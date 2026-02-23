local dll = "./src/external/jolt/bin/"
local ffi = zune.ffi
local platform = zune.platform

local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end

local structs = require("./structs")
local funcs = require("./funcs")

local libname = "joltc."..ffi.suffix

local jolt: typeof(funcs) = ffi.dlopen(dll .. libname, funcs)

return {
	lib = jolt,
	structs = structs,
}
