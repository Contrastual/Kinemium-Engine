return function(lib, structs)
	local zembed = require("@zembed")

	local function LoadTextureFromFile(path: string)
		return lib.LoadTexture(path)
	end

	local function LoadTextureFromFileAsync(path: string)
		local success, data: buffer? = zune.fs.readFileSync(path, true)
		if success then
			local image = lib.LoadImageFromMemory(lib.GetFileExtension(path), data, buffer.len(data))
			if image ~= zune.ffi.null then
				local texture = lib.LoadTextureFromImage(image)
				lib.UnloadImage(image)
				return texture
			end
		end
		return structs.Texture2D:new({})
	end

	local function GetMaterials()
		local path = "./src/assets/materials/compressed"
		local fs = zune.fs

		local entries
		if zembed.IsEmbedded() then
			entries = zembed.GetFilesThatHas([[assets\materials\compressed]])
		else
			entries = fs.entries(path)
		end

		local result = {}		
		for i, v in pairs(entries) do
			if zembed.IsEmbedded() then
				local basename = fs.path.basename(v)
				result[basename:gsub("(%.%w+)", "")] = "../" .. v
			elseif v.kind == "directory" then
				local directoryPath = "src/assets/materials/compressed/" .. v.name
				local components = fs.entries(directoryPath)

				local albedo, normal, orm
				for i, v in pairs(components) do
					local name = v.name
					local objectPath = directoryPath .. "/" .. name
					if string.match(name, "^albedo%.?") then
						albedo = objectPath
					elseif string.match(name, "^normal%.?") then
						normal = objectPath
					elseif string.match(name, "^orm%.?") then
						orm = objectPath
					end
				end
				
				result[v.name] = {
					albedo = albedo,
					normal = normal,
					orm = orm
				}
			else
				local objectPath = "src/assets/materials/compressed/" .. v.name
				result[v.name:gsub("(%.%w+)", "")] = {
					albedo = objectPath,
					normal = nil,
					orm = nil
				}
			end
		end

		return result
	end

	return {
		LoadTextureFromFile = LoadTextureFromFile,
		LoadTextureFromFileAsync = LoadTextureFromFileAsync,
		GetMaterials = GetMaterials,
	}
end
