local dll = "./src/external/manifold/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local ffi = zune.ffi
local platform = zune.platform

local fileFormat = ".dll"

local bindings = require("./bindings")

local libname = "manifoldc." .. ffi.suffix

if platform.os == "windows" then
	local success, result = pcall(function()
		ffi.dlopen(dll .. "manifold" .. fileFormat, {})
	end)
	warn(success, result)
end

local manifoldCSG: typeof(bindings.funcs) = ffi.dlopen(dll .. libname, bindings.funcs)

return {
	lib = manifoldCSG,
	structs = bindings.structs,
}
