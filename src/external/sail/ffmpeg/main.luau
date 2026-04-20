--!strict
local fs = zune.fs
local ffi = zune.ffi
local net = zune.net
local serde = zune.serde
local platform = zune.platform

local tar = require("./lib/tar")
local zip = require("./lib/zip")

local FFMPG_URL = `https://github.com/BtbN/FFmpeg-Builds/releases/tag/latest`
local file_path_windows = `ffmpeg-master-latest-win64-gpl-shared`
local file_path_linux64 = `ffmpeg-master-latest-linux64-gpl-shared`

local binPath = "./src/external/sail/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	binPath = "./"
end

--bindings
local avcodec = require("./avcodec")
local avformat = require("./avformat")
local avutil = require("./avutil")
local swresample = require("./swresample")
local swscale = require("./swscale")

local function combine(...: { [string]: any })
	local list = { ... }
	local first = table.remove(list, 1)
	assert(first)
	local result = table.clone(first)
	for _, tbl in list do
		for k, v in tbl do
			result[k] = v
		end
	end
	return result
end

local function request(link: string, options: any, bytes: boolean?): HttpResponse<buffer | string>
	local res = net.http.request(link, options, bytes)
	if res.status_code == 302 or res.status_code == 301 then
		local location = res.headers["location"]
		if location then
			return request(location, options, bytes)
		else
			error("Redirection without location")
		end
	end
	return res
end

local FFMPG_ASSET_WINDOWS = "ffmpeg-master-latest-win64-gpl-shared.zip"
local FFMPG_ASSET_LINUX = "ffmpeg-master-latest-linux64-gpl-shared.tar.gz"

local function getDownloadURL()
	if platform.os == "windows" then
		return `https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/{FFMPG_ASSET_WINDOWS}`
	elseif platform.os == "macos" then
		error("FFmpeg prebuilt binaries for macOS are not available. You must clone and compile FFmpeg as a shared library and place it in the src/external/sail/bin directory.")
	else
		return `https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/{FFMPG_ASSET_LINUX}`
	end
end

local BIN_LOCATION = "./src/external/sail/bin/"
if zembed.IsEmbedded() then
	warn("Detected kinemium executable")
	BIN_LOCATION = "./"
end

local LIBRARY_PATH = fs.path.resolve(BIN_LOCATION, `avcodec-62.{ffi.suffix}`)

if fs.stat(LIBRARY_PATH).kind == "none" then
	if platform.os == "macos" then
		error("FFmpeg prebuilt binaries for macOS are not available. You must clone and compile FFmpeg as a shared library and place the dylib files in the src/external/sail/bin directory.")
	end

	log(`Downloading FFmpeg for {platform.os}-{platform.cpu.arch}...`)

	local res = request(getDownloadURL(), {
		method = "GET",
		headers = {
			["Accept"] = "application/octet-stream, */*",
			["Connection"] = "keep-alive",
		},
		max_body_size = 1024 * 1024 * 5000, -- 5 GB
	}, true)

	log(res)

	if not res.ok then
		error(`Failed to download FFmpeg: {res.status_code}`)
	end

	local archive = res.body :: buffer

	if zip.is(archive) then
		local files = zip.read(archive)
		log("Started ZIP")
		for name, data in files do
			if name:match("^.*/bin/") and not string.find(name, "exe") then
				log(`Adding {name}`)

				local filename = name:match("bin/(.+)$")
				if filename then
					local dest = fs.path.resolve(BIN_LOCATION, filename) -- write each file separately
					fs.writeFile(dest, data)
				end
			end
		end
	else
		local decompressed = serde.gzip.decompress(archive)
		log("Started TAR")

		for name, data in tar.read(decompressed) do
			if name:match("^.*/bin/") and not string.find(name, "exe") then
				log(`Adding {name}`)

				local filename = name:match("bin/(.+)$")
				if filename then
					local dest = fs.path.resolve(BIN_LOCATION, filename)
					fs.writeFile(dest, data)
				end
			end
		end
	end
end

local lib = {
	structs = combine(avcodec.structs, avformat.structs, avutil.structs, swscale.structs) :: typeof(avcodec.structs) & typeof(avformat.structs) & typeof(avutil.structs) & typeof(swscale.structs),
}

local avutil_lib = ffi.dlopen(binPath .. "avutil-60." .. ffi.suffix, avutil.funcs)
log("Loaded avutil")
local swresample_lib = ffi.dlopen(binPath .. "swresample-6." .. ffi.suffix, swresample.funcs)
log("Loaded swresample")
local avcodec_lib = ffi.dlopen(binPath .. "avcodec-62." .. ffi.suffix, avcodec.funcs)
log("Loaded avcodec")
local avformat_lib = ffi.dlopen(binPath .. "avformat-62." .. ffi.suffix, avformat.funcs)
log("Loaded avformat")
local swscale_lib = ffi.dlopen(binPath .. "swscale-9." .. ffi.suffix, swscale.funcs)
log("Loaded swscale")

lib.avcodec_structs = avcodec.structs :: typeof(avcodec.structs)
lib.avformat_structs = avformat.structs :: typeof(avformat.structs)

lib.avutil = avutil_lib :: typeof(avutil.funcs)
lib.avformat = avformat_lib :: typeof(avformat.funcs)
lib.avcodec = avcodec_lib :: typeof(avcodec.funcs)
lib.swresample = swresample_lib :: typeof(swresample.funcs)
lib.swscale = swscale_lib :: typeof(swscale.funcs)

log("Successfully loaded FFMpeg!")

return lib
