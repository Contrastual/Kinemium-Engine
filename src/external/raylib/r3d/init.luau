--!strict
--!optimize 2

local dll = "./src/external/raylib/native/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local ffi = zune.ffi

local structs = require("./r3d/structs")
local funcs = require("./r3d/funcs")
local constants = require("./r3d/constants")

local libname = "r3d." .. ffi.suffix
local assimpname = "assimp-vc145-mt." .. ffi.suffix
local raylibname = "raylib." .. ffi.suffix

local asmpPath = dll .. assimpname

local stat = zune.fs.stat(dll .. assimpname)

if stat.kind == "none" then
	print("Did not find assimp LIB, Listing all files in searching directory")
	local entries = zune.fs.entries(dll)
	print(entries)
	return {}
end

warn("Requiring " .. asmpPath)
warn("Requiring " .. dll .. raylibname)
warn("Requiring " .. dll .. libname)

if zune.platform.os == "windows" then
	warn("Checking windows system deps:")
	warn("KERNEL32", zune.fs.stat("C:/Windows/System32/kernel32.dll").kind == "file" and "OK" or "NOT FOUND")
	warn("MSVCP140D", zune.fs.stat("C:/Windows/System32/MSVCP140D.dll").kind == "file" and "OK" or "NOT FOUND")
	warn("VCRUNTIME140D", zune.fs.stat("C:/Windows/System32/VCRUNTIME140D.dll").kind == "file" and "OK" or "NOT FOUND")
	warn(
		"VCRUNTIME140_1D",
		zune.fs.stat("C:/Windows/System32/VCRUNTIME140_1D.dll").kind == "file" and "OK" or "NOT FOUND"
	)
	warn("ucrtbased", zune.fs.stat("C:/Windows/System32/ucrtbased.dll").kind == "file" and "OK" or "NOT FOUND")
end

warn("Checking dll deps exists:")
warn("raylib", zune.fs.stat(dll .. raylibname).kind == "file" and "OK" or "NOT FOUND")
warn("r3d", zune.fs.stat(dll .. libname).kind == "file" and "OK" or "NOT FOUND")
warn("assimp", zune.fs.stat(dll .. assimpname).kind == "file" and "OK" or "NOT FOUND")

ffi.dlopen(asmpPath, {})
ffi.dlopen(dll .. raylibname, {})

local r3d: typeof(funcs) = ffi.dlopen(dll .. libname, funcs)

return {
	lib = r3d,
	structs = structs,
	constants = constants,
}
