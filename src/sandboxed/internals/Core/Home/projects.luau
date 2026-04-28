local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local MouseCursor = require("@Kinemium.MouseCursor")
local lib = raylib.lib
local renderer = rlservice.GetRenderer()
local aereon = require("@Aereon")
local gui = aereon.gui
local rect = require("@Arect")
local transparent = Color3.new(1, 1, 1):ToRaylib(0.5)

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local ProjectLoaderService = game:GetService("ProjectLoaderService")
local FileDialogService = game:GetService("FileDialogService")
local ProjectSyncService = game:GetService("ProjectSyncService")
local project_prompt_active = false

local fs = Filesystem

local vend = KinemiumFontService.GetDefaultFont()
local boldFont = KinemiumFontService.GetBoldFont()
local arect = require("@arect")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

local defaultKinemiumIcon = "./src/assets/images/kinemium/KinemiumWhite.png"
local logoIcon = KinemiumIconLoader.ToTexture(defaultKinemiumIcon)

local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor
local ThirdBackgroundColor = StudioThemeService.SelectedTheme.ThirdBackgroundColor
local screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

KinemiumIconLoader.new("Add", "./src/assets/images/plus.png")

local addIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Add"))

local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)
local gameiconPath

local scrollY = 0

KinemiumIconLoader.new("Folder", "./src/assets/images/icons/Folder.png")
KinemiumIconLoader.new("Project", "./src/assets/images/icons/DataModel.png")
KinemiumIconLoader.new("Path", "./src/assets/images/icons/Attachment.png")

local folderIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Folder"))
local projectIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Project"))
local pathIcon = KinemiumIconLoader.ToTexture(KinemiumIconLoader.Get("Path"))

local logoPath = "./src/assets/images/kinemium/KinemiumWhite.png"

local projects = ProjectLoaderService.GetProjects() or {}

local itemSlots = {}
local generated_card_projects = {}
local base_y = 150

local function generateProjectCards()
	projects = ProjectLoaderService.GetProjects() or {}

	for _, projectData in pairs(projects) do
		-- if projectData.path already has a card, skip it
		if generated_card_projects[projectData.path] then
			continue
		end
		generated_card_projects[projectData.path] = true

		local icon

		if projectData.icon then
			icon = KinemiumIconLoader.ToTexture(projectData.icon)
		else
			icon = logoIcon
		end
		local stat = fs.stat(projectData.path)
		if stat.kind == "none" then
			continue
		end
		local card = gui.projectCard({
			comp = "projectCard",
			x = 0,
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
				if project_prompt_active then
					return
				end
				ishared.GameName = projectData.name
				ishared.FolderPath = projectData.path
				ishared.GameIcon = projectData.icon
				ishared.EnableHomescreen = false
				ProjectSyncService:StartSyncing(ishared.FolderPath)
				renderer:SetDimension("3D")
			end,
		})

		table.insert(itemSlots, card)

		base_y = base_y + 90 -- move down for next card
	end
end

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
	font = vend,
	selectedIndex = 2,

	onSelect = function(index, value)
		print("Selected:", index, value)
	end,
})

local group
group = aereon.create({

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
			project_prompt_active = true
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
		title = "Create New Project",
		onClose = function()
			project_prompt_active = false
		end,
		buttons = {
			{
				text = "Create Project",
				color = StudioThemeService.SelectedTheme.Accent,
				onClick = function()
					project_prompt_active = false
					local gnInput = gameNameInput:getText()
					local projInput = projectPath:getText()

					if gnInput == "" then
						return
					end

					if projInput == "" then
						fs.makeDir("./src/projects/" .. gnInput)
						projInput = "./src/projects/" .. gnInput
					end

					ishared.GameName = gnInput
					ishared.FolderPath = projInput
					ishared.GameIcon = gameiconPath
					ProjectLoaderService.NewProject(ishared.GameName, ishared.FolderPath, gameiconPath)
					ProjectSyncService:StartSyncing(ishared.FolderPath)
					ishared.EnableHomescreen = false
					renderer:SetDimension("3D")

					generateProjectCards()
				end,
			},
		},
		bodyRenderer = function(dt, x, y, width, height)
			-- Logo Container
			local logoBg = SecondaryBackgroundColor:ToRaylib(0.2)
			local logoSize = 180
			local logoX = x + 10
			local logoY = y + 10
			local logoRect = rect.new(logoX, logoY, logoSize, logoSize)

			-- Draw logo background
			raylib.lib.DrawRectangleRounded(rect:translate(logoRect), 0.1, 12, logoBg)

			local iconRectSource = rect.new(0, 0, logoIcon.x, logoIcon.y)
			local iconPadding = 20
			local iconDisplayRect = rect.new(
				logoX + iconPadding,
				logoY + iconPadding,
				logoSize - iconPadding * 2,
				logoSize - iconPadding * 2
			)

			local isLogoHovered = rect.MouseIsInRect(logoRect)
			local tint = isLogoHovered and transparent or raylib.const.WHITE

			lib.DrawTexturePro(
				logoIcon.texture,
				rect:translate(iconRectSource),
				rect:translate(iconDisplayRect),
				vector.create(0, 0),
				0,
				tint
			)

			if isLogoHovered then
				MouseCursor.request(raylib.const.MouseCursor.MOUSE_CURSOR_POINTING_HAND)
				lib.DrawTextEx(
					vend,
					"CHANGE ICON",
					vector.create(logoX + 45, logoY + logoSize / 2 - 8),
					14,
					1,
					raylib.const.WHITE
				)
			end

			rect.Button(logoRect, function()
				local imagePath = FileDialogService.RequestFile({
					{ name = "Images", extensions = { "png", "jpg", "jpeg", "bmp" } },
					{ name = "All Files", extensions = { "*" } },
				})
				if imagePath then
					logoIcon = KinemiumIconLoader.ToTexture(imagePath)
					gameiconPath = imagePath
				end
			end)

			-- Input Fields Section
			local inputX = x + logoSize + 40
			local inputW = width - logoSize - 50

			-- Game Name
			lib.DrawTexturePro(
				projectIcon.texture,
				rect.new(0, 0, projectIcon.x, projectIcon.y).rect,
				rect.new(inputX, y - 2, 20, 20).rect,
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
			lib.DrawTextEx(vend, "Game Name", vector.create(inputX + 28, y), 16, 1, raylib.const.WHITE)
			gameNameInput:drawWithExtras(inputX, y + 30, inputW, 45)

			-- Project Path
			lib.DrawTexturePro(
				folderIcon.texture,
				rect.new(0, 0, folderIcon.x, folderIcon.y).rect,
				rect.new(inputX, y + 98, 20, 20).rect,
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
			lib.DrawTextEx(vend, "Project Path", vector.create(inputX + 28, y + 100), 16, 1, raylib.const.WHITE)
			projectPath:drawWithExtras(inputX, y + 130, inputW - 40, 45)

			-- Path Explorer Button
			local explorerRect = rect.new(inputX + inputW - 30, y + 130, 30, 45)
			local isExplorerHovered = rect.MouseIsInRect(explorerRect)
			raylib.lib.DrawRectangleRounded(
				rect:translate(explorerRect),
				0.2,
				8,
				isExplorerHovered and StudioThemeService.SelectedTheme.Accent:ToRaylib(0.2)
					or SecondaryBackgroundColor:ToRaylib(0)
			)
			lib.DrawTexturePro(
				pathIcon.texture,
				rect.new(0, 0, 16, 16).rect,
				rect.new(explorerRect.x + 7, explorerRect.y + 14, 16, 16).rect,
				vector.create(0, 0),
				0,
				isExplorerHovered and raylib.const.WHITE or transparent
			)

			rect.Button(explorerRect, function()
				local projectPathStr = FileDialogService.RequestFolder({
					{ name = "Kinemium Project", extensions = { "kproj" } },
					{ name = "All Files", extensions = { "*" } },
				})
				if projectPathStr then
					projectPath:setText(projectPathStr)
				end
			end)

			-- Dimension
			lib.DrawTextEx(vend, "Dimension", vector.create(inputX, y + 200), 16, 1, raylib.const.WHITE)
			dimension.set("obj_rect", rect.new(inputX, y + 230, inputW, 40))
			dimension.render(dt)
		end,
		zindex = 5,
	},
})

repeat
	task.wait()
until ishared.Home

generateProjectCards()

ishared.Home.pages["Projects"] = function(dt, alpha, slideOffset)
	local fade = function(col, a)
		return col:ToRaylib(1 - (a or 1) * alpha)
	end

	if ishared.Home.activePage ~= "Projects" and ishared.Home.previousPage ~= "Projects" then
		return
	end

	screenx, screeny = lib.GetRenderWidth(), lib.GetScreenHeight()

	-- Handle scrolling
	local wheel = lib.GetMouseWheelMove()
	if wheel ~= 0 then
		scrollY = scrollY - wheel * 40
		if scrollY < 0 then
			scrollY = 0
		end
	end

	local startX = 100
	local headerY = 80 + slideOffset
	local headerDesc = 120 + slideOffset

	group.addButton.set("obj_rect", arect.new(screenx - 50, 110 + slideOffset, 30, 30))
	group.newProjectPrompt.set("obj_rect", arect.new(0, 0, 600, 250))
	group.render(dt, { "newProjectPrompt" })

	if vend then
		raylib.lib.DrawTextEx(
			boldFont,
			"Projects",
			vector.create(startX, headerY),
			42,
			1,
			fade(StudioThemeService.SelectedTheme.TextColor, 1)
		)
		raylib.lib.DrawTextEx(
			vend,
			"Manage and open your Kinemium Engine projects",
			vector.create(startX, headerY + 50),
			18,
			1,
			fade(StudioThemeService.SelectedTheme.SecondaryTextColor, 1)
		)
	end

	-- render each card
	local currentY = 170 - scrollY + slideOffset
	for i, card in ipairs(itemSlots) do
		card.set("obj_rect", arect.new(100, currentY, screenx - 115, 80))
		card.set("backgroundTransparency", 1 - alpha)
		card.render(dt)
		currentY = currentY + 90
	end

	local contentHeight = #itemSlots * 90 + 150
	local maxScroll = math.max(0, contentHeight - screeny + 100)
	if scrollY > maxScroll then
		scrollY = maxScroll
	end

	group.newProjectPrompt.render(dt)
end
