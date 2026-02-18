--!strict
--!optimize 2

local dll = "./src/external/ode/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local ffi = zune.ffi
local platform = zune.platform

local structs = require("./ode/structs")
local funcs = require("./ode/funcs")
local constants = require("./ode/constants")

local libname = "ode." .. ffi.suffix

local ode: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = ode,
	structs = structs,
	constants = constants,
}
