local Instance = require("@Instance")

local ReplicatorService = Instance.new("ReplicatorService")
ReplicatorService.ExplorerHidden = true

local Server = require("./_Server")
local Client = require("./_Client")
local StateRegistry = require("./StateRegistry")
local NetworkOwnership = require("./NetworkOwnership")

ReplicatorService.InitRenderer = function(renderer, renderer_signal, game)
	task.spawn(function()
		task.wait(4)

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
			Server.init(ctx)
		end
		if IsClient then
			Client.init(ctx)
		end
	end)
end

return ReplicatorService
