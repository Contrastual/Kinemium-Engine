local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local lib = raylib.lib
local renderer = rlservice.renderer
local aereon = require("@Aereon")
local gui = aereon.gui
local rect = require("@Arect")(lib)
local transparent = Color3.new(1, 1, 1):ToRaylib(0.5)

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local ProjectLoaderService = game:GetService("ProjectLoaderService")
local FileDialogService = game:GetService("FileDialogService")
local DiscordService = game:GetService("DiscordService")
local ProjectSyncService = game:GetService("ProjectSyncService")

local vend = KinemiumFontService.GetDefaultFontSmall()
local arect = require("@Arect")(raylib.lib)
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

local defaultKinemiumIcon = "./src/assets/images/icons/vanilla3/kinemium/KinemiumWhite.png"
local logoIcon = KinemiumIconLoader.ToTexture(defaultKinemiumIcon)

local backgroundColor = StudioThemeService.SelectedTheme.BackgroundColor
local TextColor = StudioThemeService.SelectedTheme.TextColor:ToRaylib(StudioThemeService.SelectedTheme.TextTransparency)

local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor
local ThirdBackgroundColor = StudioThemeService.SelectedTheme.ThirdBackgroundColor
local SecondaryBackgroundColorRaylib = StudioThemeService.SelectedTheme.SecondaryBackgroundColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryBackgroundColorTransparency
)
local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

KinemiumIconLoader.new("Add", "./src/assets/images/icons/vanilla3/ui/16x/200/Add.png")
local addIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Add"))

local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)
local gameiconPath

local gameNameInput = textbox.new({
	multiline = false,
	placeholder = "Enter..",
	fontSize = 16,
	font = vend,
	maxLength = 56,
})

local projectPath = textbox.new({
	multiline = false,
	placeholder = "Enter path...",
	fontSize = 16,
	font = vend,
	maxLength = 56,
})

local dimension = gui.dropdown({
	x = 0,
	y = 0,
	width = 200,
	height = 30,

	options = { "2D", "3D" },
	selectedIndex = 2,

	onSelect = function(index, value)
		print("Selected:", index, value)
	end,
})

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
		text = "Projects",
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
		title = "NEW PROJECT",
		buttons = {
			{
				text = "CREATE",
				color = Color3.new(0.368627, 0.368627, 0.368627),
				onClick = function()
					local gnInput = gameNameInput:getText()
					local projInput = projectPath:getText()

					if gnInput == "" then
						return
					end

					if projInput == "" then
						return
					end

					ishared.GameName = gnInput
					ishared.FolderPath = projInput
					ishared.GameIcon = gameiconPath
					ProjectLoaderService.NewProject(ishared.GameName, ishared.FolderPath, gameiconPath)
					ProjectSyncService:StartSyncing(ishared.FolderPath)
					ishared.EnableHomescreen = false
					renderer:SetDimension("3D")

					DiscordService.SetRPC({
						details = "Working on " .. ishared.GameName,
					})
				end,
			},
		},
		bodyRenderer = function(dt, x, y, width, height)
			local iconRectSource = rect.new(0, 0, logoIcon.x, logoIcon.y)
			local iconRect = rect.new(x, y, 200, 200)
			local fileExplorerRect = rect.new(x + 510, y + 130, 30, 30)

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
				gameiconPath = imagePath
			end)

			rect.Button(fileExplorerRect, function()
				local projectPathStr = FileDialogService.RequestFolder({
					{ name = "Kinemium Project", extensions = { "kproj" } },
					{ name = "All Files", extensions = { "*" } },
				})
				projectPath:setText(projectPathStr)
			end)

			lib.DrawTextEx(vend, "Game name", vector.create(x + 210, y), 16, 1, raylib.const.WHITE)
			gameNameInput:drawWithExtras(x + 210, y + 30, 300, 50)

			lib.DrawTextEx(vend, "Project path", vector.create(x + 210, y + 100), 16, 1, raylib.const.WHITE)
			projectPath:drawWithExtras(x + 210, y + 130, 300, 50)

			lib.DrawTextEx(vend, "Dimension", vector.create(x + 210, y + 200), 16, 1, raylib.const.WHITE)
			dimension.set("obj_rect", rect.new(x + 210, y + 230, 300, 40))
			dimension.render(dt)

			lib.DrawRectangleRec(rect:translate(fileExplorerRect), raylib.const.WHITE)
		end,
		zindex = 5,
	},
})

group.frame.setTransparency(1)

local logoPath = "./src/assets/images/icons/vanilla3/kinemium/KinemiumWhite.png"
local kilLogo = KinemiumIconLoader.ToTexture(logoPath)

local projects = ProjectLoaderService.GetProjects() or {}

local itemSlots = {}
local base_y = 150

for _, projectData in pairs(projects) do
	local icon

	if projectData.icon then
		icon = KinemiumIconLoader.ToTexture(projectData.icon)
	else
		icon = logoIcon
	end
	local card = gui.projectCard({
		comp = "projectCard",
		x = 120,
		y = base_y, -- use base_y for initial placement
		width = screenx - 135,
		title = projectData.name,
		subtext = "Edited on " .. os.date("%Y-%m-%d %H:%M:%S", projectData.last_opened),
		tags = { "son", "im crine" },
		backgroundColor = ThirdBackgroundColor,
		icon = icon,
		font = vend,
		zindex = 3,
		onClick = function()
			ishared.GameName = projectData.name
			ishared.FolderPath = projectData.path
			ishared.GameIcon = projectData.icon
			ishared.EnableHomescreen = false
			ProjectSyncService:StartSyncing(ishared.FolderPath)
			renderer:SetDimension("3D")

			DiscordService.SetRPC({
				details = "Working on " .. ishared.GameName,
			})
		end,
	})

	table.insert(itemSlots, card)

	base_y = base_y + 90 -- move down for next card
end

repeat
	task.wait()
until ishared.Home

table.insert(ishared.Home.rendering, {
	render = function(dt)
		if ishared.Home.activePage ~= "Projects" then
			return
		end

		DiscordService.SetRPC({
			details = "Viewing Projects",
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
