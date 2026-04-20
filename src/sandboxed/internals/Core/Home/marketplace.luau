local raylib = require("@raylib")
local lib = raylib.lib
local aereon = import("@Aereon")
local gui = aereon.gui

local KinemiumFontService = game:GetService("KinemiumFontService")

local vend = KinemiumFontService.GetDefaultFont()
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local logoPath = "./src/assets/images/icons/vanilla3/kinemium/KinemiumWhite.png"
local kilLogo = KinemiumIconLoader.ToTexture(logoPath)

local activePluginPage = nil
local scrollY = 0

local StudioThemeService = game:GetService("StudioThemeService")

local backButton = gui.button({
	x = 60,
	y = 20,
	width = 100,
	height = 30,
	text = "<- Back",
	fontSize = 20,
	onClick = function()
		activePluginPage = nil
	end,
})

local function createCard(plugin)
	local manifest = plugin.manifest
	local card = gui.itemcard({
		x = 100,
		y = 100,
		width = 300,
		height = 300,

		title = manifest.name,
		description = manifest.description or "",
		downloads = "0",
		likes = "0",
		category = manifest.keywords and manifest.keywords[1] or "Plugin",

		font = vend,

		onClick = function()
			activePluginPage = plugin.manifest.id
		end,
	})

	return card
end

local function createPage(plugin)
	local manifest = plugin.manifest
	local modcard = gui.modcard({
		x = 60,
		y = 60,
		width = 1280,
		height = 800,
		font = vend,
		boldFont = vend,

		title = manifest.name,
		description = manifest.description or "",
		downloads = "0",
		likes = "0",
		category = manifest.keywords and manifest.keywords[1] or "Plugin",

		sections = {
			{ type = "heading", text = manifest.name },
			{ type = "text", text = manifest.description or "No description provided." },
		},

		compatibility = {
			game = "Kinemium Engine",
			versions = { "1.0.0" },
		},
		platforms = { "Any" },
		environments = { "Client-side", "Server-side" },
		backgroundTransparency = 1,

		accent = StudioThemeService.SelectedTheme.Accent,
		tabBarBg = StudioThemeService.SelectedTheme.SecondaryBackgroundColor,
		pageBg = StudioThemeService.SelectedTheme.BackgroundColor,
		headerBg = StudioThemeService.SelectedTheme.SecondaryBackgroundColor,
		iconBg = StudioThemeService.SelectedTheme.SecondaryBackgroundColor,
		text = StudioThemeService.SelectedTheme.Text,
		muted = StudioThemeService.SelectedTheme.Muted,
		bg = StudioThemeService.SelectedTheme.BackgroundColor,
		lightText = StudioThemeService.SelectedTheme.LightText,
		sidebarBg = StudioThemeService.SelectedTheme.SecondaryBackgroundColor,
		buttonBg = StudioThemeService.SelectedTheme.Accent,
		buttonBgHover = StudioThemeService.SelectedTheme.Accent,

		onDownload = function()
			game.PluginLoader.LoadPlugin(plugin.manifest.id)
		end,
	})
	return modcard
end

local cards = {}
local pages = {}

local plugins

repeat
	task.wait()
until ishared.Home

local arect = require("@Arect")(raylib.lib)

table.insert(ishared.Home.rendering, {
	render = function(dt)
		if ishared.Home.activePage ~= "Marketplace" then
			return
		end

		if not plugins then
			plugins = game.PluginLoader.GetPluginsMarketplace()
			for _, plugin in pairs(plugins) do
				table.insert(cards, createCard(plugin))
				pages[plugin.manifest.id] = createPage(plugin)
				print("Created for plugin " .. plugin.manifest.name)
			end
		end

		local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

		if activePluginPage then
			local page = pages[activePluginPage]
			if page then
				page.set("obj_rect", arect.new(60, 60, screenx - 120, screeny - 120))
				page.render(dt)
			end
			backButton.render(dt)
			return
		end

		-- Handle scrolling
		local wheel = lib.GetMouseWheelMove()
		if wheel ~= 0 then
			scrollY = scrollY - wheel * 40
			if scrollY < 0 then
				scrollY = 0
			end
		end

		local startX = 60
		local startY = 60 - scrollY
		local padding = 20
		local cardWidth = 300
		local cardHeight = 300

		local x = startX
		local y = startY

		for _, card in ipairs(cards) do
			card.set("obj_rect", arect.new(x, y, cardWidth, cardHeight))
			card.render(dt)

			x = x + cardWidth + padding
			if x + cardWidth > screenx - 60 then
				x = startX
				y = y + cardHeight + padding
			end
		end

		local contentHeight = y + cardHeight - startY + padding
		local maxScroll = math.max(0, contentHeight - screeny + 60)
		if scrollY > maxScroll then
			scrollY = maxScroll
		end
	end,
})
