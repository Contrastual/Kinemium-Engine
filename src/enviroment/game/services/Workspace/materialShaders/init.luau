local mtsh = {}

local looping = "./src/enviroment/game/services/Workspace/materialShaders/stepped"
local fs = zune.fs

local collected = {}

local zembed = require("@zembed")
if zembed.IsEmbedded() then
	looping = zembed.GetFilesThatHas([[materialShaders\stepped]])
end

function mtsh:AddFilters()
	local files = zembed.IsEmbedded() and looping or zune.fs.entries(looping)

	for i, file in pairs(files) do
		local path = zembed.IsEmbedded() and file or looping .. "/" .. file.name
		local basename = fs.path.stem(path)
		local newname = string.gsub(file.name, ".luau", "")
		local required = require(zembed.IsEmbedded() and file or "./materialShaders/stepped/" .. newname)
		collected[basename] = required -- should be a table
	end

	return collected
end

return mtsh
