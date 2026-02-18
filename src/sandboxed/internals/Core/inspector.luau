-- devcell

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local KinemiumFontService = game:GetService("KinemiumFontService")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local renderer = KinemiumRaylib.renderer
local rl = KinemiumRaylib.lib
local Selection = game:GetService("Selection")
local structs = KinemiumRaylib.structs
local vend = KinemiumFontService.GetDefaultFont()
local overlapping = {}

local scrollOffset = 0
local maxScrollOffset = 0

local EngineSignal = game.EngineSignal

local StudioThemeService = game:GetService("StudioThemeService")

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

KinemiumIconLoader.new("Add", "./src/assets/images/icons/vanilla3/ui/16x/200/Add.png")

local png = KinemiumIconLoader.Get("Add")
local addIcon = KinemiumIconLoader.ToTexture(png)

local windowRegistry = {}

local aereon = require("@Aereon")
local gui = aereon.gui
local window = aereon.window(game)
local arect = aereon.rect()
local immediate = gui.immediate

local blacklisted = {
	"Children",
}

local function create_window(title, frame)
	repeat
		task.wait()
	until frame.AbsolutePosition and frame.AbsoluteSize
	local myWindow = window.create({
		title = title,
		x = frame.AbsolutePosition.X,
		y = frame.AbsolutePosition.Y,
		width = frame.AbsoluteSize.X,
		height = frame.AbsoluteSize.Y,
	})
	return myWindow
end

local function create_window_back(screenGui, title, AnchorPoint, size)
	local frame = Instance.new("Frame")
	frame.Position = UDim2.new(AnchorPoint.X, 0, AnchorPoint.Y, 0)
	frame.AnchorPoint = AnchorPoint
	frame.Size = size or UDim2.new(0, 400, 0.5, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui

	return create_window(title, frame), frame
end

-- create explorer ingame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Inspector"
screenGui.Parent = LocalPlayer.PlayerGui

local propback, frame = create_window_back(screenGui, "Inspector", Vector2.new(1, 1), UDim2.new(0, 400, 0.5, 0))

local windowObject
local comps = {}

RunService.GuiRender:Connect(function()
	if not windowObject then
		return
	end
	renderer.Blur:DrawBlurredRegion(
		windowObject.x,
		windowObject.y,
		windowObject.width,
		windowObject.height,
		Color3.new(1, 1, 1):ToRaylib(0)
	)
end)

local openProperties = {}
local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)

local datatypes = {
	string = {
		select = function(selected, propName, propValue)
			comps[propName] = textbox.new({
				padding = 5,
				onSubmit = function(new)
					if type(propValue) == "string" then
						selected[propName] = new
					elseif type(propValue) == "number" then
						selected[propName] = tonumber(new) or 0
					end
				end,
			})
			comps[propName]:setText(tostring(propValue))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local tbx = comps[propName]
			if tbx then
				tbx:drawWithExtras(pos.x, pos.y, rect.width / 2, cellHeight - 4)
			end
		end,
	},

	Vector2 = {
		select = function(selected, propName, propValue)
			comps[propName] = {
				x = textbox.new({
					padding = 5,
					numeric = true,
					numericStep = 1,

					TextColor = Color3.new(1, 0, 0):ToRaylib(0),
					onSubmit = function(new)
						local v = selected[propName]
						selected[propName] = Vector2.new(tonumber(new) or 0, v.Y)
					end,
				}),
				y = textbox.new({
					padding = 5,
					numeric = true,
					TextColor = Color3.new(0, 1, 0):ToRaylib(0),
					onSubmit = function(new)
						local v = selected[propName]
						selected[propName] = Vector2.new(v.X, tonumber(new) or 0)
					end,
				}),
			}

			comps[propName].x:setText(tostring(propValue.X))
			comps[propName].y:setText(tostring(propValue.Y))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local vec = comps[propName]
			if not vec then
				return
			end

			local totalWidth = rect.width / 2
			local spacing = 4
			local w = (totalWidth - spacing) / 2

			vec.x:drawWithExtras(pos.x, pos.y, w, cellHeight - 4)
			vec.y:drawWithExtras(pos.x + w + spacing, pos.y, w, cellHeight - 4)
		end,
	},

	UDim2 = {
		select = function(selected, propName, propValue)
			comps[propName] = {
				sx = textbox.new({
					padding = 5,
					numeric = true,
					TextColor = Color3.new(0.4, 1, 1):ToRaylib(0),
					onSubmit = function(new)
						print("udim2 changed!")
						local v = selected[propName]
						selected[propName] = UDim2.new(tonumber(new) or 0, v.X.Offset, v.Y.Scale, v.Y.Offset)
					end,
				}),
				ox = textbox.new({
					padding = 5,
					numeric = true,
					TextColor = Color3.new(1, 1, 1):ToRaylib(0),
					onSubmit = function(new)
						local v = selected[propName]
						selected[propName] = UDim2.new(v.X.Scale, tonumber(new) or 0, v.Y.Scale, v.Y.Offset)
					end,
				}),
				sy = textbox.new({
					padding = 5,
					numeric = true,
					TextColor = Color3.new(0.4, 1, 1):ToRaylib(0),
					onSubmit = function(new)
						local v = selected[propName]
						selected[propName] = UDim2.new(v.X.Scale, v.X.Offset, tonumber(new) or 0, v.Y.Offset)
					end,
				}),
				oy = textbox.new({
					padding = 5,
					numeric = true,
					TextColor = Color3.new(1, 1, 1):ToRaylib(0),
					onSubmit = function(new)
						local v = selected[propName]
						selected[propName] = UDim2.new(v.X.Scale, v.X.Offset, v.Y.Scale, tonumber(new) or 0)
					end,
				}),
			}

			comps[propName].sx:setText(tostring(propValue.X.Scale))
			comps[propName].ox:setText(tostring(propValue.X.Offset))
			comps[propName].sy:setText(tostring(propValue.Y.Scale))
			comps[propName].oy:setText(tostring(propValue.Y.Offset))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local u = comps[propName]
			if not u then
				return
			end

			local totalWidth = rect.width / 2
			local spacing = 4
			local half = (totalWidth - spacing) / 2
			local innerSpacing = 4
			local w = (half - innerSpacing) / 2

			u.sx:drawWithExtras(pos.x, pos.y, w, cellHeight - 4)
			u.ox:drawWithExtras(pos.x + w + innerSpacing, pos.y, w, cellHeight - 4)

			local xStart = pos.x + half + spacing
			u.sy:drawWithExtras(xStart, pos.y, w, cellHeight - 4)
			u.oy:drawWithExtras(xStart + w + innerSpacing, pos.y, w, cellHeight - 4)
		end,
	},

	Color3 = {
		select = function(selected, propName, propValue)
			comps[propName] = {
				r = textbox.new({
					padding = 5,
					numeric = true,
					numericMin = 0,
					numericMax = 1,
					numericStep = 1,
					TextColor = Color3.new(1, 0, 0):ToRaylib(0),

					onSubmit = function(new)
						local r, g, b = selected[propName]:ToRGB()
						selected[propName] = Color3.fromRGB(new, g, b)
					end,
				}),
				g = textbox.new({
					padding = 5,
					numeric = true,
					numericMin = 0,
					numericMax = 1,
					numericStep = 1,

					TextColor = Color3.new(0, 1, 0):ToRaylib(0),

					onSubmit = function(new)
						local r, g, b = selected[propName]:ToRGB()
						selected[propName] = Color3.fromRGB(r, new, b)
					end,
				}),
				b = textbox.new({
					padding = 5,
					numeric = true,
					numericMin = 0,
					numericStep = 1,
					numericMax = 1,
					TextColor = Color3.new(0, 0, 1):ToRaylib(0),

					onSubmit = function(new)
						local r, g, b = selected[propName]:ToRGB()
						selected[propName] = Color3.fromRGB(r, g, new)
					end,
				}),
			}

			local r, g, b = propValue:ToRGB()

			comps[propName].r:setText(tostring(r))
			comps[propName].g:setText(tostring(g))
			comps[propName].b:setText(tostring(b))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local c = comps[propName]
			if not c then
				return
			end

			local totalWidth = rect.width / 2
			local spacing = 4
			local w = (totalWidth - spacing * 2) / 3

			c.r:drawWithExtras(pos.x, pos.y, w, cellHeight - 4)
			c.g:drawWithExtras(pos.x + w + spacing, pos.y, w, cellHeight - 4)
			c.b:drawWithExtras(pos.x + (w + spacing) * 2, pos.y, w, cellHeight - 4)
		end,
	},

	number = {
		select = function(selected, propName, propValue)
			comps[propName] = textbox.new({
				padding = 5,

				numeric = true,
				numericMin = 0,
				numericMax = 100000,
				numericStep = 1,
				showStepButtons = true,

				onSubmit = function(new)
					print("number changed!")
					selected[propName] = tonumber(new or 0)
				end,
			})
			comps[propName]:setText(tostring(propValue))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local tbx = comps[propName]
			if tbx then
				tbx:drawWithExtras(pos.x, pos.y, rect.width / 2, cellHeight - 4)
			end
		end,
	},

	boolean = {
		select = function(selected, propName, propValue)
			comps[propName] = aereon.gui.checkbox({
				value = propValue,
				onChanged = function(new)
					selected[propName] = new
				end,
			})
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local dt = KinemiumRaylib.lib.GetFrameTime()
			local tbx = comps[propName]
			if tbx then
				tbx.set("obj_rect", arect.new(pos.x, pos.y, 25, 25))
				tbx.render(dt)
			end
		end,
	},

	EnumItem = {
		select = function(selected, propName, propValue)
			local itemNames = propValue.EnumType:GetItemsNames()
			local selected_index = 1

			for i, name in pairs(itemNames) do
				if name == propValue.Name then
					selected_index = i
					break
				end
			end

			local dp = gui.dropdown({
				options = propValue.EnumType:GetItemsNames(),
				font = vend,
				selectedIndex = selected_index,
				backgroundColor = StudioThemeService.SelectedTheme.SecondaryBackgroundColor,
				hoverColor = StudioThemeService.SelectedTheme.BackgroundColor,
				onSelect = function(i, option: string)
					selected[propName] = Enum[propValue.EnumType.Name][option]
				end,
			})
			overlapping[propName] = {
				render = function(selected, propName, propValue, pos, rect, cellHeight)
					local dt = KinemiumRaylib.lib.GetFrameTime()
					dp.set("obj_rect", arect.new(pos.x, pos.y, (rect.width / 2) - 10, cellHeight - 4))
					dp.render(dt)
				end,
			}
		end,
	},

	Vector3 = {
		select = function(selected, propName, propValue)
			comps[propName] = {
				x = textbox.new({
					padding = 5,
					onSubmit = function(new)
						print("changed")
						selected[propName] = Vector3.new(tonumber(new), selected[propName].Y, selected[propName].Z)
					end,
					TextColor = Color3.new(1, 0, 0):ToRaylib(0),
				}),
				y = textbox.new({
					padding = 5,
					onSubmit = function(new)
						print("changed")

						selected[propName] = Vector3.new(selected[propName].X, tonumber(new), selected[propName].Z)
					end,
					TextColor = Color3.new(0, 1, 0.266667):ToRaylib(0),
				}),
				z = textbox.new({
					padding = 5,
					onSubmit = function(new)
						print("changed")

						selected[propName] = Vector3.new(selected[propName].X, selected[propName].Y, tonumber(new))
					end,
					TextColor = Color3.new(0, 0, 1):ToRaylib(0),
				}),
			}
			comps[propName].x:setText(tostring(propValue.X))
			comps[propName].y:setText(tostring(propValue.Y))
			comps[propName].z:setText(tostring(propValue.Z))
		end,

		render = function(selected, propName, propValue, pos, rect, cellHeight)
			local vec = comps[propName]
			if vec then
				local totalWidth = rect.width / 2
				local spacing = 4
				local w = (totalWidth - spacing * 2) / 3

				vec.x:drawWithExtras(pos.x, pos.y, w, cellHeight - 4)
				vec.y:drawWithExtras(pos.x + w + spacing, pos.y, w, cellHeight - 4)
				vec.z:drawWithExtras(pos.x + (w + spacing) * 2, pos.y, w, cellHeight - 4)
			end
		end,
	},
}

Selection.SelectionAdded:Connect(function(selected)
	table.clear(comps)
	table.clear(overlapping)
	scrollOffset = 0

	for propName, propValue in pairs(selected._props) do
		if type(propValue) == "table" then
			if propValue._history then
				continue
			end
			local datatype = datatypes[propValue.__type]
			if datatype then
				datatype.select(selected, propName, propValue)
			end
		else
			local datatype = datatypes[type(propValue)]
			if datatype then
				datatype.select(selected, propName, propValue)
			end
		end
	end
end)

window.stepped = function(windowData)
	if windowData.title == "Inspector" then
		windowObject = windowData

		local winX, winY = windowData.x, windowData.y + 30
		local winWidth = windowData.width
		local winHeight = windowData.height - 30
		local cellHeight = 28
		local padding = 0
		local mousePos = rl.GetMousePosition()

		local mouseWheel = rl.GetMouseWheelMove()
		if mouseWheel ~= 0 then
			if
				mousePos.x >= winX
				and mousePos.x <= winX + winWidth
				and mousePos.y >= winY
				and mousePos.y <= winY + winHeight
			then
				scrollOffset = scrollOffset - mouseWheel * 40 -- 40 pixels per scroll notch
				scrollOffset = math.max(0, math.min(scrollOffset, maxScrollOffset))
			end
		end

		if rl.IsWindowResized() == 1 then
			window.dragspring:target(windowData, {
				x = frame.AbsolutePosition.X,
				y = frame.AbsolutePosition.Y,
				width = frame.AbsoluteSize.X,
				height = frame.AbsoluteSize.Y,
			})
		end

		local selected = Selection.Get()[1]

		if not selected then
			return
		end

		gui.clear()

		local propertyCount = 0
		for propName, propValue in pairs(selected._props) do
			if table.find(blacklisted, propName) then
				continue
			end
			if type(propValue) == "function" then
				continue
			end
			if type(propValue) == "table" then
				if propValue.__type == "KinemiumSignal" or propValue.__type == "KinemiumConnection" then
					continue
				end
				if propValue._history then
					continue
				end
			end
			if string.find(propName, "_") then
				continue
			end
			propertyCount = propertyCount + 1
		end
		local totalContentHeight = propertyCount * (cellHeight + padding)
		maxScrollOffset = math.max(0, totalContentHeight - winHeight)

		rl.BeginScissorMode(winX, winY, winWidth, winHeight)

		local i = 0

		for propName, propValue in pairs(selected._props) do
			if table.find(blacklisted, propName) then
				continue
			end
			if type(propValue) == "function" then
				continue
			end
			if type(propValue) == "table" then
				if propValue._history then
					continue
				end
			end
			if string.find(propName, "_") then
				continue
			end

			i += 1

			local cellY = winY + (i - 1) * (cellHeight + padding) - scrollOffset

			if cellY + cellHeight < winY or cellY > winY + winHeight then
				continue
			end

			local rect = { x = winX + 5, y = cellY, width = winWidth - 25, height = cellHeight }
			local pos = vector.create(rect.x + 200, rect.y + 4)

			local transparency = 1

			local col
			if i % 2 == 0 then
				col = Color3.new(0.15, 0.15, 0.15) -- dark gray
			else
				col = Color3.new(0.13, 0.13, 0.13) -- black
			end

			if
				mousePos.x >= rect.x
				and mousePos.x <= rect.x + rect.width
				and mousePos.y >= rect.y
				and mousePos.y <= rect.y + rect.height
			then
				col = Color3.new(0.25, 0.25, 0.25) -- lighter gray on hover
				transparency = 0.5
			end

			-- draw cell
			rl.DrawRectangleRounded(
				structs.Rectangle:new({
					x = rect.x,
					y = rect.y,
					width = rect.width,
					height = rect.height,
				}),
				0.2,
				6,
				col:ToRaylib(transparency)
			)

			-- draw property name
			rl.DrawTextEx(vend, propName, vector.create(rect.x + 8, rect.y + 4), 17, 1, TextColor)

			if type(propValue) == "table" then
				if propValue.__type ~= "EnumItem" then
					local datatype = datatypes[propValue.__type]
					if datatype then
						datatype.render(selected, propName, propValue, pos, rect, cellHeight)
					end
				end
			else
				local datatype = datatypes[type(propValue)]
				if datatype then
					datatype.render(selected, propName, propValue, pos, rect, cellHeight)
				end
			end

			for pN, gui in pairs(overlapping) do
				if pN == propName then
					gui.propName = propName
					gui.propValue = propValue
					gui.pos = pos
					gui.rect = rect
					gui.cellHeight = cellHeight
					overlapping[pN] = gui
				end
			end
		end

		rl.EndScissorMode()

		for pN, gui in pairs(overlapping) do
			if not gui.propName then
				continue
			end
			gui.render(selected, gui.propName, gui.propValue, gui.pos, gui.rect, cellHeight)
		end

		if maxScrollOffset > 0 then
			local scrollbarWidth = 8
			local scrollbarX = winX + winWidth - scrollbarWidth - 2
			local scrollbarHeight = winHeight
			local scrollbarThumbHeight = math.max(30, (winHeight / totalContentHeight) * scrollbarHeight)
			local scrollbarThumbY = winY + (scrollOffset / maxScrollOffset) * (scrollbarHeight - scrollbarThumbHeight)

			rl.DrawRectangle(scrollbarX, winY, scrollbarWidth, scrollbarHeight, Color3.new(0.1, 0.1, 0.1):ToRaylib(0.3))

			rl.DrawRectangleRounded(
				structs.Rectangle:new({
					x = scrollbarX,
					y = scrollbarThumbY,
					width = scrollbarWidth,
					height = scrollbarThumbHeight,
				}),
				0.5,
				6,
				Color3.new(1, 1, 1):ToRaylib(0.7)
			)
		end
	end
end
