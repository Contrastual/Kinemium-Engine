-- devcell

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local KinemiumFontService = game:GetService("KinemiumFontService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local renderer = KinemiumRaylib.renderer
local const = KinemiumRaylib.const
local rl = KinemiumRaylib.lib
local Selection = game:GetService("Selection")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")
local structs = KinemiumRaylib.structs
local vend = KinemiumFontService.GetDefaultFont()
local StudioThemeService = game:GetService("StudioThemeService")
local arectlib = require("@Arect")(rl)
local scrollOffset = 0

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
local lastLogCount = 0

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

print("This is output.")

KinemiumIconLoader.new("Add", "./src/assets/images/icons/vanilla3/ui/16x/200/Add.png")

local png = KinemiumIconLoader.Get("Add")
local addIcon = KinemiumIconLoader.ToTexture(png)

local windowRegistry = {}

local aereon = import("@Aereon")
local window = aereon.window(game, nil, 1)

local blacklisted = {
	"Children",
}

local function create_window(title, frame)
	repeat
		task.wait()
	until frame.AbsolutePosition and frame.AbsoluteSize
	local myWindow = window.create({
		title = title,
		headerRender = false,
		x = frame.AbsolutePosition.X,
		y = frame.AbsolutePosition.Y,
		width = frame.AbsoluteSize.X,
		height = frame.AbsoluteSize.Y,
		tabs = {
			{
				name = "Output",
				render = function(windowData)
					local winX, winY = windowData.x, windowData.y + 30
					local winWidth, winHeight = windowData.width, windowData.height
					local cellHeight = 25
					local padding = 2

					local logs = LogService.GetLogHistory()
					local logCount = #logs

					if logCount ~= lastLogCount then
						lastLogCount = logCount

						local totalHeight = logCount * (cellHeight + padding)

						if totalHeight > winHeight then
							scrollOffset = totalHeight - winHeight
						else
							scrollOffset = 0
						end
					end

					for i, log in ipairs(logs) do
						local cellY = winY + (i - 1) * (cellHeight + padding) - scrollOffset
						local rect = arectlib.new(winX + 5, cellY, winWidth - 10, cellHeight)

						if cellY + cellHeight >= winY and cellY <= winY + winHeight then
							local logColor = TextColor
							if log.type == "print" then
								logColor = structs.Color:new({ r = 200, g = 200, b = 200, a = 255 })
							elseif log.type == "warn" then
								logColor = structs.Color:new({ r = 255, g = 200, b = 0, a = 255 })
							elseif log.type == "error" then
								logColor = structs.Color:new({ r = 255, g = 50, b = 50, a = 255 })
							end

							if not log then
								return
							end
							if not log.message then
								return
							end
							if not log.time then
								return
							end

							local ts = os.date("%H:%M:%S", log.time)
							local text = string.format("[%s] %s", ts, log.message)

							local col = StudioThemeService.SelectedTheme.Accent
							local transparency = 1

							rl.DrawTextEx(vend, text, vector.create(rect.x + 8, rect.y + 4), 17, 1, logColor)

							if arectlib.MouseIsInRect(rect) then
								transparency = 0
								rl.DrawLineEx(
									vector.create(rect.x, rect.y + cellHeight),
									vector.create(rect.x + rect.width, rect.y + cellHeight),
									1,
									col:ToRaylib(transparency)
								)
							end
						end
					end
				end,
			},
			{
				name = "Stack Trace",
				render = function(windowData)
					-- Tab 2 content
				end,
			},
			{
				name = "Debugger",
				render = function(windowData)
					-- Tab 2 content
				end,
			},
			{
				name = "Profiler",
				render = function(windowData)
					-- Tab 2 content
				end,
			},
		},
	})
	return myWindow
end

local function create_window_back(screenGui, title, AnchorPoint, size)
	local frame = Instance.new("Frame")
	frame.Position = UDim2.new(AnchorPoint.X, 0, AnchorPoint.Y, 0)
	frame.AnchorPoint = AnchorPoint
	frame.Size = size or UDim2.new(0, 400, 0.6, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui

	return create_window(title, frame), frame
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Console"
screenGui.Parent = LocalPlayer.PlayerGui

local propback, frame = create_window_back(
	screenGui,
	"Console",
	Vector2.new(0, 1),
	UDim2.new(0, KinemiumRaylib.lib.GetRenderWidth() - 400, 0.2, 0)
)

local windowObject

RunService.GuiRender:Connect(function()
	if not windowObject then
		return
	end
	renderer.Blur:DrawBlurredRegion(
		windowObject.x,
		windowObject.y,
		windowObject.width,
		windowObject.height,
		const.WHITE
	)
end)

window.stepped = function(windowData)
	if windowData.title == "Console" then
		windowObject = windowData

		window.dragspring:target(windowData, {
			x = frame.AbsolutePosition.X,
			y = frame.AbsolutePosition.Y,
			width = frame.AbsoluteSize.X,
			height = frame.AbsoluteSize.Y,
		})

		frame.Size = UDim2.new(0, KinemiumRaylib.lib.GetRenderWidth() - 400, 0.2, 0)
	end
end
