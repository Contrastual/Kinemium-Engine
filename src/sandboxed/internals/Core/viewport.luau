-- devcell

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local EngineSignal = game.EngineSignal
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local renderer = KinemiumRaylib.renderer
local rl = KinemiumRaylib.lib
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

if FlagExists("client") then
	return
end

if FlagExists("cli") then
	return
end

if FlagExists("headless") then
	return
end

local aereon = import("@Aereon")
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
			ide:openTab(Script.Name, Script.Source)

			enableIDE = true
			currentObject = Script
			game.Stop3DInput = true
		else
			enableIDE = false
			currentObject = nil

			game.Stop3DInput = false
		end
	end
end)

local window = aereon.window(game)

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
	title = "Script Editor",
	x = x,
	y = y,
	width = width,
	height = height,
	enabled = false,
})

--[[
local viewportWindow = window.create({
	title = "Viewport",
	x = x,
	y = y,
	width = width,
	height = height,
	backgroundTransparency = 1,
	enabled = false,
})
--]]

ideWindow.stepped = function(data)
	ide.draw(ideWindow.x, ideWindow.y + 30, vector.create(ideWindow.width, ideWindow.height), 50)

	if currentObject then
		if currentObject.IsOverridden then
			ide.text:clear()
			ide.text:insertString(currentObject.Source)
			ide.text:setCursor(1, 1)
			ide._highlightCache = {}
			return
		end
		currentObject.Source = ide:getCode()
	end
end

local viewport_x, viewport_y, viewport_width, viewport_height = 0, 0, 0, 0

renderer.Pool.new("2d", function(data)
	if game.Context ~= Enum.GameContext.Editor then
		return
	end

	local dt = rl.GetFrameTime()
	local mainTheme = StudioThemeService.SelectedTheme

	ideWindow.enabled = enableIDE

	aereon.step(dt, mainTheme.aereon)
end)

--[[
viewportWindow.stepped = function(data)
	viewport_x = data.x
	viewport_y = data.y + 30
	viewport_width = data.width
	viewport_height = data.height - 30
end
--]]
