--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "./src/external/discordsdk/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local ffi = zune.ffi

local structs = require("./rpc/structs")
local funcs = require("./rpc/funcs")
local constants = require("./rpc/constants")

local libname = "rpc." .. ffi.suffix

local discordrpc: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = discordrpc,
	structs = structs,
	constants = constants,
}
