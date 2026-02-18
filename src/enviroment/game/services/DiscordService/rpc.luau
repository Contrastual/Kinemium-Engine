local discordRPC = require("@discord")

local rpc = discordRPC.rpc
local structs = rpc.structs
local ffi = zune.ffi

export type DiscordPresence = {
	state: string?, -- optional string, max 127 chars
	details: string?,
	startTimestamp: number?, -- optional integer
	endTimestamp: number?,
	largeImageKey: string?,
	largeImageText: string?,
	smallImageKey: string?,
	smallImageText: string?,
	partyId: string?,
	partySize: number?, -- optional integer
	partyMax: number?,
	matchSecret: string?,
	joinSecret: string?,
	spectateSecret: string?,
	instance: number?,
}

-- event handlers
--[[
	{ ready = ffi.types.pointer },
	{ disconnected = ffi.types.pointer },
	{ errored = ffi.types.pointer },
	{ joinGame = ffi.types.pointer },
	{ spectateGame = ffi.types.pointer },
	{ joinRequest = ffi.types.pointer },
--]]

local luaHandlers = {
	ready = function(userId, username, discriminator, avatar)
		print("Discord RPC Ready!")
	end,
	disconnected = function(errorCode, message)
		print("Discord RPC Disconnected")
	end,
	errored = function(errorCode, message)
		print("Discord RPC errored")
	end,
	joinGame = function(joinSecret)
		print("Discord RPC errored")
	end,
	joinRequest = function(userId, username, discriminator, avatar)
		print("Discord RPC joinRequest")
	end,
	spectateGame = function(spectateSecret)
		print("Discord RPC spectateGame")
	end,
}

local discordservice_rpc = {}

function discordservice_rpc:SetLuaHandler(name, handler)
	luaHandlers[name] = handler
end

function discordservice_rpc:CreateDiscordHandlers()
	local closureshandlers = {
		ready = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32, ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
		}, luaHandlers.ready),

		disconnected = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32, ffi.types.pointer },
		}, luaHandlers.disconnected),

		errored = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32, ffi.types.pointer },
		}, luaHandlers.errored),

		joinGame = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32 },
		}, luaHandlers.joinGame),

		spectateGame = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32 },
		}, luaHandlers.spectateGame),

		joinRequest = ffi.closure({
			returns = ffi.types.void,
			args = { ffi.types.i32, ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
		}, luaHandlers.joinRequest),
	}
	return structs.DiscordEventHandlers:new(closureshandlers)
end

function discordservice_rpc:init(appId)
	local handlers = discordservice_rpc:CreateDiscordHandlers()
	rpc.lib.Discord_Initialize(appId, handlers, 0)
end

function discordservice_rpc:CreateRPC(rpcData: DiscordPresence)
	local cpresence = structs.DiscordRichPresence:new({
		state = rpcData.state or nil,
		details = rpcData.details or nil,
		startTimestamp = rpcData.startTimestamp or 0,
		endTimestamp = rpcData.endTimestamp or 0,
		largeImageKey = rpcData.largeImageKey or nil,
		largeImageText = rpcData.largeImageText or nil,
		smallImageKey = rpcData.smallImageKey or nil,
		smallImageText = rpcData.smallImageText or nil,
		partyId = rpcData.partyId or nil,
		partySize = rpcData.partySize or 0,
		partyMax = rpcData.partyMax or 0,
		matchSecret = rpcData.matchSecret or nil,
		joinSecret = rpcData.joinSecret or nil,
		spectateSecret = rpcData.spectateSecret or nil,
		instance = rpcData.instance or 0,
	})

	rpc.lib.Discord_UpdatePresence(cpresence)
	return cpresence
end

function discordservice_rpc:step()
	rpc.lib.Discord_RunCallbacks()
end

return discordservice_rpc
