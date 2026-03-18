local filesystem = {}

local zunefs = zune.fs
local zembed = require("@zembed")

function filesystem.entryloop(path, callback)
	if not zembed.IsEmbedded() then
		local entries = zunefs.entries(path)
		if entries then
			for _, entry in pairs(entries) do
				callback(entry, entries)
			end
		end
	else
		path = string.gsub(path, "/", [[\]])
		print(path)
		local entries = zembed.GetScriptsThatHas(path)
		if entries then
			print(entries)
			for _, path in pairs(entries) do
				local name = zunefs.path.basename(path)
				local kind = zunefs.stat(path).kind
				callback({
					kind = kind,
					path = path,
					name = name,
				}, entries)
			end
		end
	end
	return true
end

filesystem.read = zunefs.readFile

return filesystem
