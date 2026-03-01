--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local ffi = zune.ffi
local structs = require("./ole32/structs")
local funcs = require("./ole32/funcs")
local constants = require("./ole32/constants")

local ole32: funcs.Fns = ffi.dlopen("C:/Windows/System32/ole32.dll", funcs)

return {
	lib = ole32,
	structs = structs,
	constants = constants,
}
