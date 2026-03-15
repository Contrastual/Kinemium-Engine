--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "../bin/"
local ffi = zune.ffi
local platform = zune.platform

local structs = require("./structs")
local funcs = require("./funcs")
local constants = require("./constants")

local libname = "sail-manip." .. ffi.suffix

local sail_manip: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = sail_manip,
	structs = structs,
	constants = constants,
}
