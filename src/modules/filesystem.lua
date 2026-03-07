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
		local entries = zembed.GetScriptsThatHas(path)
		if entries then
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

function filesystem.read(file)
	return zunefs.readFile(file)
end

return filesystem
