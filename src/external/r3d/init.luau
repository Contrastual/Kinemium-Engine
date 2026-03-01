--!strict
--!optimize 2

local dll = "./src/external/raylib/native/bin/"

local ffi = zune.ffi

local structs = require("./r3d/structs")
local funcs = require("./r3d/funcs")
local constants = require("./r3d/constants")

local libname = "r3d." .. ffi.suffix
local assimpname = "assimp-vc145-mt." .. ffi.suffix
local raylibname = "raylib." .. ffi.suffix

ffi.dlopen(dll .. assimpname, {})
ffi.dlopen(dll .. raylibname, {})
local r3d: typeof(funcs) = ffi.dlopen(dll .. libname, funcs)

return {
	lib = r3d,
	structs = structs,
	constants = constants,
}
