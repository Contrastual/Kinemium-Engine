-- devcell

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local DiscordRPC = game:GetService("DiscordRPC")
local EngineSignal = game.EngineSignal
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local renderer = KinemiumRaylib.renderer
local rl = KinemiumRaylib.lib
local structs = KinemiumRaylib.structs
local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")

local vend = KinemiumFontService.GetDefaultFont()

local backgroundColor =
	StudioThemeService.SelectedTheme.BackgroundColor:ToRaylib(StudioThemeService.SelectedTheme.BackgroundTransparency)
local TextColor = StudioThemeService.SelectedTheme.TextColor:ToRaylib(StudioThemeService.SelectedTheme.TextTransparency)
local GuiHandlesColor =
	StudioThemeService.SelectedTheme.GuiHandlesColor:ToRaylib(StudioThemeService.SelectedTheme.GuiHandlesTransparency)
local SecondaryBackgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryBackgroundColorTransparency
)
local SecondaryTextColor = StudioThemeService.SelectedTheme.SecondaryTextColor:ToRaylib(
	StudioThemeService.SelectedTheme.SecondaryTextTransparency
)
local ImageColor =
	StudioThemeService.SelectedTheme.ImageColor:ToRaylib(StudioThemeService.SelectedTheme.ImageTransparency)

if game.Context ~= Enum.GameContext.Editor then
	return
end

if FlagExists("client") then
	return
end

if FlagExists("cli") then
	return
end

if FlagExists("headless") then
	return
end

local aereon = import("@Kinemium.Aereon")
local gui = aereon.gui
local ide = aereon.ide(nil, game)

gui.SetFont(vend)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Output"
screenGui.Parent = LocalPlayer.PlayerGui

local enableIDE = false
local currentObject

EngineSignal:Connect(function(route, value, Script)
	if route == "idestate" then
		if value == true then
			--KinemiumIDE.Open()
			ide.text:clear()
			ide.text:insertString(Script.Source)
			enableIDE = true
			currentObject = Script
			DiscordRPC.ChangeDetail(`Editing {Script.Name}`)

			game.Stop3DInput = true
		else
			enableIDE = false
			currentObject = nil
			DiscordRPC.ChangeDetail(`idle..`)

			game.Stop3DInput = false
		end
	end
end)

local window = aereon.window(game, mainTheme, 1)

local function calculate()
	local screenWidth = rl.GetMonitorWidth(0)
	local screenHeight = rl.GetMonitorHeight(0)
	local toolbarHeight = 160
	local viewportX = 0
	local viewportY = toolbarHeight
	local viewportWidth = screenWidth - 400
	local viewportHeight = screenHeight - toolbarHeight - screenHeight * 0.2
	return viewportX, viewportY, viewportWidth, viewportHeight
end

local x, y, width, height = calculate()

local ideWindow = window.create({
	title = "Kinemium IDE",
	x = x,
	y = y,
	width = width,
	height = height,
	enabled = false,
})

ideWindow.stepped = function(data)
	data.enabled = enableIDE
	if enableIDE then
		ide.draw(ideWindow.x, ideWindow.y + 30, vector.create(ideWindow.width, ideWindow.height), 50)

		if currentObject then
			currentObject.Source = ide:getCode()
		end
	end
end

renderer.Add2DStack(function(data)
	local dt = rl.GetFrameTime()
	local mainTheme = StudioThemeService.SelectedTheme

	aereon.step(dt, mainTheme.aereon)
end)
