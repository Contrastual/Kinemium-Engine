local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local ChatService = Instance.new("ChatService")
ChatService.ExplorerHidden = true

ChatService.InitRenderer = function(renderer, renderer_signal)
	ChatService:SetProperties({
		ChatEnabled = true,

		OnMessageServerReplace = function() end,
		OnMessageClientReplace = function(player, message)
			return `[{player.Name}]: {message}`
		end,
		OnMessageRecieveServer = signal.new(),
		OnMessageRecieveClient = signal.new(),
		GetChatGui = function() end,
	})
end

return ChatService
