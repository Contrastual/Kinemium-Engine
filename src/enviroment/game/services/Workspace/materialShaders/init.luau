local mtsh = {}

local looping = "./src/enviroment/game/services/Workspace/materialShaders/stepped"
local fs = zune.fs

local collected = {}

function mtsh:AddFilters()
	local files = zune.fs.entries(looping)

	for i, file in pairs(files) do
		local path = looping .. "/" .. file.name
		local basename, kind = fs.path.stem(path), file.kind
		local required = require("./materialShaders/stepped/" .. string.gsub(file.name, ".luau", ""))
		collected[basename] = required -- should be a table
	end

	return collected
end

return mtsh
