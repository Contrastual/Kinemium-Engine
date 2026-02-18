local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local discordlib = require("@discord")
local structs = discordlib.rpc.structs
local kinemium_discord_rpc = require("./DiscordService/rpc")
local bufferUtils = require("@bufferUtils")

local DiscordService = Instance.new("DiscordService")
DiscordService.ExplorerHidden = true

--[[
	{ state = ffi.types.pointer },
	{ details = ffi.types.pointer },
	{ startTimestamp = ffi.types.i64 },
	{ endTimestamp = ffi.types.i64 },
	{ largeImageKey = ffi.types.pointer },
	{ largeImageText = ffi.types.pointer },
	{ smallImageKey = ffi.types.pointer },
	{ smallImageText = ffi.types.pointer },
	{ partyId = ffi.types.pointer },
	{ partySize = ffi.types.i32 },
	{ partyMax = ffi.types.i32 },
	{ matchSecret = ffi.types.pointer },
	{ joinSecret = ffi.types.pointer },
	{ spectateSecret = ffi.types.pointer },
	{ instance = ffi.types.i8 },
--]]

DiscordService.InitRenderer = function(renderer, renderer_signal)
	local mainRpc = structs.DiscordRichPresence:new({})

	local rpc = {
		state = bufferUtils.stringToPtr("Idle.."),
		details = bufferUtils.stringToPtr("Hm......"),
	}

	kinemium_discord_rpc:init("1466374312389902481")
	kinemium_discord_rpc:CreateRPC(rpc)

	DiscordService:SetProperties({
		SetRPC = function(rpcData)
			for i, v in pairs(rpcData) do
				if type(v) == "string" then
					rpcData[i] = bufferUtils.stringToPtr(v)
				end
			end
			kinemium_discord_rpc:CreateRPC(rpcData)
		end,
	})

	renderer_signal:Connect(function(route, dt)
		if route == "Renderstepped" then
			kinemium_discord_rpc:step()
			--rpclib.Discord_RunCallbacks()
		end
	end)
end

return DiscordService
