local Instance = require("@Instance")
local Color3 = require("@Color3")

local StudioThemeService = Instance.new("StudioThemeService")
StudioThemeService.ExplorerHidden = true

StudioThemeService.InitRenderer = function(renderer, renderer_signal, datamodel)
	local themes = {
		dark = {
			TextColor = Color3.new(1, 1, 1),
			ImageColor = Color3.new(1, 1, 1),
			ImageTransparency = 0,
			GuiHandlesColor = Color3.new(0, 0, 1),
			GuiHandlesTransparency = 0,
			TextTransparency = 0,
			BackgroundColor = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.2,
			SecondaryTextTransparency = 0,
			SecondaryTextColor = Color3.new(0.541176, 0.541176, 0.541176),
			SecondaryBackgroundColor = Color3.new(0.03, 0.03, 0.03),
			SecondaryBackgroundColorTransparency = 0,
			Accent = Color3.new(0.02, 0.5, 1),
			AccentTransparency = 0,
			WindowBackgroundColor = Color3.new(0, 0, 0),
			WindowBackgroundTransparency = 0.05,
			TitleTextSize = 16,
			WindowTitleHeight = 29,
			ShadowsEnabled = true,
			ShadowTransparency = 0.98,
			CornerRadius = 5,
			ShadowColor = Color3.new(0, 0, 0),
			ArrowImageColor = Color3.new(1, 1, 1),
			TitleColor = Color3.new(1, 1, 1),

			aereon = {
				window = {
					BackgroundColor = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.05,
					TextColor = Color3.new(1, 1, 1),
					SecondaryBackgroundColor = Color3.new(0.05, 0.05, 0.05),
					DragColor = Color3.new(0.02, 0.5, 1),
					DragOutlineTransparency = 0,
					TitleBackgroundTransparency = 0,
					TitleTextSize = 16,
					TitleColor = Color3.new(1, 1, 1),
					TitleHeight = 29,
					ShadowsEnabled = true,
					ShadowTransparency = 0.98,
					ShadowColor = Color3.new(0, 0, 0),
				},

				ide = {
					BackgroundColor = Color3.new(0.05, 0.05, 0.05),
					SecondaryBackgroundColor = Color3.new(0.07, 0.07, 0.07),
					TextColor = Color3.new(1, 1, 1),
					currentLineColor = Color3.new(0.2, 0.2, 0.2),

					autocomplete = {
						BackgroundColor = Color3.new(0.07, 0.07, 0.07),
						OutlineColor = Color3.new(1, 1, 1),
						ItemSelectColor = Color3.new(0, 0, 0.3),
						OutlineThickness = 0.6,
						OutlineTransparency = 0.8,
						CornerRadius = 0.2,

						Width = 200,
						Height = 20,
						ListPadding = 5,
					},
				},
			},
		},
	}

	themes.dark.aereon.window.BackgroundColor = themes.dark.WindowBackgroundColor
	themes.dark.aereon.window.BackgroundTransparency = themes.dark.WindowBackgroundTransparency
	themes.dark.aereon.window.TextColor = themes.dark.TextColor
	themes.dark.aereon.window.SecondaryBackgroundColor = themes.dark.SecondaryBackgroundColor
	themes.dark.aereon.window.DragColor = themes.dark.Accent
	themes.dark.aereon.window.DragOutlineTransparency = themes.dark.AccentTransparency
	themes.dark.aereon.window.TitleBackgroundTransparency = themes.dark.SecondaryBackgroundColorTransparency
	themes.dark.aereon.window.TitleTextSize = themes.dark.TitleTextSize
	themes.dark.aereon.window.TitleColor = themes.dark.TitleColor
	themes.dark.aereon.window.TitleHeight = themes.dark.WindowTitleHeight
	themes.dark.aereon.window.ShadowsEnabled = themes.dark.ShadowsEnabled
	themes.dark.aereon.window.ShadowTransparency = themes.dark.ShadowTransparency
	themes.dark.aereon.window.ShadowColor = themes.dark.ShadowColor

	StudioThemeService:SetProperties({
		themes = themes,
		SelectedTheme = themes.dark,
	})
end

return StudioThemeService
