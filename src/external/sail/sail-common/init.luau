--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "./src/external/sail/bin/"
local ffi = zune.ffi

local structs = require("./structs")
local funcs = require("./funcs")
local constants = require("./constants")

local libname = "sail-common." .. ffi.suffix

local sail_common: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = sail_common,
	structs = structs,
	constants = constants,
}
