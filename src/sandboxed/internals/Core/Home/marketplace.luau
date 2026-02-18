local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local lib = raylib.lib
local renderer = rlservice.renderer
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")

local vend = KinemiumFontService.GetDefaultFont()
local arect = require("@Arect")(raylib.lib)
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

local backgroundColor = StudioThemeService.SelectedTheme.BackgroundColor
local TextColor = StudioThemeService.SelectedTheme.TextColor:ToRaylib(StudioThemeService.SelectedTheme.TextTransparency)
local GuiHandlesColor =
	StudioThemeService.SelectedTheme.GuiHandlesColor:ToRaylib(StudioThemeService.SelectedTheme.GuiHandlesTransparency)
local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor
local SecondaryBackgroundColorRaylib = StudioThemeService.SelectedTheme.SecondaryBackgroundColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryBackgroundColorTransparency
)
local SecondaryTextColor = StudioThemeService.SelectedTheme.SecondaryTextColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryTextTransparency
)
local ImageColor =
	StudioThemeService.SelectedTheme.ImageColor:ToRaylib(StudioThemeService.SelectedTheme.ImageTransparency)

local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

local logoPath = "./src/assets/images/icons/vanilla3/kinemium/KinemiumWhite.png"
local kilLogo = KinemiumIconLoader.ToTexture(logoPath)

local card = gui.itemcard({
	x = 100,
	y = 100,
	width = 300,
	height = 300,

	title = "JS Kilang Superset",
	description = "This adds a Javascript superset to kilang, lets you code games in JS!",
	downloads = "67.41M",
	likes = "67",
	category = "Scripting",

	icon = kilLogo,
	font = vend,
	bannerImage = kilLogo,

	onClick = function()
		print("Card clicked!")
	end,
})

repeat
	task.wait()
until ishared.Home

table.insert(ishared.Home.rendering, {
	render = function(dt)
		if ishared.Home.activePage ~= "Marketplace" then
			return
		end

		screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

		card.render(dt)
	end,
})
