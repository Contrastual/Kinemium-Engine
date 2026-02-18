local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type DiscordEventHandlers = structs.DiscordEventHandlers
type DiscordRichPresence = structs.DiscordRichPresence
type DiscordUser = structs.DiscordUser

export type Fns = {
	Discord_ClearPresence: () -> (),
	Discord_Initialize: (
		applicationId: cstring,
		handlers: FFIPointer,
		autoRegister: int,
		optionalSteamId: cstring
	) -> (),
	Discord_Register: (applicationId: cstring, command: cstring) -> (),
	Discord_RegisterSteamGame: (applicationId: cstring, steamId: cstring) -> (),
	Discord_Respond: (userid: cstring, reply: int) -> (),
	Discord_RunCallbacks: () -> (),
	Discord_Shutdown: () -> (),
	Discord_UpdateHandlers: (handlers: FFIPointer) -> (),
	Discord_UpdatePresence: (presence: FFIPointer) -> (),
}

local funcs = {
	Discord_Register = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	Discord_RegisterSteamGame = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	Discord_Initialize = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	Discord_Shutdown = { returns = ffi.types.void, args = {} },
	Discord_RunCallbacks = { returns = ffi.types.void, args = {} },
	Discord_UpdatePresence = { returns = ffi.types.void, args = { ffi.types.pointer } },
	Discord_ClearPresence = { returns = ffi.types.void, args = {} },
	Discord_Respond = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	Discord_UpdateHandlers = { returns = ffi.types.void, args = { ffi.types.pointer } },
}

return funcs
