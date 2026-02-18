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

local engine_fonts = "./src/assets/fonts"
local fontCount = 0

KinemiumFontService.InitRenderer = function(renderer, renderer_signal)
	local default_font = "./src/assets/fonts/Montserrat-Medium.ttf"
	local code_font = "./src/assets/fonts/JetBrainsMono-Light.ttf"

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
			local cache = {}

			for _, font in pairs(fs.entries(engine_fonts)) do
				local path = engine_fonts .. "/" .. font.name
				local transformed = transformFontName(font.name)
				if cache[transformed] then
					continue
				end
				cache[transformed] = true
				renderer.Font.new(transformed, path, 64)
				fontCount += 1
				print("FONTSERVICE | Loaded font " .. transformed)
			end
			print("FONTSERVICE | Loaded " .. fontCount .. " fonts.")
		end,
		FontAdded = FontAdded,
		FontRemoved = FontRemoved,
	})

	KinemiumFontService.LoadAllEngineFonts()
end

return KinemiumFontService
