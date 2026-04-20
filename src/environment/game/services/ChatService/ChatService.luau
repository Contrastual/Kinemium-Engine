local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local ChatService = Instance.new("ChatService")
ChatService.ExplorerHidden = true

ChatService.InitRenderer = function(renderer, renderer_signal)
	ChatService:SetProperties({
		ChatEnabled = true,

		CreateChatMessage = function(player, message) end,
		CreateChatMessageForAll = function(message) end,
		CreateChatMessageForPlayers = function(players, message) end,

		OnMessageServerReplace = function() end,
		OnMessageClientReplace = function(player, message)
			if not player then
				return message
			end
			return `[{player.Name}]: {message}`
		end,
		OnMessageRecieveServer = signal.new(),
		OnMessageRecieveClient = signal.new(),
		GetChatGui = function() end,
	})
end

return ChatService
