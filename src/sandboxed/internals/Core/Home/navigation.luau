if FlagExists("client") then
	return
end

local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local lib = raylib.lib
local renderer = rlservice.renderer
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

local vend = KinemiumFontService.GetDefaultFont()
local arect = require("@Arect")(raylib.lib)

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
local frame = gui.frame({ x = 0, y = 0, width = 0, height = 0 })
local bottomBar = gui.frame({ x = 0, y = 0, width = 0, height = 0 })
local topframe = gui.frame({ x = 0, y = 0, width = screenx, height = 60 })

local mainSignal = Signal.new()

ishared.Home = { signal = mainSignal, rendering = {}, activePage = "" }

local nav = gui.navigation({
	x = 0,
	y = 60,
	width = 60,
	height = lib.GetRenderHeight(),
	items = {},
	selectedColor = StudioThemeService.SelectedTheme.Accent,
	selectedIconColor = SecondaryBackgroundColor,
	font = vend,

	onItemClick = function(item, index)
		ishared.Home.activePage = item.label
		mainSignal:Fire(item.label)
	end,
})

nav.addItem("home", "icon", "Projects")
nav.addItem("compass", "icon", "Explore")
nav.addItem("settings", "icon", "Settings")
nav.addItem("credits", "icon", "Credits")
nav.addItem("marketplace", "icon", "Marketplace")
nav.addItem("marketplace", "icon", "API")

ishared.EnableHomescreen = true

if FlagExists("dhs") then
	return
end
renderer.Pool.new("2d", function()
	if ishared.EnableHomescreen == false then
		game.Context = Enum.GameContext.Editor
		return
	end
	local dt = raylib.lib.GetFrameTime()

	game.Context = Enum.GameContext.Home
	screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

	frame.set("raylib_color", backgroundColor:ToRaylib(0))
	frame.set("obj_rect", arect.new(0, 0, screenx, screeny))
	frame.render(dt)

	for _, objecttoRender in pairs(ishared.Home.rendering) do
		objecttoRender.render(dt)
	end

	local btmbarpos = arect.new(0, screeny - 60, screenx, 60)
	bottomBar.set("raylib_color", SecondaryBackgroundColorRaylib)
	bottomBar.set("obj_rect", btmbarpos)
	bottomBar.render(dt)

	nav.set("obj_rect", arect.new(0, 60, 60, screeny))
	nav.set("backgroundColor", SecondaryBackgroundColor)
	nav.render(dt)

	topframe.set("raylib_color", SecondaryBackgroundColorRaylib)
	topframe.set("obj_rect", arect.new(0, 0, screenx, 60))
	topframe.render(dt)
end, -1)
