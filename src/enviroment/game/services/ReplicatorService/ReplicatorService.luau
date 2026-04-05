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

		repeat
			task.wait()
		until game.SerializationService and game.NetworkService

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
			NetworkService = game:GetService("NetworkService"),
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
