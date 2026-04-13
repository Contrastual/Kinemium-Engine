local raylib = require("@raylib")
local lib = raylib.lib
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")

local vend = KinemiumFontService.GetDefaultFont()
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
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
