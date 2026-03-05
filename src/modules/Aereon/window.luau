return function(raylib: typeof(require("@raylib").lib), structs, game, theme)
	local windowRegistry = {}
	local module = {}
	local draggedWindow = nil
	local dragOffset = { x = 0, y = 0 }
	local Color3 = require("@Color3")
	local Enum = require("@EnumMap")
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

	local function isMouseOverWindow(window, mousePos)
		return mousePos.x >= window.x
			and mousePos.x <= window.x + window.width
			and mousePos.y >= window.y
			and mousePos.y <= window.y + window.height
	end

	module.OutlineColor = Color3.new(0, 0.517647, 1)
	module.OutlineTransparency = 1
	module.dragged = function() end
	module.stepped = function() end
	module.dragEnd = function() end
	module.backgroundDrawed = function() end
	module.focused = function() end
	module.unfocused = function() end

	local anyWindowFocused = false

	local function isMouseInViewport(mousePos)
		local screenWidth = raylib.GetRenderWidth()
		local screenHeight = raylib.GetRenderHeight()
		local toolbarHeight = 160
		local viewportX = 0
		local viewportY = toolbarHeight
		local viewportWidth = screenWidth - 400
		local viewportHeight = screenHeight - toolbarHeight - screenHeight * 0.2

		return mousePos.x >= viewportX
			and mousePos.x <= viewportX + viewportWidth
			and mousePos.y >= viewportY
			and mousePos.y <= viewportY + viewportHeight
	end

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
			Focused = false,
			focused = function() end,
			unfocused = function() end,
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
		local mouseRightPressed = raylib.IsMouseButtonPressed(1)
		local mouseDown = raylib.IsMouseButtonDown(0)
		local mouseReleased = raylib.IsMouseButtonReleased(0)

		-- Find the topmost window the mouse is over
		local hoveredWindow = nil
		for i = #windowRegistry, 1, -1 do
			local window = windowRegistry[i]
			if not window.Closed and window.enabled and isMouseOverWindow(window, mousePos) then
				hoveredWindow = window
				break
			end
		end

		-- Handle right-click on window to halt 3D input
		if mouseRightPressed == 1 and hoveredWindow then
			game.Stop3DInput = true
			anyWindowFocused = true
		end

		-- Handle right-click on viewport to enable 3D input (for freecam)
		if mouseRightPressed == 1 and not hoveredWindow then
			if isMouseInViewport(mousePos) then
				game.Stop3DInput = false
				anyWindowFocused = false
				-- Unfocus all windows when right-clicking on viewport
				for _, window in pairs(windowRegistry) do
					if window.Focused then
						window.Focused = false
						window.unfocused(window)
						module.unfocused(window)
					end
				end
			end
		end

		if mousePressed == 1 then
			-- Focus/unfocus logic: find the topmost window the mouse is over
			local clickedWindow = hoveredWindow

			-- Track if any window gets focused this click
			local windowFocusedThisClick = false

			for _, window in pairs(windowRegistry) do
				if window.Closed or not window.enabled then
					continue
				end

				if window == clickedWindow then
					if not window.Focused then
						window.Focused = true
						window.focused(window)
						module.focused(window)
					end
					windowFocusedThisClick = true
				else
					if window.Focused then
						window.Focused = false
						window.unfocused(window)
						module.unfocused(window)
					end
				end
			end

			if windowFocusedThisClick then
				game.Stop3DInput = true
				anyWindowFocused = true
			else
				if isMouseInViewport(mousePos) then
					game.Stop3DInput = false
					anyWindowFocused = false
				end
			end
		end

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
		local shadowColor = shadowsEnabled and window_theme_config.ShadowColor:ToRaylib(0.9)
		local whiteOutline = Color3.new(1, 1, 1):ToRaylib(0.9)

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
				window_theme_config.BackgroundColor:ToRaylib(
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
					titleColor:ToRaylib(window_theme_config.TitleBackgroundTransparency)
				)

				raylib.DrawTextEx(
					vend,
					windowData.title,
					vector.create(wx + 8, wy + 6),
					window_theme_config.TitleTextSize,
					1,
					window_theme_config.TitleColor:ToRaylib(0)
				)

				windowData.titleRect = { height = 28, width = ww, x = wx, y = wy }
			end

			if windowData.IsDragging then
				raylib.DrawRectangleLines(
					wx,
					wy,
					ww,
					wh,
					window_theme_config.DragColor:ToRaylib(window_theme_config.DragOutlineTransparency)
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
