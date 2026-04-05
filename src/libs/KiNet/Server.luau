local net = zune.net
local Server = {}

local Serializer = require("./Serializer")

Server.ConnectedClients = {}
local onRecieveCallbacks = {}

local HEARTBEAT_TIMEOUT = 15
local MAX_MESSAGE_SIZE = 100000
local MESSAGE_TIMEOUT = 10
local MAX_CLIENTS = 130
local MAX_MESSAGES_PER_CLIENT = 300
local MTU_SIZE = 1400
local ACK_TIMEOUT = 3
local MAX_RETRIES = 5

local function clientKey(addr)
	return addr.address .. ":" .. addr.port
end

function Server:Init(address, port, allowedTokens)
	local socket = net.createSocket(
		net.ADDRF.INET,
		bit32.bor(net.SOCKF.DGRAM, net.SOCKF.NONBLOCK, net.SOCKF.CLOEXEC),
		net.IPPROTO.UDP
	)

	address = address or "0.0.0.0"
	port = port or 1234

	socket:bindIp(address, port)
	Server.Socket = socket
	Server.Address = address
	Server.Port = port
	Server.AllowedTokens = allowedTokens or {}
	Server.SessionCounter = 0
	Server.BannedAddresses = {}
	Server.MessageSequence = 0

	log(`Created server socket at {address}:{port}`)

	return socket
end

function Server:GenerateSessionId()
	Server.SessionCounter = Server.SessionCounter + 1
	return `session_{Server.SessionCounter}_{os.time()}`
end

function Server:ValidateAuthToken(token)
	if #Server.AllowedTokens == 0 then
		return true
	end

	for _, allowedToken in ipairs(Server.AllowedTokens) do
		if token == allowedToken then
			return true
		end
	end

	return false
end

function Server:OnClientConnectionRequest(callback)
	Server._onClientConnectionRequest = callback
end

function Server:ValidateMessage(data, client)
	if type(data) ~= "table" then
		return false, "Invalid message format"
	end

	if not data.timestamp then
		return false, "Missing timestamp"
	end

	local currentTime = os.time()
	if math.abs(currentTime - data.timestamp) > MESSAGE_TIMEOUT then
		return false, "Message expired"
	end

	if data.sequence then
		if not client.lastSequence then
			client.lastSequence = data.sequence
		elseif data.sequence <= client.lastSequence then
			return false, "Invalid sequence"
		else
			client.lastSequence = data.sequence
		end
	end

	if data.sessionId and data.sessionId ~= client.sessionId then
		return false, "Invalid session"
	end

	return true
end

function Server:CheckRateLimit(client)
	local currentTime = os.clock()

	if not client.rateLimitWindow then
		client.rateLimitWindow = {}
	end

	local filtered = {}
	for _, timestamp in ipairs(client.rateLimitWindow) do
		if currentTime - timestamp < 1 then
			table.insert(filtered, timestamp)
		end
	end
	client.rateLimitWindow = filtered

	if #client.rateLimitWindow >= MAX_MESSAGES_PER_CLIENT then
		return false
	end

	table.insert(client.rateLimitWindow, currentTime)
	return true
end

function Server:FragmentMessage(data, messageId)
	local buf = Serializer.Serialize(data)

	if buffer.len(buf) <= MTU_SIZE then
		return { data }
	end

	if data.kind then
		print(`[KiNet][Server] Fragmenting {data.channel}:{data.kind} for {messageId} into {math.ceil(buffer.len(buf) / MTU_SIZE)} fragments ({buffer.len(buf)} bytes)`)
	end

	local fragments = {}
	local totalFragments = math.ceil(buffer.len(buf) / MTU_SIZE)

	for i = 0, totalFragments - 1 do
		local startOffset = i * MTU_SIZE
		local chunkLength = math.min(MTU_SIZE, buffer.len(buf) - startOffset)
		local chunk = buffer.create(chunkLength)
		buffer.copy(chunk, 0, buf, startOffset, chunkLength)

		table.insert(fragments, {
			fragment = true,
			reliable = true,
			messageId = messageId,
			fragmentIndex = i,
			totalFragments = totalFragments,
			data = chunk,
		})
	end

	return fragments
end

function Server:ReassembleFragments(fragmentData, client)
	local msgId = fragmentData.messageId

	if not client.fragmentBuffer then
		client.fragmentBuffer = {}
	end

	if not client.fragmentBuffer[msgId] then
		client.fragmentBuffer[msgId] = {
			fragments = {},
			totalFragments = fragmentData.totalFragments,
			received = 0,
		}
	end

	local fragmentState = client.fragmentBuffer[msgId]

	if not fragmentState.fragments[fragmentData.fragmentIndex] then
		fragmentState.fragments[fragmentData.fragmentIndex] = fragmentData.data
		fragmentState.received = fragmentState.received + 1
	end

	if fragmentState.received == fragmentState.totalFragments then
		local totalLength = 0
		for i = 0, fragmentState.totalFragments - 1 do
			totalLength += buffer.len(fragmentState.fragments[i])
		end

		local completeData = buffer.create(totalLength)
		local writeOffset = 0
		for i = 0, fragmentState.totalFragments - 1 do
			local chunk = fragmentState.fragments[i]
			local chunkLength = buffer.len(chunk)
			buffer.copy(completeData, writeOffset, chunk, 0, chunkLength)
			writeOffset += chunkLength
		end

		client.fragmentBuffer[msgId] = nil

		print(`[KiNet][Server] Reassembled fragmented message {msgId} from {clientKey(client)} ({fragmentState.totalFragments} fragments)`)

		return Serializer.Deserialize(completeData)
	end

	return nil
end

function Server:IsBanned(address)
	return Server.BannedAddresses[address] ~= nil
end

function Server:BanClient(address, reason)
	Server.BannedAddresses[address] = {
		reason = reason or "Violation",
		timestamp = os.time(),
	}
	log(`Banned client {address}: {reason}`)
end

function Server:OnRecieve(callback)
	table.insert(onRecieveCallbacks, callback)
end

function Server:OnNewClient(callback)
	self._onNewClient = callback
end

function Server:OnClientRemoved(callback)
	self._onClientRemoved = callback
end

function Server:SendAll(data, reliable)
	local success, err = pcall(function()
		for key, client in pairs(Server.ConnectedClients) do
			if client.authenticated then
				local sendSuccess, sendErr = pcall(function()
					self:Send(client, data, reliable)
				end)
				if not sendSuccess then
					warn(`Failed to send to {key}: {sendErr}`)
				end
			end
		end
	end)

	if not success then
		warn(`SendAll error: {err}`)
	end
end

function Server:Shutdown()
	log(`Shutting down server at {self.Address}:{self.Port}`)
	if not self.Socket then
		return
	end
	Server:SendAll({ type = "SHUTDOWN" })
	self.Socket:close()
end

function Server:SendReliable(client, data)
	local messageId = `reliable_{Server.MessageSequence}_{clientKey({ address = client.address, port = client.port })}`
	Server.MessageSequence = Server.MessageSequence + 1

	data.messageId = messageId
	data.reliable = true
	data.timestamp = os.time()

	local fragments = self:FragmentMessage(data, messageId)

	if not client.pendingAcks then
		client.pendingAcks = {}
	end

	client.pendingAcks[messageId] = {
		fragments = fragments,
		attempts = 0,
		lastSent = os.clock(),
	}

	for _, fragment in ipairs(fragments) do
		self:SendRaw(client, fragment)
	end
end

function Server:SendRaw(client, data)
	data.timestamp = os.time()
	data.sessionId = client.sessionId

	local buf = Serializer.Serialize(data)

	if buffer.len(buf) > MAX_MESSAGE_SIZE then
		error(`Message too large: {buffer.len(buf)} bytes (max: {MAX_MESSAGE_SIZE})`)
		error(`Message type: {data.type}`)
		return
	end

	self.Socket:sendMsg(tonumber(client.port), client.address, buf)
end

function Server:Send(client, data, reliable)
	if reliable then
		self:SendReliable(client, data)
	else
		self:SendRaw(client, data)
	end
end

function Server:ProcessReliableQueue()
	task.spawn(function()
		while true do
			task.wait(0.1)

			local currentTime = os.clock()

			for key, client in pairs(Server.ConnectedClients) do
				if client.authenticated and client.pendingAcks then
					for msgId, ackData in pairs(client.pendingAcks) do
						if currentTime - ackData.lastSent > ACK_TIMEOUT then
							if ackData.attempts >= MAX_RETRIES then
								warn(`Message {msgId} to {key} failed after {MAX_RETRIES} retries`)
								client.pendingAcks[msgId] = nil
							else
								ackData.attempts = ackData.attempts + 1
								ackData.lastSent = currentTime

								for _, fragment in ipairs(ackData.fragments) do
									self:SendRaw(client, fragment)
								end
							end
						end
					end
				end
			end
		end
	end)
end

function Server:AuthenticateClient(addr, authToken)
	if not self:ValidateAuthToken(authToken) then
		self:SendRaw({
			address = addr.address,
			port = addr.port,
		}, {
			type = "AUTH_FAILED",
			reason = "Invalid token",
		})
		return false
	end

	local key = clientKey(addr)

	local sessionId = self:GenerateSessionId()

	Server.ConnectedClients[key] = {
		address = addr.address,
		port = addr.port,
		sessionId = sessionId,
		authenticated = true,
		connectedAt = os.time(),
		lastHeartbeat = os.time(),
		lastSequence = nil,
		rateLimitWindow = {},
		fragmentBuffer = {},
		pendingAcks = {},
	}

	self:SendRaw(Server.ConnectedClients[key], {
		type = "AUTH_SUCCESS",
		sessionId = sessionId,
	})

	log(`Client ({key}) authenticated with session: {sessionId}`)

	if Server._onNewClient then
		Server._onNewClient(addr)
	end

	return true, Server.ConnectedClients[key]
end

function Server._middleware(v, addr)
	local key = clientKey(addr)
	local client = Server.ConnectedClients[key]

	if Server:IsBanned(addr.address) then
		return
	end

	if type(v) == "table" then
		if v.type == "ACK" then
			if client and client.pendingAcks and client.pendingAcks[v.messageId] then
				client.pendingAcks[v.messageId] = nil
			end
			return
		end

		if v.type == "CONNECT" then
			if #table.pack(Server.ConnectedClients) >= MAX_CLIENTS then
				warn(`Max clients reached, rejecting {key}`)
				return
			end

			local success, client = Server:AuthenticateClient(addr, v.authToken)
			if success and client then
				if Server._onClientConnectionRequest then
					Server._onClientConnectionRequest(client, v.arguments)
				end
			end
			return
		end

		if not client or not client.authenticated then
			warn(`Unauthenticated message from {key}`)
			return
		end

		if not Server:CheckRateLimit(client) then
			warn(`Rate limit exceeded for {key}`)
			Server:BanClient(addr.address, "Rate limit exceeded")
			Server:SendRaw(client, { type = "DISCONNECT", reason = "Rate limit" })
			Server.ConnectedClients[key] = nil
			return
		end

		local valid, err = Server:ValidateMessage(v, client)
		if not valid then
			warn(`Invalid message from {key}: {err}`)
			return
		end

		if v.type == "DISCONNECT" then
			Server.ConnectedClients[key] = nil
			log(`Client ({key}) disconnected`)

			if Server._onClientRemoved then
				Server._onClientRemoved(addr)
			end
		end

		if v.type == "HEARTBEAT" then
			client.lastHeartbeat = os.time()
		end
	end
end

function Server:StartHeartbeatMonitor()
	task.spawn(function()
		while true do
			task.wait(HEARTBEAT_TIMEOUT / 2)

			local currentTime = os.time()
			for key, client in pairs(Server.ConnectedClients) do
				if client.authenticated then
					if currentTime - client.lastHeartbeat > HEARTBEAT_TIMEOUT then
						log(`Client {key} timed out`)
						Server:SendRaw(client, { type = "DISCONNECT", reason = "Timeout" })
						Server.ConnectedClients[key] = nil

						if Server._onClientRemoved then
							Server._onClientRemoved({
								address = client.address,
								port = client.port,
							})
						end
					end
				end
			end
		end
	end)
end

function Server:Listen()
	assert(self.Socket, "Socket not created, call :Init() first")

	self:StartHeartbeatMonitor()
	self:ProcessReliableQueue()

	task.spawn(function()
		while true do
			if not self.Socket then
				break
			end

			local success, addr, data = pcall(function()
				return self.Socket:recvMsg(MAX_MESSAGE_SIZE)
			end)

			if not success then
				warn(`[KiNet][Server] recvMsg failed: {addr}`)
				task.wait()
				continue
			end

			if not data then
				task.wait()
				continue
			end

			if buffer.len(data) > MAX_MESSAGE_SIZE then
				warn(`Message too large from {clientKey(addr)}`)
				task.wait()
				continue
			end

			local decoded = Serializer.Deserialize(data)
			if decoded then
				local key = clientKey(addr)
				local client = Server.ConnectedClients[key]

				if decoded.fragment and client then
					local fragmentMessageId = decoded.messageId
					local reassembled = self:ReassembleFragments(decoded, client)
					if reassembled then
						decoded = reassembled
						if decoded.reliable then
							self:SendRaw(client, {
								type = "ACK",
								messageId = fragmentMessageId,
							})
						end
					else
						task.wait()
						continue
					end
				elseif decoded.reliable and client then
					self:SendRaw(client, {
						type = "ACK",
						messageId = decoded.messageId,
					})
				end

				Server._middleware(decoded, addr)

				client = Server.ConnectedClients[key]

				if client and client.authenticated then
					for _, v in pairs(onRecieveCallbacks) do
						zune.task.spawn(function()
							v(addr, decoded)
						end)
					end
				end
			end
			task.wait()
		end
	end)
end

return Server
