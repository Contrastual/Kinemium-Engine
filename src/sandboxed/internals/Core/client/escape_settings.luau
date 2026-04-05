repeat
	task.wait()
until ishared.EscapeMenu_Signal

local sign = ishared.EscapeMenu_Signal

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local ConfigService = game:GetService("ConfigService")

local vend = KinemiumFontService.GetDefaultFontSmall()

ConfigService.SetConfig({
	Controls = {
		CameraSensitivity = {
			Value = 1,
			Description = "Change camera sensitivity.",
		},
		FieldOfView = {
			Value = 70,
			Description = "Change camera FOV.",
		},
		CameraMode = {
			Value = "Classic",
			Description = "Change camera mode.",
		},
	},
	Graphics = {
		Quality = {
			Value = Enum.GraphicsLevel.Automatic,
			Description = "Change graphics quality.",
		},
		Shadows = {
			Value = true,
			Description = "Enable shadows.",
		},
		Bloom = {
			Value = true,
			Description = "Enable bloom.",
		},
		Vsync = {
			Value = true,
			Description = "Enable vsync.",
		},
		PostProcessing = {
			Value = true,
			Description = "Enable post processing.",
		},
	},
	Audio = {
		Volume = {
			Value = 0.5,
			Description = "Change audio volume.",
		},
		Music = {
			Value = true,
			Description = "Enable music.",
		},
		SoundEffects = {
			Value = true,
			Description = "Enable sound effects.",
		},
	},
	Misc = {
		Language = {
			Value = "English",
			Description = "Change game language.",
		},
		Fullscreen = {
			Value = false,
			Description = "Toggle fullscreen.",
		},
		DeveloperMode = {
			Value = false,
			Description = "Toggle developer mode.",
		},
	},
})

sign:Fire("MakeWindow", "Settings", function(window)
	window.ClipsDescendants = true

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
	ScrollingFrame.ClipsDescendants = true
	ScrollingFrame.BackgroundTransparency = 1
	ScrollingFrame.AutoScrollSize = false
	ScrollingFrame.Parent = window

	local cellList = Instance.new("UICellList")
	cellList.Parent = ScrollingFrame
	cellList.Size = UDim2.new(1, -20, 1, 0)
	cellList.Sections = {}

	for section, entries in pairs(ConfigService.GetConfig()) do
		local values = {}

		for propName, propData in pairs(entries) do
			table.insert(values, {
				name = propName,
				description = propData.Description,
				font = vend,
				backgroundColor = Color3.new(0, 0, 0),
				value = true,
			})
			ScrollingFrame.CanvasSize += 100
		end

		cellList.Sections[section] = values
	end
end)
