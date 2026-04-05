local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local KiNet = require("@KiNet")
local Protocol = require("./Protocol")
local GuiMirror = require("../../runtime/GuiMirror")

local NetworkService = Instance.new("NetworkService")
NetworkService.ExplorerHidden = true

local task = zune.task

local tickSignal = signal.new()
local clientConnectedSignal = signal.new()
local clientRemovedSignal = signal.new()
local packetSignal = signal.new()

local packetHandlers = {}
local pendingPackets = {}
local sessionsByKey = {}
local sessionsByUserId = {}

local currentTick = 0
local tickRate = 30
local tickInterval = 1 / tickRate
local tickAccumulator = 0
local tickLoopBound = false

local datamodelRef = nil
local connectedTo = {}
local localPlayerUserId = nil

local function clientKey(client)
	return `{client.address}:{client.port}`
end

local function normalizeRecipient(recipient)
	if recipient == nil then
		return nil
	end

	if recipient.client then
		return recipient.client
	end

	return recipient
end

local function queuePendingPacket(sender, envelope)
	local key = `{envelope.channel}:{envelope.kind}`
	local bucket = pendingPackets[key]
	if not bucket then
		bucket = {}
		pendingPackets[key] = bucket
	end

	table.insert(bucket, {
		sender = sender,
		envelope = envelope,
	})
end

local function dispatchPacket(sender, envelope)
	if not Protocol.IsEnvelope(envelope) then
		return false
	end

	local channelHandlers = packetHandlers[envelope.channel]
	local kindHandlers = channelHandlers and channelHandlers[envelope.kind]
	if not kindHandlers or #kindHandlers == 0 then
		queuePendingPacket(sender, envelope)
		return true
	end

	packetSignal:Fire(sender, envelope)

	for _, callback in ipairs(kindHandlers) do
		task.spawn(function()
			callback(sender, envelope.payload, envelope)
		end)
	end

	return true
end

local function flushPendingPackets(channel, kind)
	local key = `{channel}:{kind}`
	local bucket = pendingPackets[key]
	if not bucket then
		return
	end

	pendingPackets[key] = nil
	for _, entry in ipairs(bucket) do
		dispatchPacket(entry.sender, entry.envelope)
	end
end

local function registerMessageHandler(channel, kind, callback)
	packetHandlers[channel] = packetHandlers[channel] or {}
	packetHandlers[channel][kind] = packetHandlers[channel][kind] or {}
	table.insert(packetHandlers[channel][kind], callback)
	flushPendingPackets(channel, kind)
end

local function sendEnvelope(sendFn, recipient, channel, kind, payload, reliable)
	local envelope = Protocol.MakeEnvelope(channel, kind, payload, currentTick)
	if recipient then
		sendFn(normalizeRecipient(recipient), envelope, reliable == true)
	else
		sendFn(envelope, reliable == true)
	end
end

local function withMouseInjection(player, renderer, datamodel)
	if player.GetMouse then
		return
	end

	player:SetProperties({
		GetMouse = function(self)
			if not self.MouseInstance then
				local Mouse = require("@Mouse")
				local mouseInstance = Instance.new("Mouse")
				self.MouseInstance = Mouse.callback(mouseInstance, renderer, datamodel)
			end
			return self.MouseInstance
		end,
	})
end

local function attachPlayerSession(datamodel, session)
	local players = datamodel.Players
	local player = players:AddPlayer(session.name, session.userId, datamodel)
	if not player then
		return nil
	end

	player.client = session.client

	local playerGui = Instance.new("PlayerGui")
	GuiMirror.MarkTreeLocalOnly(playerGui)
	playerGui.Parent = player
	player.PlayerGui = playerGui

	local guiMirrorController = GuiMirror.new(playerGui)
	guiMirrorController:BindContainer(datamodel.StarterGui, "StarterGui")
	guiMirrorController:BindContainer(datamodel.CoreGui, "CoreGui")
	session.guiMirrorController = guiMirrorController

	session.player = player
	return player
end

local function cleanupPlayerSession(datamodel, session)
	local players = datamodel:GetService("Players")
	local player = session.player
	if not player then
		return
	end

	if player.Character then
		player.Character:Destroy()
		player.Character = nil
	end

	if session.guiMirrorController then
		session.guiMirrorController:Destroy()
		session.guiMirrorController = nil
	end

	players:RemovePlayer(player)
	player:Destroy()
	session.player = nil
end

local function bindTickLoop(runService)
	if tickLoopBound then
		return
	end

	tickLoopBound = true
	task.spawn(function()
		local lastClock = os.clock()

		while datamodelRef ~= nil do
			task.wait(tickInterval * 0.5)

			local now = os.clock()
			tickAccumulator += now - lastClock
			lastClock = now

			while tickAccumulator >= tickInterval do
				tickAccumulator -= tickInterval
				currentTick += 1
				tickSignal:Fire(currentTick, tickInterval)
			end
		end
	end)
end

NetworkService.InitRenderer = function(renderer, renderer_signal, datamodel)
	task.spawn(function()
		repeat
			task.wait()
		until datamodel.Players and datamodel:GetService("RunService")

		datamodelRef = datamodel
		bindTickLoop(datamodel:GetService("RunService"))

		local function sendToClient(recipient, channel, kind, payload, reliable)
			sendEnvelope(function(client, envelope, shouldBeReliable)
				KiNet.Server:Send(client, envelope, shouldBeReliable)
			end, recipient, channel, kind, payload, reliable)
		end

		local function broadcast(channel, kind, payload, reliable)
			sendEnvelope(function(envelope, shouldBeReliable)
				KiNet.Server:SendAll(envelope, shouldBeReliable)
			end, nil, channel, kind, payload, reliable)
		end

		local function sendToServer(channel, kind, payload, reliable)
			sendEnvelope(function(envelope, shouldBeReliable)
				KiNet.Client:Send(envelope, shouldBeReliable)
			end, nil, channel, kind, payload, reliable)
		end

		function NetworkService:StartServer(address, port, allowedTokens)
			KiNet.Server:Init(address, port, allowedTokens)
			KiNet.Server:Listen()
		end

		function NetworkService:StartClient(address, port, authToken)
			KiNet.Client:Init(address, port, authToken)

			KiNet.Client:OnRecieve(function(addr, msg)
				if msg.type == "AUTH_SUCCESS" then
					NetworkService.IsClientConnected = true
					return
				end

				if msg.type == "AUTH_FAILED" or msg.type == "DISCONNECT" or msg.type == "SHUTDOWN" then
					NetworkService.IsClientConnected = false
					return
				end

				dispatchPacket(nil, msg)
			end)

			KiNet.Client:Listen()
		end

		registerMessageHandler(Protocol.Channels.Control, Protocol.Kinds.PlayerProfile, function(_, payload)
			localPlayerUserId = payload.id

			task.spawn(function()
				local player = datamodel.Players.LocalPlayer
				if player and player.UserId == 1 and player.Name == payload.name then
					player.UserId = payload.id
					datamodel.Players.LocalPlayer = player
					withMouseInjection(player, renderer, datamodel)
					NetworkService.IsClientConnected = true
					return
				end

				local player
				repeat
					task.wait()
					player = datamodel.Players:GetPlayerByUserId(payload.id)
					if not player then
						for _, child in ipairs(datamodel.Players:GetChildren()) do
							if child.ClassName == "Player" and child.Name == payload.name then
								player = child
								break
							end
						end
					end
				until player

				datamodel.Players.LocalPlayer = player
				withMouseInjection(player, renderer, datamodel)
				NetworkService.IsClientConnected = true
			end)
		end)

		registerMessageHandler(Protocol.Channels.Control, Protocol.Kinds.PlayerJoined, function() end)

		registerMessageHandler(Protocol.Channels.Control, Protocol.Kinds.PlayerLeft, function(_, payload)
			local players = datamodel:GetService("Players")
			local player = players:GetPlayerByUserId(payload.id)
			if player then
				if player.Character then
					player.Character:Destroy()
				end
				players:RemovePlayer(player)
				player:Destroy()
			end
		end)

		KiNet.Server:OnClientConnectionRequest(function(client, clientData)
			local name = clientData and clientData.name
			local userId = clientData and clientData.id
			if not name or not userId or sessionsByUserId[userId] then
				return
			end

			local session = {
				key = clientKey(client),
				client = client,
				address = client.address,
				port = client.port,
				name = name,
				userId = userId,
				lastInputSequence = 0,
				lastAppliedInputSequence = 0,
				lastAcknowledgedInputSequence = -1,
			}

			sessionsByKey[session.key] = session
			sessionsByUserId[userId] = session

			attachPlayerSession(datamodel, session)

			local existingPlayers = {}
			for _, otherSession in pairs(sessionsByKey) do
				if otherSession.userId ~= session.userId then
					table.insert(existingPlayers, {
						name = otherSession.name,
						id = otherSession.userId,
					})
				end
			end

			sendToClient(session, Protocol.Channels.Control, Protocol.Kinds.PlayerProfile, {
				name = session.name,
				id = session.userId,
				existingPlayers = existingPlayers,
			}, true)

			for _, otherSession in pairs(sessionsByKey) do
				if otherSession.userId ~= session.userId then
					sendToClient(otherSession, Protocol.Channels.Control, Protocol.Kinds.PlayerJoined, {
						name = session.name,
						id = session.userId,
					}, true)
				end
			end

			clientConnectedSignal:Fire(session, session.player)
		end)

		KiNet.Server:OnRecieve(function(addr, msg)
			local session = sessionsByKey[clientKey(addr)]
			dispatchPacket(session, msg)
		end)

		KiNet.Server:OnClientRemoved(function(addr)
			local key = clientKey(addr)
			local session = sessionsByKey[key]
			if not session then
				return
			end

			sessionsByKey[key] = nil
			sessionsByUserId[session.userId] = nil
			cleanupPlayerSession(datamodel, session)

			broadcast(Protocol.Channels.Control, Protocol.Kinds.PlayerLeft, {
				name = session.name,
				id = session.userId,
			}, true)

			clientRemovedSignal:Fire(session)
		end)

		local authToken = GetFlagValue("auth_token")
		local allowedTokens = authToken and { authToken } or {}
		local data

		if IsClient then
			local userName = GetFlagValue("username") or "Player"
			local userId = math.random(1000, 999999)
			data = { name = userName, id = userId }
		end

		if IsServer then
			local port = tonumber(GetFlagValue("port"))
			local address = GetFlagValue("address")
			if port and address then
				connectedTo = { address, port }
				NetworkService:StartServer(address, port, allowedTokens)
			else
				connectedTo = { "0.0.0.0", 1234 }
				NetworkService:StartServer("0.0.0.0", 1234, allowedTokens)
			end
		elseif IsClient then
			local port = tonumber(GetFlagValue("port"))
			local address = GetFlagValue("address")
			if port and address then
				connectedTo = { address, port }
				NetworkService:StartClient(address, port, authToken)
				KiNet.Client:Connect(data)
				KiNet.Client:StartHeartbeat()
			else
				connectedTo = { "127.0.0.1", 1234 }
				NetworkService:StartClient("127.0.0.1", 1234, authToken)
				KiNet.Client:Connect(data)
				KiNet.Client:StartHeartbeat()
			end
		elseif FlagExists("live") then
			NetworkService:StartServer("0.0.0.0", 1234, allowedTokens)
			connectedTo = { "127.0.0.1", 1234 }
			NetworkService:StartClient("127.0.0.1", 1234, authToken)
			KiNet.Client:Connect(data)
			KiNet.Client:StartHeartbeat()
		end

		table.insert(datamodel.ShutdownCallbacks, function()
			if KiNet.Client then
				KiNet.Client:Disconnect()
			end
			if KiNet.Server then
				KiNet.Server:Shutdown()
			end
		end)

		NetworkService:SetProperties({
			Success = true,
			IsClientConnected = false,
			KiNet = KiNet,
			Protocol = Protocol,
			Replicate = true,
			Tick = tickSignal,
			ClientConnected = clientConnectedSignal,
			ClientRemoved = clientRemovedSignal,
			PacketReceived = packetSignal,
			TickRate = tickRate,
			TickInterval = tickInterval,
			RegisterMessageHandler = function(self, channel, kind, callback)
				registerMessageHandler(channel, kind, callback)
			end,
			SendToServer = function(self, channel, kind, payload, reliable)
				sendToServer(channel, kind, payload, reliable)
			end,
			SendToClient = function(self, recipient, channel, kind, payload, reliable)
				sendToClient(recipient, channel, kind, payload, reliable)
			end,
			Broadcast = function(self, channel, kind, payload, reliable)
				broadcast(channel, kind, payload, reliable)
			end,
			GetCurrentTick = function()
				return currentTick
			end,
			GetServerDataAsync = function()
				return table.unpack(connectedTo)
			end,
			GetLocalPlayerUserId = function()
				return localPlayerUserId
			end,
			GetSessionByUserId = function(self, userId)
				return sessionsByUserId[userId]
			end,
			GetSessions = function()
				local list = {}
				for _, session in pairs(sessionsByKey) do
					table.insert(list, session)
				end
				return list
			end,
		})
	end)
end

return NetworkService
