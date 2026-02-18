local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local fs = zune.fs

local KinemiumIconLoader = Instance.new("KinemiumIconLoader")
KinemiumIconLoader.ExplorerHidden = true
local raylib = require("@raylib")
local lib = raylib.lib

local general = "./src/assets/images/icons/vanilla3/general/32x/200"
local objects = "./src/assets/images/icons/vanilla3/instance/16x/200"
local kinemiumIcons = "./src/assets/images/icons/vanilla3/kinemium"

KinemiumIconLoader.InitRenderer = function(renderer, renderer_signal)
	local registry = {}
	local textures = {}

	local function reload()
		table.clear(registry)
		table.clear(textures)

		for _, file in pairs(fs.entries(general)) do
			registry[file.name] = general .. "/" .. file.name
		end

		for _, file in pairs(fs.entries(objects)) do
			registry[file.name] = objects .. "/" .. file.name
		end

		for _, file in pairs(fs.entries(kinemiumIcons)) do
			registry[file.name] = kinemiumIcons .. "/" .. file.name
		end
	end

	KinemiumIconLoader:SetProperties({
		Reload = reload,
		ToTexture = function(path: string)
			if textures[path] then
				return textures[path]
			end

			local texture = lib.LoadTexture(path)
			local size = vector.create(buffer.readi32(texture, 4), buffer.readi32(texture, 8))

			local data = {
				texture = texture,
				x = size.x,
				y = size.y,
			}
			lib.SetTextureFilter(texture, raylib.const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
			lib.SetTextureWrap(texture, raylib.const.TextureWrap.TEXTURE_WRAP_CLAMP)
			lib.GenTextureMipmaps(texture)

			textures[path] = data
			return data
		end,
		new = function(name, path)
			registry[name] = path
		end,
		Get = function(name)
			return registry[name]
		end,
		Remove = function(name)
			registry[name] = nil
		end,
		Change = function(name, newPath)
			if not registry[name] then
				return
			end
			registry[name] = newPath
		end,
		LoadAutoTexture = function(name, path)
			if textures[path] then
				return textures[path].texture
			end

			local texture = lib.LoadTexture(path)
			registry[name] = path

			textures[path] = {
				texture = texture,
				x = 0,
				y = 0,
			}

			lib.SetTextureFilter(texture, raylib.const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
			lib.SetTextureWrap(texture, raylib.const.TextureWrap.TEXTURE_WRAP_CLAMP)
			lib.GenTextureMipmaps(texture)

			return texture
		end,
		Cleanup = function()
			for _, data in pairs(textures) do
				lib.UnloadTexture(data.texture)
			end
			table.clear(textures)
		end,
	})

	reload()

	return registry
end

return KinemiumIconLoader
