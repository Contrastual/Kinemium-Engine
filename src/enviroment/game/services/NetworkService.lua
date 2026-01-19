local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local KiNet = require("@KiNet")

local NetworkService = Instance.new("NetworkService")
NetworkService.ExplorerHidden = true

local task = zune.task

local players = {}

NetworkService.InitRenderer = function(renderer, renderer_signal, datamodel)
	task.spawn(function()
		repeat
			task.wait()
		until datamodel.Players

		function NetworkService:StartServer(address, port, allowedTokens)
			KiNet.Server:Init(address, port, allowedTokens)
			KiNet.Server:Listen()
		end

		function NetworkService:StartClient(address, port, authToken)
			KiNet.Client:Init(address, port, authToken)
			KiNet.Client:Listen()
		end

		function NetworkService:Service(timeout) end

		local authToken = GetFlagValue("auth_token")
		local allowedTokens = { authToken or nil }
		local connectedTo = {}

		local data
		if IsClient then
			local player = datamodel.Players.LocalPlayer
			data = { name = player.Name, id = player.UserId }
		end

		KiNet.Server:OnClientConnectionRequest(function(client, data)
			local name, id = data.name, data.UserId
			if not name or not id then
				return
			end
			-- add new player to table? (this will obviously overwrite previous clients but eh)
			players[id] = { name = name, id = id }
		end)

		if IsServer then
			local port = tonumber(GetFlagValue("port"))
			local address = GetFlagValue("address")
			if port and address then
				log(`Starting server at {address}:{port}`)
				NetworkService:StartServer(address, port, allowedTokens)
			else
				print("Starting default server")
				NetworkService:StartServer("0.0.0.0", 1234, allowedTokens)
			end
		elseif IsClient then
			local port = tonumber(GetFlagValue("port"))
			local address = GetFlagValue("address")
			if port and address then
				log(`Starting client at {address}:{port}`)
				connectedTo = { address, port }
				NetworkService:StartClient(address, port, authToken)
				KiNet.Client:Connect(data)
				KiNet.Client:StartHeartbeat()
			else
				print("Starting default client")
				connectedTo = { "127.0.0.1", 1234 }
				NetworkService:StartClient("127.0.0.1", 1234, authToken)
				KiNet.Client:Connect(data)
				KiNet.Client:StartHeartbeat()
			end
		elseif FlagExists("live") then
			log(`Starting live client and server at 127.0.0.1:1234`)

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
			Replicate = true,
			GetServerDataAsync = function()
				return table.unpack(connectedTo)
			end,
		})
	end)
end

return NetworkService
