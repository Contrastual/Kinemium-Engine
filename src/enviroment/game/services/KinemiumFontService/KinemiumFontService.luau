local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local fs = zune.fs

local KinemiumFontService = Instance.new("KinemiumFontService")
KinemiumFontService.ExplorerHidden = true

local FontRemoved = signal.new()
local FontAdded = signal.new()

local function transformFontName(v: string)
	v = string.gsub(v, "%.ttf$", "") -- remove .ttf (literal)
	v = string.gsub(v, "%-.*$", "") -- remove weight after first dash
	return v
end

local zembed = require("@zembed")
local engine_fonts
local fontCount = 0

if zembed.IsEmbedded() then
	engine_fonts = zembed.GetFilesThatHas([[.ttf]])
else
	engine_fonts = "./src/assets/fonts"
end

KinemiumFontService.InitRenderer = function(renderer, renderer_signal)
	local default_font = "./src/assets/fonts/Montserrat-Medium.ttf"
	local code_font = "./src/assets/fonts/JetBrainsMono-Light.ttf"

	if zembed.IsEmbedded() then
		default_font = "." .. default_font
		code_font = "." .. code_font
	end

	local font = renderer.Font.new("DefaultEngineFont", default_font, 32)
	local loaded_cf = renderer.Font.new("DefaultCodeEngineFont", code_font, 32)

	KinemiumFontService:SetProperties({
		LoadFont = function(self, name, fontPath)
			local fontInstance = {}

			FontAdded:Fire(name, fontPath)

			fontInstance.Font = renderer.Font.new(name, fontPath)
			fontInstance.Unload = function()
				renderer.Font.Remove(name)
				FontRemoved:Fire(fontPath)
			end
			return fontInstance
		end,

		GetDefaultFontSmall = function()
			return font
		end,

		GetDefaultFont = function()
			return font
		end,

		GetMonoFontDefault = function()
			return loaded_cf
		end,

		LoadAllEngineFonts = function()
			local fontsLoadStart = os.clock()
			local cache = {}

			for _, font in pairs(type(engine_fonts) == "string" and fs.entries(engine_fonts) or engine_fonts) do
				local fontLoadStart = os.clock()
				local path = zembed.IsEmbedded() and "../" .. font or engine_fonts .. "/" .. font.name
				local transformed = transformFontName(zembed.IsEmbedded() and zune.fs.path.basename(path) or font.name)
				if cache[transformed] then
					continue
				end
				cache[transformed] = true
				renderer.Font.new(transformed, path, 64)
				fontCount += 1
				print(string.format("FONTSERVICE | Loaded font %s in %.3fms", transformed, (os.clock() - fontLoadStart) * 1000))
			end
			print(string.format("FONTSERVICE | Loaded %i fonts in %.2fs", fontCount, os.clock() - fontsLoadStart))
		end,
		FontAdded = FontAdded,
		FontRemoved = FontRemoved,
	})

	KinemiumFontService.LoadAllEngineFonts()
end

return KinemiumFontService
