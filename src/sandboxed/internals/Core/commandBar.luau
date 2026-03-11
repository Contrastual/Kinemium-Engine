-- devcell

if FlagExists("client") then
	return
end

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local syntax_highlighter = require("@syntax_highlighter")
local syntax_autocomplete = require("@syntax_autocomplete")
local aereon = require("@Aereon")

local renderer = KinemiumRaylib.renderer
local vend = KinemiumFontService.GetDefaultFont()
local raylib = require("@raylib")

local theme = StudioThemeService.SelectedTheme
local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)

local kilang = require("@Kilang")

local box = textbox.new({
	multiline = false,
	placeholder = "Enter Kilang code here..",
	fontSize = 16,
	font = vend,
	backgroundColor = theme.SecondaryBackgroundColor,
	borderColor = theme.SecondaryBackgroundColor,
	syntaxHighlighter = syntax_highlighter.highlight,
	autocompleteProvider = syntax_autocomplete,

	onSubmit = function(new)
		kilang:execute(new, {
			SecurityCapabilities = Enum.SecurityCapabilities.Internals,
		})
	end,
})

renderer.Pool.new("2d", function()
	if game.Context ~= Enum.GameContext.Editor then
		return
	end
	box:drawWithExtras(0, raylib.lib.GetRenderHeight() - 30, raylib.lib.GetRenderWidth(), 30)
end, 10)
