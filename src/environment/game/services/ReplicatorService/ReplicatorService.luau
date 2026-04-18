local Instance = require("@Instance")

local ReplicatorService = Instance.new("ReplicatorService")
ReplicatorService.ExplorerHidden = true

local Server = require("./_Server")
local Client = require("./_Client")
local StateRegistry = require("./StateRegistry")
local NetworkOwnership = require("./NetworkOwnership")

ReplicatorService.InitRenderer = function(renderer, renderer_signal, game)
	task.spawn(function()
		local networkService
		repeat
			task.wait()
			networkService = game.NetworkService or (game.GetService and game:GetService("NetworkService"))
		until game.SerializationService
			and networkService
			and type(networkService.RegisterMessageHandler) == "function"
			and type(networkService.SendToServer) == "function"
			and type(networkService.SendToClient) == "function"
			and type(networkService.Broadcast) == "function"

		ReplicatorService:SetProperties({
			RegisterStateAdapter = function(self, name, adapter)
				StateRegistry.RegisterAdapter(name, adapter)
			end,
			StateRegistry = StateRegistry,
			NetworkOwnership = NetworkOwnership,
		})

		local ctx = {
			game = game,
			ReplicatorService = ReplicatorService,
			SerializationService = game:GetService("SerializationService"),
			NetworkService = networkService,
			renderer = renderer,
			signal = renderer_signal,
			StateRegistry = StateRegistry,
			NetworkOwnership = NetworkOwnership,
		}

		if IsServer then
			local ok, err = pcall(Server.init, ctx)
			if not ok then
				warn(`[ReplicatorService] Server.init failed: {err}`)
			end
		end
		if IsClient then
			local ok, err = pcall(Client.init, ctx)
			if not ok then
				warn(`[ReplicatorService] Client.init failed: {err}`)
			end
		end
	end)
end

return ReplicatorService
