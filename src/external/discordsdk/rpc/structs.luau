--!strict
--!optimize 2
--!native

local ffi = zune.ffi

local DiscordRichPresence = ffi.struct({
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
})
export type DiscordRichPresence = typeof(DiscordRichPresence:new({}))

local DiscordUser = ffi.struct({
	{ userId = ffi.types.pointer },
	{ username = ffi.types.pointer },
	{ discriminator = ffi.types.pointer },
	{ avatar = ffi.types.pointer },
})
export type DiscordUser = typeof(DiscordUser:new({}))

local DiscordEventHandlers = ffi.struct({
	{ ready = ffi.types.pointer },
	{ disconnected = ffi.types.pointer },
	{ errored = ffi.types.pointer },
	{ joinGame = ffi.types.pointer },
	{ spectateGame = ffi.types.pointer },
	{ joinRequest = ffi.types.pointer },
})
export type DiscordEventHandlers = typeof(DiscordEventHandlers:new({}))

local structs = {
	DiscordRichPresence = DiscordRichPresence,
	DiscordUser = DiscordUser,
	DiscordEventHandlers = DiscordEventHandlers,
}

return structs
