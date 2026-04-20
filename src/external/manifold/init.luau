--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "./"
local ffi = zune.ffi
local platform = zune.platform

local structs = require("./structs")
local funcs = require("./funcs")
local constants = require("./constants")

local libname = "manifold." .. ffi.suffix

local manifold: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = manifold,
	structs = structs,
	constants = constants,
}