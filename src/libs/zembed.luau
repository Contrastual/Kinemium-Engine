local lib = {}

local embeddedScripts = table.freeze(zune.fs.embeddedScripts())
local embeddedFiles = table.freeze(zune.fs.embeddedFiles())

print(embeddedScripts)
print(embeddedFiles)

local isEmbedded = embeddedScripts[1] ~= nil

function lib.IsEmbedded()
	return isEmbedded
end

function lib.Path(path)
	-- assuming "./" if embedded
	return isEmbedded and ("./" .. path) or path
end

function lib.AssetPath(...)
	return zune.fs.path.resolve(isEmbedded and "assets" or "src/assets", ...)
end

function lib.GetEmbeddedScripts()
	return embeddedScripts
end

function lib.GetEmbeddedFiles()
	return embeddedFiles
end

function lib.GetScriptsThatHas(str)
	local results = {}

	for _, script in embeddedScripts do
		if string.find(script, str) then
			table.insert(results, script)
		end
	end

	return results
end

function lib.GetFilesThatHas(str)
	local results = {}

	for _, script in embeddedFiles do
		if string.find(script, str) then
			table.insert(results, script)
		end
	end

	return results
end

lib.readFile = zune.fs.embedFile

return lib
