local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local lib = raylib.lib
local renderer = rlservice.GetRenderer()
local aereon = require("@Aereon")
local gui = aereon.gui
local rect = require("@Arect")(lib)
local transparent = Color3.new(1, 1, 1):ToRaylib(0.5)

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local FileDialogService = game:GetService("FileDialogService")
local DiscordService = game:GetService("DiscordService")
local ProcessService = game:GetService("Process")
local NetworkService = game:GetService("NetworkService")

local vend = KinemiumFontService.GetDefaultFontSmall()
local arect = require("@Arect")(raylib.lib)
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

local defaultKinemiumIcon = "./src/assets/images/kinemium/KinemiumWhite.png"
local logoIcon = KinemiumIconLoader.ToTexture(defaultKinemiumIcon)

local backgroundColor = StudioThemeService.SelectedTheme.BackgroundColor
local TextColor = StudioThemeService.SelectedTheme.TextColor:ToRaylib(StudioThemeService.SelectedTheme.TextTransparency)

local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor
local SecondaryBackgroundColorRaylib = StudioThemeService.SelectedTheme.SecondaryBackgroundColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryBackgroundColorTransparency
)
local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

KinemiumIconLoader.new("Add", "./src/assets/images/plus.png")

local addIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Add"))

local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)

local usernameTextbox = textbox.new({
	multiline = false,
	placeholder = "Enter your username",
	fontSize = 16,
	font = vend,
	maxLength = 56,
})

local serverAddress_Textbox = textbox.new({
	multiline = false,
	placeholder = "Enter server address",
	fontSize = 16,
	font = vend,
	maxLength = 56,
})

local serverPort_Textbox = textbox.new({
	multiline = false,
	placeholder = "Enter server port",
	fontSize = 16,
	font = vend,
	maxLength = 56,
})

--[[
example server preview data:

[RUNTIME]       <table: 0x1c8dcfbbd20> {
    port = 1234,
    motd = "A Kinemium server is online.",
    server = <table: 0x1c8dcfbbcf0> {
        tickRate = 30,
        startedAt = 1775734828,
        uptime = 98,
        tick = 2950,
    },
    players = <table: 0x1c8dcfbbc30> {
        max = 16,
        online = 1,
        sample = <table: 0x1c8dcfbbc00> {
            [1] = <table: 0x1c8dcfbbbd0> {
                name = "devcell",
                id = 579995,
                connectedAt = 1775734903,
            },
        },
    },
    type = "preview_response",
    tags = <table: 0x1c8dcfbbcc0> {
    },
    extra = <table: 0x1c8dcfbbc90> {
    },
    resolvedAddress = "147.185.221.31",
    latency = 351,
    map = "datamodel",
    version = 1,
    __preview = "kinemium_server_preview_v1",
    name = "Kinemium Server",
    features = <table: 0x1c8dcfbbc60> {
        requiresAuth = false,
        preview = true,
        includePlayers = true,
    },
    address = "0.0.0.0",
    timestamp = 1775734926,
    software = <table: 0x1c8dcfbbba0> {
        name = "Kinemium",
        preview = "kinemium_server_preview_v1",
        protocol = "kinetica_net_v2",
        transport = "KiNet/UDP",
    },
    requestId = "preview_1775734926_817415",
}
--]]

local itemSlots = {}

local group
group = aereon.create({
	frame = {
		comp = "frame",
		x = 0,
		y = 0,
		width = screenx,
		height = screeny,
		zindex = 1,
	},
	background = {
		comp = "frame",
		x = 0,
		y = 0,
		width = screenx,
		height = screeny,
		raylib_color = SecondaryBackgroundColorRaylib,
		zindex = 2,
		rounded = { 0, 10 },
	},
	title = {
		comp = "label",
		text = "Servers",
		x = 120,
		y = 120,
		font = vend,
		textColor = TextColor,
		backgroundColor = backgroundColor,
		zindex = 3,
	},

	-- addition
	addButton = {
		comp = "imageButton",
		image = addIcon,
		y = 110,
		x = screenx - 50,
		width = 30,
		height = 30,
		zindex = 3,

		onClick = function()
			group.newProjectPrompt.show()
		end,
	},

	newProjectPrompt = {
		comp = "prompt",
		visible = false,
		width = 600,
		height = 250,
		bodyHeight = 400,
		font = vend,
		backgroundColor = SecondaryBackgroundColor,
		title = "JOIN SERVER",
		buttons = {
			{
				text = "JOIN",
				color = Color3.new(0.368627, 0.368627, 0.368627),
				onClick = function()
					local username = usernameTextbox:getText()
					local server_address = serverAddress_Textbox:getText()
					local server_port = serverPort_Textbox:getText()

					if username == "" then
						return
					end

					local info, err = NetworkService:Ping(server_address, server_port)

					if info then
						local serverCardData = {
							x = 0,
							y = 0,
							width = 520,
							font = vend,

							onPlay = function()
								ProcessService.CreateKinemiumClientProcessEx(username, server_address, server_port)
							end,
						}
						for prop, value in pairs(info) do
							serverCardData[prop] = value
						end
						table.insert(itemSlots, gui.servercard(serverCardData))
					end
				end,
			},
		},
		bodyRenderer = function(dt, x, y, width, height)
			local iconRectSource = rect.new(0, 0, logoIcon.x, logoIcon.y)
			local iconRect = rect.new(x, y, 200, 200)

			local tint = raylib.const.WHITE
			if rect.MouseIsInRect(iconRect) then
				tint = transparent
				lib.SetMouseCursor(raylib.const.MouseCursor.MOUSE_CURSOR_POINTING_HAND)
			else
				lib.SetMouseCursor(raylib.const.MouseCursor.MOUSE_CURSOR_DEFAULT)
			end
			lib.DrawTexturePro(
				logoIcon.texture,
				rect:translate(iconRectSource),
				rect:translate(iconRect),
				vector.create(0, 0),
				0,
				tint
			)
			rect.Button(iconRect, function()
				local imagePath = FileDialogService.RequestFile({
					{ name = "Kinemium Project", extensions = { "kproj" } },
					{ name = "All Files", extensions = { "*" } },
				})
				logoIcon = KinemiumIconLoader.ToTexture(imagePath)
			end)

			lib.DrawTextEx(vend, "Username", vector.create(x + 210, y), 16, 1, raylib.const.WHITE)
			usernameTextbox:drawWithExtras(x + 210, y + 30, 300, 50)

			lib.DrawTextEx(vend, "Server Address", vector.create(x + 210, y + 100), 16, 1, raylib.const.WHITE)
			serverAddress_Textbox:drawWithExtras(x + 210, y + 130, 300, 50)

			lib.DrawTextEx(vend, "Server Port", vector.create(x + 210, y + 200), 16, 1, raylib.const.WHITE)
			serverPort_Textbox:drawWithExtras(x + 210, y + 230, 300, 50)
		end,
		zindex = 5,
	},
})

group.frame.setTransparency(1)

repeat
	task.wait()
until ishared.Home

table.insert(ishared.Home.rendering, {
	render = function(dt)
		if ishared.Home.activePage ~= "Join" then
			return
		end

		DiscordService.SetRPC({
			details = "Viewing Servers",
		})

		screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

		local x = 60
		local y = 60

		group.frame.set("obj_rect", arect.new(x, y, screenx, screeny))
		group.background.set("obj_rect", arect.new(x + 30, y + 30, screenx - 60, screeny - 60))
		group.addButton.set("obj_rect", arect.new(screenx - 50, 110, 30, 30))

		group.render(dt, { "newProjectPrompt" })

		-- render each card
		for i, card in ipairs(itemSlots) do
			local card_y = 150 + (i - 1) * 90
			card.set("obj_rect", arect.new(120, card_y, screenx - 135, 80))
			card.render(dt)
		end

		group.newProjectPrompt.render(dt)
	end,
})
