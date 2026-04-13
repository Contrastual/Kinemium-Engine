local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	return
end
local InternalStorage = game:GetService("InternalStorage")

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "ChatRemote"
remoteEvent.Parent = InternalStorage

local ChatService = game:GetService("ChatService")

local cache = {}

local validateMessage = Schema.allOf(Schema.nonEmptyString(), Schema.length(1, 200))
local lastMessageTime = {}

local function getPlayerColor(player)
	return Color3.fromHSV((player.UserId % 100) / 100, 0.7, 1)
end

remoteEvent.OnServerEvent:Connect(function(player, message)
	local now = os.clock()

	if not validateMessage(message) then
		return
	end
	if (lastMessageTime[player.UserId] or 0) + 0.5 > now then
		return
	end
	lastMessageTime[player.UserId] = now

	table.insert(cache, {
		player = player.UserId,
		message = message,
	})

	ChatService.ChatCache = cache

	ChatService.OnMessageRecieveServer:Fire(player, message)

	if ChatService.OnMessageServerReplace then
		message = ChatService.OnMessageServerReplace(player, message) or message
	end

	remoteEvent:FireAllClients({
		name = player.Name,
		message = message,
		color = getPlayerColor(player),
	})
end)
