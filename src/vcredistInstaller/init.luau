local platform = zune.platform
if platform.os ~= "windows" then
	return true
end

local zembed = require("@zembed")

local arch_map = {
	["x86_64"] = "x64",
	["aarch64"] = "arm64"
}

local arch = arch_map[zune.platform.cpu.arch]
if not arch then
	error("unknown architecture")
end

local path = `./{ zembed.IsEmbedded() and "vcredist" or "src/vcredistInstaller/bin" }/VC_redist.{ arch }.exe`
if zune.fs.stat(path).kind ~= "file" then
	print("No VC++ runtime installer detected, you will have to install manually.")
	return true
end
path = zune.fs.realPath(path)

local state = zune.process.run(path, {
	"/install",
	"/quiet",
	"/norestart",
})

local code = state.code
if code == 0 or code == 1638 then
	print("VC++ runtime ready")
else
	print("Installer failed with code:", code)
end

return true
