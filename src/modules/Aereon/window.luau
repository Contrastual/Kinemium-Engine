return function(raylib: typeof(require("@raylib").lib), structs, game, theme)
	local windowRegistry = {}
	local module = {}
	local draggedWindow = nil
	local dragOffset = { x = 0, y = 0 }
	local Color3 = require("@Color3")
	local Enum = require("@EnumMap")
	local const = require("@raylib").const
	local spring = require("@kispring")
	local KinemiumFontService = game:GetService("KinemiumFontService")

	local resizingWindow = nil
	local resizeSide = nil
	local resizeStart = vector.create(0, 0)
	local resizeMinSize = vector.create(100, 60)
	local resizeThreshold = 15
	local dragSpring = spring.new(1, 5)
	local vend = KinemiumFontService.GetDefaultFont()

	local shadowTexture, shadowSize
	if _G.IsHeadless then
		shadowTexture = buffer.create(16)
		shadowSize = vector.create(0, 0)
	else
		shadowTexture = raylib.LoadTexture("./src/assets/images/shadow.png")
		shadowSize = vector.create(buffer.readi32(shadowTexture, 4), buffer.readi32(shadowTexture, 8))
	end

	local function Color3ToRaylib(c, transparency)
		local r, g, b = c:ToRGB()
		return structs.Color:new({
			r = r,
			g = g,
			b = b,
			a = math.floor(255 * (1 - transparency)),
		})
	end

	local function getResizeSide(window, mousePos)
		local sides = {}
		local wx, wy, ww, wh = window.x, window.y, window.width, window.height

		if math.abs(mousePos.x - wx) <= resizeThreshold then
			table.insert(sides, "left")
		elseif math.abs(mousePos.x - (wx + ww)) <= resizeThreshold then
			table.insert(sides, "right")
		end

		if math.abs(mousePos.y - wy) <= resizeThreshold then
			table.insert(sides, "top")
		elseif math.abs(mousePos.y - (wy + wh)) <= resizeThreshold then
			table.insert(sides, "bottom")
		end

		return #sides > 0 and sides or nil
	end

	local function setCursorForResize(sides)
		if not sides then
			raylib.SetMouseCursor(Enum.KinemiumMouseCursor.MOUSE_CURSOR_DEFAULT.Value)
			return
		end

		local hasHorizontal = false
		local hasVertical = false

		for _, side in ipairs(sides) do
			if side == "left" or side == "right" then
				hasHorizontal = true
			elseif side == "top" or side == "bottom" then
				hasVertical = true
			end
		end

		if hasHorizontal then
			raylib.SetMouseCursor(Enum.KinemiumMouseCursor.MOUSE_CURSOR_RESIZE_EW.Value)
		elseif hasVertical then
			raylib.SetMouseCursor(Enum.KinemiumMouseCursor.MOUSE_CURSOR_RESIZE_NS.Value)
		end
	end

	module.OutlineColor = Color3.new(0, 0.517647, 1)
	module.OutlineTransparency = 1
	module.dragged = function() end
	module.stepped = function() end
	module.dragEnd = function() end
	module.backgroundDrawed = function() end

	function module.create(data: {
		headerRender: boolean?,
		step: () -> (),
		title: string,
		x: number,
		y: number,
		width: number,
		DisableClipping: boolean?,
		height: number,
		enabled: boolean?,
	})
		local window = {
			title = data.title,
			x = data.x,
			y = data.y,
			width = data.width,
			headerRender = data.headerRender,
			height = data.height,
			id = #windowRegistry + 1,
			DisableClipping = data.DisableClipping,
			rounded = 0,
			stepped = data.step,
			enabled = data.enabled or true,
			scrollOffset = vector.create(0, 0),
		}
		table.insert(windowRegistry, window)

		function window:MoveTo(x, y)
			window.x = x
			window.y = y
		end

		function window:Resize(x, y)
			window.width = x
			window.height = y
		end

		return window
	end

	function module.update(dt, theme)
		local mousePos = raylib.GetMousePosition()
		local mousePressed = raylib.IsMouseButtonPressed(0)
		local mouseDown = raylib.IsMouseButtonDown(0)
		local mouseReleased = raylib.IsMouseButtonReleased(0)

		if mousePressed == 1 and not draggedWindow and not resizingWindow then
			for i = #windowRegistry, 1, -1 do
				local window = windowRegistry[i]
				local wx, wy, ww = window.x, window.y, window.width
				local titleBarHeight = 24

				if
					mousePos.x >= wx
					and mousePos.x <= wx + ww
					and mousePos.y >= wy
					and mousePos.y <= wy + titleBarHeight
				then
					draggedWindow = window
					dragOffset.x = mousePos.x - wx
					dragOffset.y = mousePos.y - wy

					table.remove(windowRegistry, i)
					table.insert(windowRegistry, window)
					break
				end
			end

			if not draggedWindow then
				for i = #windowRegistry, 1, -1 do
					local window = windowRegistry[i]
					local sides = getResizeSide(window, mousePos)
					if sides then
						resizingWindow = window
						resizeSide = sides
						resizeStart = vector.create(mousePos.x, mousePos.y)
						break
					end
				end
			end
		end

		if mouseDown == 1 then
			if draggedWindow then
				raylib.SetMouseCursor(Enum.KinemiumMouseCursor.MOUSE_CURSOR_RESIZE_ALL.Value)

				draggedWindow.x = mousePos.x - dragOffset.x
				draggedWindow.y = mousePos.y - dragOffset.y

				draggedWindow.IsDragging = true
				module.dragged(draggedWindow)
			elseif resizingWindow then
				local dx = mousePos.x - resizeStart.x
				local dy = mousePos.y - resizeStart.y

				for _, side in ipairs(resizeSide) do
					if side == "left" then
						resizingWindow.x = resizingWindow.x + dx
						resizingWindow.width = resizingWindow.width - dx
					elseif side == "right" then
						resizingWindow.width = resizingWindow.width + dx
					elseif side == "top" then
						resizingWindow.y = resizingWindow.y + dy
						resizingWindow.height = resizingWindow.height - dy
					elseif side == "bottom" then
						resizingWindow.height = resizingWindow.height + dy
					end
				end

				resizingWindow.width = math.max(resizingWindow.width, resizeMinSize.x)
				resizingWindow.height = math.max(resizingWindow.height, resizeMinSize.y)

				setCursorForResize(resizeSide)
				resizeStart = vector.create(mousePos.x, mousePos.y)
			end
		end

		if mouseReleased == 1 then
			raylib.SetMouseCursor(Enum.KinemiumMouseCursor.MOUSE_CURSOR_DEFAULT.Value)

			if draggedWindow then
				draggedWindow.IsDragging = false
				module.dragEnd(draggedWindow)
			end

			draggedWindow = nil
			resizingWindow = nil
			resizeSide = nil
		end
	end

	function module.draw(dt, selectedTheme)
		dragSpring:step(dt)

		local window_theme_config = selectedTheme.window
		local shadowsEnabled = window_theme_config.ShadowsEnabled
		local shadowColor = shadowsEnabled and Color3ToRaylib(window_theme_config.ShadowColor, 0.9)
		local whiteOutline = Color3ToRaylib(Color3.new(1, 1, 1), 0.9)

		for _, windowData in pairs(windowRegistry) do
			if windowData.Closed or not windowData.enabled then
				continue
			end

			local wx, wy, ww, wh = windowData.x, windowData.y, windowData.width, windowData.height

			if shadowsEnabled then
				local shadowOffset = 6
				raylib.DrawTexturePro(
					shadowTexture,
					structs.Rectangle:new({ x = 0, y = 0, width = shadowSize.x, height = shadowSize.y }),
					structs.Rectangle:new({
						x = wx - shadowOffset * 15,
						y = wy - shadowOffset * 15,
						width = ww + shadowOffset * 30,
						height = wh + shadowOffset * 30,
					}),
					vector.create(0, 0),
					0,
					shadowColor
				)
			end

			local mainRect = structs.Rectangle:new({ x = wx, y = wy, width = ww, height = wh })

			raylib.DrawRectangleRounded(
				mainRect,
				windowData.rounded,
				30,
				Color3ToRaylib(
					window_theme_config.BackgroundColor,
					windowData.transparency or window_theme_config.BackgroundTransparency
				)
			)

			module.backgroundDrawed(windowData)

			raylib.DrawRectangleRoundedLinesEx(mainRect, windowData.rounded, 30, 1, whiteOutline)

			if windowData.headerRender ~= false then
				local titleColor = windowData.IsDragging and window_theme_config.DragColor
					or window_theme_config.SecondaryBackgroundColor

				raylib.DrawRectangleRec(
					structs.Rectangle:new({ x = wx, y = wy, width = ww, height = 28 }),
					Color3ToRaylib(titleColor, window_theme_config.TitleBackgroundTransparency)
				)

				raylib.DrawTextEx(
					vend,
					windowData.title,
					vector.create(wx + 8, wy + 6),
					window_theme_config.TitleTextSize,
					1,
					Color3ToRaylib(window_theme_config.TitleColor, 0)
				)

				windowData.titleRect = { height = 28, width = ww, x = wx, y = wy }
			end

			if windowData.IsDragging then
				raylib.DrawRectangleLines(
					wx,
					wy,
					ww,
					wh,
					Color3ToRaylib(window_theme_config.DragColor, window_theme_config.DragOutlineTransparency)
				)
			end

			if not windowData.DisableClipping then
				raylib.BeginScissorMode(wx, wy, ww, wh)
			end

			module.stepped(windowData, dt)

			if not windowData.DisableClipping then
				raylib.EndScissorMode()
			end

			if windowData.stepped then
				windowData.stepped(windowData, dt)
			end
		end
	end

	module.dragspring = dragSpring

	return module
end
