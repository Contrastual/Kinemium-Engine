-- devcell

if FlagExists("client") then
	return
end

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local Selection = game:GetService("Selection")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ScriptRunnerService = game:GetService("ScriptRunnerService")
local aereon = require("@Aereon")

local gui = aereon.gui
local LocalPlayer = Players.LocalPlayer
local rl = KinemiumRaylib.lib
local structs = KinemiumRaylib.structs
local renderer = KinemiumRaylib.renderer
local EngineSignal = game.EngineSignal
local vend = KinemiumFontService.GetDefaultFont()
local raylib = require("@raylib")

local theme = StudioThemeService.SelectedTheme
local themeColors = {
	background = theme.BackgroundColor:ToRaylib(theme.BackgroundTransparency),
	text = theme.TextColor:ToRaylib(theme.TextTransparency),
	guiHandles = theme.GuiHandlesColor:ToRaylib(theme.GuiHandlesTransparency),
	secondaryBackground = theme.SecondaryBackgroundColor:ToRaylib(theme.SecondaryBackgroundColorTransparency),
	secondaryText = theme.SecondaryTextColor:ToRaylib(theme.SecondaryTextTransparency),
	image = theme.ImageColor:ToRaylib(theme.ImageTransparency),
	arrowImage = theme.ArrowImageColor:ToRaylib(0),
}

local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)

local kilang = require("@Kilang")

local box = textbox.new({
	multiline = false,
	placeholder = "Enter Kilang code here..",
	fontSize = 16,
	font = vend,
	backgroundColor = theme.SecondaryBackgroundColor,
	borderColor = theme.SecondaryBackgroundColor,

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
