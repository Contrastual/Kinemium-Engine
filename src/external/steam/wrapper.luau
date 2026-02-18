local dll = "./src/external/steam/bin/"
local ffi = zune.ffi
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local bindings = require("./bindings")

local libname = "steam_api." .. ffi.suffix
local steam: typeof(bindings.funcs) = ffi.dlopen(dll .. libname, bindings.funcs)

return {
	lib = steam,
	structs = bindings.structs,
}
