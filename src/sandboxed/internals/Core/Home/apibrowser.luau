local rlservice = game:GetService("KinemiumRaylib")
local raylib = import("@raylib")
local lib = raylib.lib
local renderer = rlservice.renderer
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")

local vend = KinemiumFontService.GetDefaultFont()
local arect = import("@Arect")(raylib.lib)
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

local categories = import("@apidumpbrowser")

local browser = gui.apibrowser({
	x = 50,
	y = 50,
	categories = categories,
	width = 800,
	height = 600,
	fontSize = 25,
	font = vend,
	onItemSelect = function(item)
		print("Selected:", item.name, item.type)
	end,
})

repeat
	task.wait()
until ishared.Home

table.insert(ishared.Home.rendering, {
	render = function(dt)
		if ishared.Home.activePage ~= "API" then
			return
		end

		screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

		browser.set("backgroundColor", backgroundColor)
		browser.set("headerColor", SecondaryBackgroundColor)

		browser.set("obj_rect", arect.new(70, 60, screenx - 60, screeny - 60))
		browser.render(dt)
	end,
})
