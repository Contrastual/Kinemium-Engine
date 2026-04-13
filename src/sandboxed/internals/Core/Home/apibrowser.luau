local raylib = require("@raylib")
local lib = raylib.lib
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")

local vend = KinemiumFontService.GetDefaultFont()
local arect = require("@Arect")(raylib.lib)
local backgroundColor = StudioThemeService.SelectedTheme.BackgroundColor
local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor

local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

local categories = require("@apidumpbrowser")

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
