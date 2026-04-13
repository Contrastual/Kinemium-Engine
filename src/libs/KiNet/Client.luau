local net = zune.net
local Client = {}

local Serializer = require("./Serializer")

local onRecieveConnections = {}
local messageQueue = {}
local isQueueProcessing = false
local MAX_QUEUE_SIZE = 1000

local HEARTBEAT_INTERVAL = 5
local MAX_WIRE_MESSAGE_SIZE = 256 * 1024
local MAX_LOGICAL_MESSAGE_SIZE = 4 * 1024 * 1024
local MESSAGE_TIMEOUT = 10
local MTU_SIZE = 1000
local ACK_TIMEOUT = 3
local MAX_RETRIES = 5
local FRAGMENT_TIMEOUT = 10
local MAX_FRAGMENT_COUNT = 4096
local MAX_SEQUENCE_WINDOW = 2048
local MAX_PROCESSED_RELIABLE_MESSAGES = 2048

local function createMessageId(prefix, sequence)
	return `{prefix}_{sequence}_{math.floor(os.clock() * 1000)}`
end

local function trackReceivedSequence(self, sequence)
	if type(sequence) ~= "number" then
		return true
	end

	self.ReceivedSequences = self.ReceivedSequences or {}
	self.ReceivedSequenceOrder = self.ReceivedSequenceOrder or {}
	self.HighestReceivedSequence = self.HighestReceivedSequence or -math.huge

	if self.ReceivedSequences[sequence] then
		return false, "Duplicate message"
	end

	if self.HighestReceivedSequence ~= -math.huge and sequence <= self.HighestReceivedSequence - MAX_SEQUENCE_WINDOW then
		return false, "Sequence too old"
	end

	self.ReceivedSequences[sequence] = true
	table.insert(self.ReceivedSequenceOrder, sequence)

	if sequence > self.HighestReceivedSequence then
		self.HighestReceivedSequence = sequence
	end

	while #self.ReceivedSequenceOrder > MAX_SEQUENCE_WINDOW do
		local oldest = table.remove(self.ReceivedSequenceOrder, 1)
		if oldest and oldest <= self.HighestReceivedSequence - MAX_SEQUENCE_WINDOW then
			self.ReceivedSequences[oldest] = nil
		end
	end

	return true
end

local function cleanupFragmentBuffer(fragmentBuffer, now)
	now = now or os.clock()
	for messageId, state in pairs(fragmentBuffer or {}) do
		if now - (state.lastUpdated or state.createdAt or now) > FRAGMENT_TIMEOUT then
			fragmentBuffer[messageId] = nil
		end
	end
end

local function rememberReliableMessage(self, messageId)
	if type(messageId) ~= "string" then
		return true
	end

	self.ProcessedReliableMessages = self.ProcessedReliableMessages or {}
	self.ProcessedReliableOrder = self.ProcessedReliableOrder or {}

	if self.ProcessedReliableMessages[messageId] then
		return false
	end

	self.ProcessedReliableMessages[messageId] = true
	table.insert(self.ProcessedReliableOrder, messageId)

	while #self.ProcessedReliableOrder > MAX_PROCESSED_RELIABLE_MESSAGES do
		local oldest = table.remove(self.ProcessedReliableOrder, 1)
		if oldest then
			self.ProcessedReliableMessages[oldest] = nil
		end
	end

	return true
end

local function resolveServerEndpoint(address, port)
	local ok, addresses = pcall(net.getAddressList, address, port)
	if not ok or type(addresses) ~= "table" or #addresses == 0 then
		return address
	end

	for _, entry in ipairs(addresses) do
		if entry.family == net.ADDRF.INET then
			return entry.address
		end
	end

	return address
end

function Client:Init(serverAddress, serverPort, authToken)
	if self.Socket then
		self:Disconnect()
	end

	serverAddress = serverAddress or "127.0.0.1"
	serverPort = serverPort or 1234

	local resolvedAddress = resolveServerEndpoint(serverAddress, serverPort)

	local socket = net.createSocket(
		net.ADDRF.INET,
		bit32.bor(net.SOCKF.DGRAM, net.SOCKF.NONBLOCK, net.SOCKF.CLOEXEC),
		net.IPPROTO.UDP
	)

	socket:bindIp("0.0.0.0", 0)

	self.Socket = socket
	self.ServerAddress = resolvedAddress
	self.ServerPort = serverPort
	self.OriginalServerAddress = serverAddress
	self.AuthToken = authToken or self:GenerateToken()
	self.SessionId = nil
	self.IsAuthenticated = false
	self.LastHeartbeat = 0
	self.MessageSequence = 0
	self.ReceivedSequences = {}
	self.RateLimitWindow = {}
	self.MaxMessagesPerSecond = 300
	self.PendingAcks = {}
	self.FragmentBuffer = {}
	self.ReliableQueue = {}
	self.ReceivedSequenceOrder = {}
	self.HighestReceivedSequence = -math.huge
	self.ProcessedReliableMessages = {}
	self.ProcessedReliableOrder = {}
	self._reliableQueueRunning = false
	self._heartbeatRunning = false
	self._listenRunning = false

	onRecieveConnections = {}
	messageQueue = {}

	print(`Created client socket for {serverAddress} -> {resolvedAddress}`)
	return socket
end

function Client:GenerateToken()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local token = ""
	for i = 1, 32 do
		local rand = math.random(1, #chars)
		token = token .. string.sub(chars, rand, rand)
	end
	return token
end

function Client:ValidateMessage(data)
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
		local accepted, err = trackReceivedSequence(self, data.sequence)
		if not accepted then
			return false, err
		end
	end

	if data.sessionId and self.SessionId and data.sessionId ~= self.SessionId then
		return false, "Invalid session"
	end

	return true
end

function Client:CheckRateLimit()
	local currentTime = os.clock()

	local filtered = {}
	for _, timestamp in ipairs(self.RateLimitWindow or {}) do
		if currentTime - timestamp < 1 then
			table.insert(filtered, timestamp)
		end
	end
	self.RateLimitWindow = filtered

	if #self.RateLimitWindow >= self.MaxMessagesPerSecond then
		return false
	end

	table.insert(self.RateLimitWindow, currentTime)
	return true
end

function Client:FragmentMessage(data, messageId, serializedBuffer, reliable)
	local buf = serializedBuffer or Serializer.Serialize(data)

	if buffer.len(buf) <= MTU_SIZE then
		return { data }
	end

	local totalFragments = math.ceil(buffer.len(buf) / MTU_SIZE)
	if totalFragments > MAX_FRAGMENT_COUNT then
		error(
			`Message {messageId} requires {totalFragments} fragments which exceeds the limit of {MAX_FRAGMENT_COUNT}`
		)
	end

	if data.kind then
		print(
			`[KiNet][Client] Fragmenting {data.channel}:{data.kind} into {totalFragments} fragments ({buffer.len(buf)} bytes)`
		)
	end

	local fragments = {}

	for i = 0, totalFragments - 1 do
		local startOffset = i * MTU_SIZE
		local chunkLength = math.min(MTU_SIZE, buffer.len(buf) - startOffset)
		local chunk = buffer.create(chunkLength)
		buffer.copy(chunk, 0, buf, startOffset, chunkLength)

		table.insert(fragments, {
			fragment = true,
			reliable = reliable == true,
			messageId = messageId,
			fragmentIndex = i,
			totalFragments = totalFragments,
			data = chunk,
		})
	end

	return fragments
end

function Client:ReassembleFragments(fragmentData)
	local msgId = fragmentData.messageId
	if type(msgId) ~= "string" then
		return nil
	end

	if type(fragmentData.totalFragments) ~= "number"
		or fragmentData.totalFragments < 1
		or fragmentData.totalFragments > MAX_FRAGMENT_COUNT
	then
		return nil
	end

	if type(fragmentData.fragmentIndex) ~= "number"
		or fragmentData.fragmentIndex < 0
		or fragmentData.fragmentIndex >= fragmentData.totalFragments
	then
		return nil
	end

	local chunkLengthOk, chunkLength = pcall(buffer.len, fragmentData.data)
	if not chunkLengthOk then
		return nil
	end

	cleanupFragmentBuffer(self.FragmentBuffer)

	if not self.FragmentBuffer[msgId] then
		self.FragmentBuffer[msgId] = {
			fragments = {},
			totalFragments = fragmentData.totalFragments,
			received = 0,
			totalBytes = 0,
			createdAt = os.clock(),
			lastUpdated = os.clock(),
		}
	end

	local fragmentState = self.FragmentBuffer[msgId]
	if fragmentState.totalFragments ~= fragmentData.totalFragments then
		self.FragmentBuffer[msgId] = nil
		return nil
	end

	fragmentState.lastUpdated = os.clock()

	if not fragmentState.fragments[fragmentData.fragmentIndex] then
		fragmentState.fragments[fragmentData.fragmentIndex] = fragmentData.data
		fragmentState.received = fragmentState.received + 1
		fragmentState.totalBytes += chunkLength
		if fragmentState.totalBytes > MAX_LOGICAL_MESSAGE_SIZE then
			self.FragmentBuffer[msgId] = nil
			warn(`[KiNet][Client] Dropping fragmented message {msgId} because it exceeds {MAX_LOGICAL_MESSAGE_SIZE} bytes`)
			return nil
		end
	end

	if fragmentState.received == fragmentState.totalFragments then
		local totalLength = 0
		for i = 0, fragmentState.totalFragments - 1 do
			if not fragmentState.fragments[i] then
				self.FragmentBuffer[msgId] = nil
				return nil
			end
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

		self.FragmentBuffer[msgId] = nil

		print(`[KiNet][Client] Reassembled fragmented message {msgId} ({fragmentState.totalFragments} fragments)`)

		local ok, decoded = pcall(Serializer.Deserialize, completeData)
		if not ok then
			warn(`[KiNet][Client] Failed to deserialize reassembled message {msgId}: {decoded}`)
			return nil
		end

		return decoded
	end

	return nil
end

function Client:SendReliable(data)
	local messageId = data.messageId or createMessageId("reliable", self.MessageSequence)
	data.messageId = messageId
	data.reliable = true
	data.timestamp = os.time()

	local ok, serialized = pcall(Serializer.Serialize, data)
	if not ok then
		warn(`[KiNet][Client] Failed to serialize reliable message {messageId}: {serialized}`)
		return
	end

	if buffer.len(serialized) > MAX_LOGICAL_MESSAGE_SIZE then
		warn(
			`[KiNet][Client] Reliable message {messageId} is {buffer.len(serialized)} bytes which exceeds the logical limit of {MAX_LOGICAL_MESSAGE_SIZE}`
		)
		return
	end

	local fragments = self:FragmentMessage(data, messageId, serialized, true)

	self.PendingAcks[messageId] = {
		fragments = fragments,
		attempts = 0,
		lastSent = os.clock(),
		channel = data.channel,
		kind = data.kind or data.type,
		fragmentCount = #fragments,
	}

	for _, fragment in ipairs(fragments) do
		self:SendRaw(fragment)
	end
end

function Client:SendRaw(data)
	local bypassRateLimit = type(data) == "table"
		and (data.type == "ACK" or data.type == "HEARTBEAT" or data.type == "CONNECT" or data.type == "DISCONNECT")

	if not bypassRateLimit and not self:CheckRateLimit() then
		warn("Rate limit exceeded")
		return
	end

	data.timestamp = os.time()
	data.sequence = self.MessageSequence
	self.MessageSequence = self.MessageSequence + 1

	if self.SessionId then
		data.sessionId = self.SessionId
	end

	local buf = Serializer.Serialize(data)

	if buffer.len(buf) > MAX_WIRE_MESSAGE_SIZE then
		warn(
			`[KiNet][Client] Datagram too large: {buffer.len(buf)} bytes (max: {MAX_WIRE_MESSAGE_SIZE}) for {data.kind or data.type or "packet"}`
		)
		return false
	end

	self.Socket:sendMsg(self.ServerPort, self.ServerAddress, buf)
	return true
end

function Client:ProcessReliableQueue()
	if self._reliableQueueRunning then
		return
	end

	self._reliableQueueRunning = true
	task.spawn(function()
		while self._reliableQueueRunning do
			task.wait(0.1)

			local currentTime = os.clock()
			cleanupFragmentBuffer(self.FragmentBuffer, currentTime)

			for msgId, ackData in pairs(self.PendingAcks) do
				if currentTime - ackData.lastSent > ACK_TIMEOUT then
					if ackData.attempts >= MAX_RETRIES then
						warn(
							`Message {msgId} failed after {MAX_RETRIES} retries (channel={ackData.channel or "?"}, kind={ackData.kind or "?"}, fragments={ackData.fragmentCount or 1})`
						)
						self.PendingAcks[msgId] = nil
					else
						ackData.attempts = ackData.attempts + 1
						ackData.lastSent = currentTime

						for _, fragment in ipairs(ackData.fragments) do
							if self.Socket then
								self:SendRaw(fragment)
							end
						end
					end
				end
			end
		end
	end)
end

function Client:OnShutdown(v)
	Client._OnShutdown = v
end

function Client:Connect(arguments)
	local displayAddress = self.OriginalServerAddress or self.ServerAddress
	log(`Connecting to server at {displayAddress}:{self.ServerPort}`)
	Client:Send({
		type = "CONNECT",
		authToken = self.AuthToken,
		arguments = arguments,
	})
end

function Client:OnRecieve(callback)
	table.insert(onRecieveConnections, callback)

	if #onRecieveConnections == 1 and #messageQueue > 0 then
		print(`Processing {#messageQueue} queued messages`)
		for _, queuedMsg in ipairs(messageQueue) do
			task.spawn(function()
				callback(queuedMsg.addr, queuedMsg.data)
			end)
		end
		messageQueue = {} -- Clear queue
	end
end

function Client:Disconnect()
	local displayAddress = self.OriginalServerAddress or self.ServerAddress
	log(`Disconnecting from server at {displayAddress}:{self.ServerPort}`)
	if not self.Socket then
		return
	end

	if self.IsAuthenticated then
		Client:Send({
			type = "DISCONNECT",
			sessionId = self.SessionId,
		})
	end

	self._reliableQueueRunning = false
	self._heartbeatRunning = false
	self._listenRunning = false

	self.Socket:close()
	self.Socket = nil
	self.IsAuthenticated = false
	self.SessionId = nil
	self.PendingAcks = {}
	self.FragmentBuffer = {}
	self.ReliableQueue = {}
	self.ReceivedSequences = {}
	self.ReceivedSequenceOrder = {}
	self.HighestReceivedSequence = -math.huge
	self.ProcessedReliableMessages = {}
	self.ProcessedReliableOrder = {}
	self.RateLimitWindow = {}

	if Client._OnShutdown then
		Client._OnShutdown()
	end
end

function Client:Send(data, reliable)
	assert(self.Socket, "Socket not initialized, call :Init() first")

	if reliable then
		self:SendReliable(data)
	else
		data.reliable = false

		local ok, serialized = pcall(Serializer.Serialize, data)
		if not ok then
			warn(`[KiNet][Client] Failed to serialize message: {serialized}`)
			return
		end

		if buffer.len(serialized) > MAX_LOGICAL_MESSAGE_SIZE then
			warn(
				`[KiNet][Client] Message is {buffer.len(serialized)} bytes which exceeds the logical limit of {MAX_LOGICAL_MESSAGE_SIZE}`
			)
			return
		end

		if buffer.len(serialized) > MTU_SIZE then
			local messageId = data.messageId or createMessageId("fragmented", self.MessageSequence)
			data.messageId = messageId
			local largeOk, largeSerialized = pcall(Serializer.Serialize, data)
			if not largeOk then
				warn(`[KiNet][Client] Failed to serialize large fragmented message {messageId}: {largeSerialized}`)
				return
			end

			for _, fragment in ipairs(self:FragmentMessage(data, messageId, largeSerialized, false)) do
				self:SendRaw(fragment)
			end
			return
		end

		self:SendRaw(data)
	end
end

function Client._middleware(v, addr)
	if type(v) == "table" then
		if v.type == "ACK" then
			if Client.PendingAcks[v.messageId] then
				Client.PendingAcks[v.messageId] = nil
			end
			return
		end

		if v.type == "AUTH_SUCCESS" then
			Client.IsAuthenticated = true
			Client.SessionId = v.sessionId
			log(`Authenticated with session: {v.sessionId}`)
		end

		if v.type == "AUTH_FAILED" then
			warn("Authentication failed")
			Client:Disconnect()
		end

		if v.type == "DISCONNECT" then
			log(`Server requested disconnect`)
			Client:Disconnect()
		end

		if v.type == "SHUTDOWN" then
			log(`Server shutdown`)
			Client:Disconnect()
		end

		if v.type == "HEARTBEAT" then
			Client.LastHeartbeat = os.time()
		end
	elseif type(v) == "string" then
		if string.find(v, "DISCONNECT") then
			log(`Client disconnected at {addr}`)
			Client:Disconnect()
		end

		if string.find(v, "SHUTDOWN") then
			log(`Client shutdown at {addr}`)
			Client:Disconnect()
		end
	end
end

function Client:StartHeartbeat()
	if self._heartbeatRunning then
		return
	end

	self._heartbeatRunning = true
	task.spawn(function()
		while self._heartbeatRunning do
			task.wait(HEARTBEAT_INTERVAL)
			if Client.IsAuthenticated then
				Client:Send({
					type = "HEARTBEAT",
				})
			end
		end
	end)
end

function Client:Listen()
	if self._listenRunning then
		return
	end

	self._listenRunning = true
	self:ProcessReliableQueue()

	task.spawn(function()
		while self._listenRunning do
			if not self.Socket then
				break
			end

			local success, addr, data = pcall(function()
				return self.Socket:recvMsg(MAX_WIRE_MESSAGE_SIZE)
			end)

			if not success then
				task.wait()
				continue
			end

			if data then
				local decodedOk, decoded = pcall(Serializer.Deserialize, data)
				if not decodedOk then
					warn(`[KiNet][Client] Failed to deserialize incoming packet: {decoded}`)
					continue
				end

				if decoded then
					if decoded.fragment then
						local fragmentMessageId = decoded.messageId
						local reassembled = self:ReassembleFragments(decoded)
						if reassembled then
							decoded = reassembled
							if decoded.reliable then
								self:SendRaw({
									type = "ACK",
									messageId = fragmentMessageId,
								})
							end
						else
							task.wait()
							continue
						end
					elseif decoded.reliable then
						self:SendRaw({
							type = "ACK",
							messageId = decoded.messageId,
						})
					end

					local valid, err = self:ValidateMessage(decoded)
					if not valid then
						warn(`Invalid message: {err}`)
						task.wait()
						continue
					end

					if decoded.reliable and decoded.messageId and not rememberReliableMessage(self, decoded.messageId) then
						continue
					end

					Client._middleware(decoded, addr)

					if #onRecieveConnections == 0 then
						if #messageQueue < MAX_QUEUE_SIZE then
							table.insert(messageQueue, { addr = addr, data = decoded })
							print(`Queued message (queue size: {#messageQueue})`)
						else
							warn("Message queue full, dropping message")
						end
					else
						for _, v in pairs(onRecieveConnections) do
							task.spawn(function()
								v(addr, decoded)
							end)
						end
					end
				end
			end
		end
	end)
end

return Client
