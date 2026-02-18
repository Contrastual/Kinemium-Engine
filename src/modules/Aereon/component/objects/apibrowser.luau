local raylib = require("@raylib")
local structs = raylib.structs

local function c3tr(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

local rect = require("@arect")(raylib.lib)
local color3 = require("@Color3")

return function(objects, data)
	local config = {
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4]),
		rounded = data.rounded or { 0.08, 10 },
		modifiers = {},

		-- Colors
		backgroundColor = color3.new(0.08, 0.09, 0.10),
		panelColor = color3.new(0.11, 0.12, 0.13),
		headerColor = color3.new(0.09, 0.10, 0.11),
		itemColor = color3.new(0.13, 0.14, 0.15),
		hoverColor = color3.new(0.17, 0.18, 0.20),
		selectedColor = color3.new(0.22, 0.40, 0.60),
		textColor = color3.new(0.92, 0.93, 0.95),
		subtextColor = color3.new(0.58, 0.60, 0.62),
		accentColor = color3.new(0.35, 0.70, 1.0),
		dividerColor = color3.new(0.16, 0.17, 0.18),
		scrollbarColor = color3.new(0.28, 0.30, 0.32),
		scrollbarHoverColor = color3.new(0.35, 0.37, 0.40),
		borderColor = color3.new(0.20, 0.21, 0.23),
		shadowColor = color3.new(0, 0, 0),

		-- Layout
		headerHeight = 46,
		itemHeight = 30,
		padding = 14,
		spacing = 4,
		indentSize = 18,
		iconSize = 14,
		searchHeight = 36,

		-- Panel widths
		leftPanelWidth = 350,
		middlePanelWidth = 350,

		-- Font
		font = data.font,
		fontSize = data.fontSize or 14,
		fontSpacing = 0.5,
		headerFontSize = 17,
		headerFontSpacing = 0.8,

		-- Data structure
		categories = data.categories or {
			{
				name = "Classes",
				count = 858,
				expanded = true,
				items = {
					{
						name = "Object",
						type = "class",
						expanded = false,
						children = {
							{ name = "AnimationNode", type = "class" },
							{
								name = "Capture",
								type = "class",
								expanded = false,
								children = {
									{ name = "ScreenshotCapture", type = "class" },
									{ name = "VideoCapture", type = "class" },
								},
							},
							{ name = "ConfigSnapshot", type = "class" },
						},
					},
					{
						name = "Instance",
						type = "class",
						expanded = false,
						children = {
							{ name = "Accessory", type = "class" },
							{ name = "Animation", type = "class" },
						},
					},
				},
			},
			{
				name = "Enums",
				count = 545,
				expanded = false,
				items = {
					{ name = "AccessModifierType", type = "enum" },
					{ name = "AccessoryType", type = "enum" },
					{ name = "ActionType", type = "enum" },
				},
			},
			{
				name = "Types",
				count = 69,
				expanded = false,
				items = {
					{ name = "DataType", type = "type" },
					{ name = "BinaryString", type = "type" },
					{ name = "Color3", type = "type" },
				},
			},
		},

		middleItems = {},
		middleScrollOffset = 0,
		middleSearch = "",

		selectedItem = nil,
		rightScrollOffset = 0,

		-- Interaction
		leftScrollOffset = 0,
		selectedCategoryIndex = 1,
		hoveredItem = nil,
		searchFocused = false,

		-- Animation states
		hoverStates = {},
		expandAnimations = {},
		scrollbarAlpha = {},

		onItemSelect = data.onItemSelect,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	local function drawText(text, x, y, fontSize, spacing, color)
		if config.font then
			raylib.lib.DrawTextEx(config.font, text, vector.create(x, y), fontSize, spacing, c3tr(color, 0))
		else
			raylib.lib.DrawText(text, x, y, fontSize, c3tr(color, 0))
		end
	end

	local function measureText(text, fontSize, spacing)
		if config.font then
			local textSize = raylib.lib.MeasureTextEx(config.font, text, fontSize, spacing)
			return textSize.x
		else
			return raylib.lib.MeasureText(text, fontSize)
		end
	end

	local function getHoverState(key, dt, isHovered)
		if not config.hoverStates[key] then
			config.hoverStates[key] = 0
		end

		if isHovered then
			config.hoverStates[key] = math.min(config.hoverStates[key] + dt * 10, 1)
		else
			config.hoverStates[key] = math.max(config.hoverStates[key] - dt * 10, 0)
		end

		return config.hoverStates[key]
	end

	local function drawIcon(x, y, size, iconType, color)
		local centerX = x + size / 2
		local centerY = y + size / 2
		local thickness = 1.5

		if iconType == "class" then
			-- Filled circle with border
			raylib.lib.DrawCircle(centerX, centerY, size / 3, c3tr(color, 0))
			raylib.lib.DrawCircleLines(centerX, centerY, size / 3, c3tr(color, 0.3))
		elseif iconType == "enum" then
			-- Filled square with border
			raylib.lib.DrawRectangle(centerX - size / 3, centerY - size / 3, size * 2 / 3, size * 2 / 3, c3tr(color, 0))
			raylib.lib.DrawRectangleLines(
				centerX - size / 3,
				centerY - size / 3,
				size * 2 / 3,
				size * 2 / 3,
				c3tr(color, 0.3)
			)
		elseif iconType == "type" then
			-- Diamond shape
			raylib.lib.DrawTriangle(
				vector.create(centerX, centerY - size / 3),
				vector.create(centerX + size / 3, centerY),
				vector.create(centerX, centerY + size / 3),
				c3tr(color, 0)
			)
			raylib.lib.DrawTriangle(
				vector.create(centerX, centerY - size / 3),
				vector.create(centerX - size / 3, centerY),
				vector.create(centerX, centerY + size / 3),
				c3tr(color, 0)
			)
		elseif iconType == "expanded" then
			-- Down chevron
			raylib.lib.DrawTriangle(
				vector.create(centerX - size / 3, centerY - size / 6),
				vector.create(centerX + size / 3, centerY - size / 6),
				vector.create(centerX, centerY + size / 4),
				c3tr(color, 0)
			)
		elseif iconType == "collapsed" then
			-- Right chevron
			raylib.lib.DrawTriangle(
				vector.create(centerX - size / 5, centerY - size / 3),
				vector.create(centerX + size / 4, centerY),
				vector.create(centerX - size / 5, centerY + size / 3),
				c3tr(color, 0)
			)
		end
	end

	local function drawTreeItem(item, x, y, width, indent, mousePos, mousePressed, dt)
		local itemKey = tostring(item) .. "_" .. x .. "_" .. y
		local itemRect = rect.new(x, y, width, config.itemHeight)
		local isHovered = rect.MouseIsInRect(itemRect)
		local hoverAlpha = getHoverState(itemKey, dt, isHovered)
		local isSelected = config.selectedItem == item

		-- Background with rounded corners and smooth hover
		if isSelected then
			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(x + 2, y + 1, width - 4, config.itemHeight - 2)),
				0.15,
				6,
				c3tr(config.selectedColor, 0)
			)
		elseif hoverAlpha > 0 then
			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(x + 2, y + 1, width - 4, config.itemHeight - 2)),
				0.15,
				6,
				c3tr(config.hoverColor, 1 - hoverAlpha * 0.3)
			)
		end

		-- Expand/collapse arrow
		if item.children and #item.children > 0 then
			local arrowX = x + indent
			local arrowY = y + config.itemHeight / 2 - config.iconSize / 2
			drawIcon(arrowX, arrowY, config.iconSize, item.expanded and "expanded" or "collapsed", config.subtextColor)

			if isHovered and mousePressed and mousePos.x < x + indent + config.iconSize + 4 then
				item.expanded = not item.expanded
			end
		end

		-- Icon
		local iconX = x + indent + (item.children and (config.iconSize + 4) or 0)
		local iconY = y + config.itemHeight / 2 - config.iconSize / 2
		local iconColor = isSelected and config.textColor or config.accentColor
		drawIcon(iconX, iconY, config.iconSize, item.type, iconColor)

		-- Text
		local textX = iconX + config.iconSize + 8
		local textY = y + (config.itemHeight - config.fontSize) / 2
		drawText(item.name, textX, textY, config.fontSize, config.fontSpacing, config.textColor)

		-- Click handling
		if isHovered and mousePressed and (not item.children or mousePos.x >= x + indent + config.iconSize + 4) then
			config.selectedItem = item
			if config.onItemSelect then
				config.onItemSelect(item)
			end
		end

		local nextY = y + config.itemHeight

		-- Draw children if expanded
		if item.expanded and item.children then
			for _, child in ipairs(item.children) do
				nextY = drawTreeItem(child, x, nextY, width, indent + config.indentSize, mousePos, mousePressed, dt)
			end
		end

		return nextY
	end

	local function drawScrollbar(panelRect, scrollOffset, contentHeight, panelId, dt)
		local visibleHeight = panelRect.height - config.headerHeight
		local maxScroll = math.max(0, contentHeight - visibleHeight)

		if maxScroll <= 0 then
			return
		end

		local scrollbarWidth = 6
		local scrollbarHeight = math.max(30, (visibleHeight / contentHeight) * visibleHeight)
		local scrollbarY = panelRect.y
			+ config.headerHeight
			+ (scrollOffset / maxScroll) * (visibleHeight - scrollbarHeight)
		local scrollbarX = panelRect.x + panelRect.width - scrollbarWidth - 4

		local scrollbarRect = rect.new(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight)
		local isHovered = rect.MouseIsInRect(scrollbarRect)

		-- Fade in/out scrollbar
		if not config.scrollbarAlpha[panelId] then
			config.scrollbarAlpha[panelId] = 0
		end

		if rect.MouseIsInRect(panelRect) or isHovered then
			config.scrollbarAlpha[panelId] = math.min(config.scrollbarAlpha[panelId] + dt * 5, 1)
		else
			config.scrollbarAlpha[panelId] = math.max(config.scrollbarAlpha[panelId] - dt * 3, 0)
		end

		if config.scrollbarAlpha[panelId] > 0.01 then
			local scrollbarColor = isHovered and config.scrollbarHoverColor or config.scrollbarColor
			raylib.lib.DrawRectangleRounded(
				rect:translate(scrollbarRect),
				0.5,
				4,
				c3tr(scrollbarColor, 1 - config.scrollbarAlpha[panelId])
			)
		end
	end

	-- Update middle panel based on selected category
	local function updateMiddlePanel()
		config.middleItems = {}
		if config.selectedCategoryIndex > 0 and config.selectedCategoryIndex <= #config.categories then
			local category = config.categories[config.selectedCategoryIndex]

			-- Flatten all items from the category
			local function addItems(items)
				for _, item in ipairs(items) do
					if
						config.middleSearch == ""
						or string.find(string.lower(item.name), string.lower(config.middleSearch))
					then
						table.insert(config.middleItems, item)
					end
					if item.children then
						addItems(item.children)
					end
				end
			end

			if category.items then
				addItems(category.items)
			end
		end
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1
		local scrollWheel = raylib.lib.GetMouseWheelMove()

		-- Background with border
		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.borderColor, 0)
		)
		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(r.x + 1, r.y + 1, r.width - 2, r.height - 2)),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		-- Calculate panel positions
		local leftPanel = rect.new(r.x + 1, r.y + 1, config.leftPanelWidth, r.height - 2)
		local middlePanel = rect.new(r.x + config.leftPanelWidth + 2, r.y + 1, config.middlePanelWidth, r.height - 2)
		local rightPanel = rect.new(
			r.x + config.leftPanelWidth + config.middlePanelWidth + 3,
			r.y + 1,
			r.width - config.leftPanelWidth - config.middlePanelWidth - 4,
			r.height - 2
		)

		-- Draw dividers with subtle gradient effect
		raylib.lib.DrawRectangle(
			r.x + config.leftPanelWidth + 1,
			r.y + 1,
			1,
			r.height - 2,
			c3tr(config.dividerColor, 0)
		)
		raylib.lib.DrawRectangle(
			r.x + config.leftPanelWidth + config.middlePanelWidth + 2,
			r.y + 1,
			1,
			r.height - 2,
			c3tr(config.dividerColor, 0)
		)

		-- LEFT PANEL: Categories tree
		raylib.lib.BeginScissorMode(leftPanel.x, leftPanel.y, leftPanel.width, leftPanel.height)

		local leftHeaderRect = rect.new(leftPanel.x, leftPanel.y, leftPanel.width, config.headerHeight)

		-- Header gradient effect
		raylib.lib.DrawRectangle(
			leftHeaderRect.x,
			leftHeaderRect.y,
			leftHeaderRect.width,
			config.headerHeight,
			c3tr(config.headerColor, 0)
		)
		raylib.lib.DrawRectangle(
			leftHeaderRect.x,
			leftHeaderRect.y + config.headerHeight - 1,
			leftHeaderRect.width,
			1,
			c3tr(config.dividerColor, 0)
		)

		drawText(
			"API Reference",
			leftHeaderRect.x + config.padding,
			leftHeaderRect.y + 16,
			config.headerFontSize,
			config.headerFontSpacing,
			config.textColor
		)

		local currentY = leftPanel.y + config.headerHeight + config.padding - config.leftScrollOffset
		local contentStartY = currentY

		if rect.MouseIsInRect(leftPanel) then
			config.leftScrollOffset = math.max(0, config.leftScrollOffset - scrollWheel * 25)
		end

		for i, category in ipairs(config.categories) do
			local categoryKey = "cat_" .. i
			local categoryRect = rect.new(
				leftPanel.x + config.padding,
				currentY,
				leftPanel.width - config.padding * 2,
				config.itemHeight
			)
			local isHovered = rect.MouseIsInRect(categoryRect)
			local hoverAlpha = getHoverState(categoryKey, dt, isHovered)

			-- Background with rounded corners
			if hoverAlpha > 0 then
				raylib.lib.DrawRectangleRounded(
					rect:translate(
						rect.new(categoryRect.x, categoryRect.y + 1, categoryRect.width, categoryRect.height - 2)
					),
					0.15,
					6,
					c3tr(config.hoverColor, 1 - hoverAlpha * 0.3)
				)
			end

			-- Arrow with rotation animation
			drawIcon(
				categoryRect.x + 2,
				categoryRect.y + config.itemHeight / 2 - config.iconSize / 2,
				config.iconSize,
				category.expanded and "expanded" or "collapsed",
				config.subtextColor
			)

			-- Category name
			local textX = categoryRect.x + config.iconSize + 8
			local textY = categoryRect.y + (config.itemHeight - config.fontSize) / 2
			drawText(category.name, textX, textY, config.fontSize, config.fontSpacing, config.textColor)

			-- Count badge
			local countText = tostring(category.count)
			local countWidth = measureText(countText, config.fontSize - 2, config.fontSpacing)
			local badgeWidth = countWidth + 12
			local badgeX = categoryRect.x + categoryRect.width - badgeWidth
			local badgeY = categoryRect.y + (config.itemHeight - 18) / 2

			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(badgeX, badgeY, badgeWidth, 18)),
				0.3,
				6,
				c3tr(config.itemColor, 0)
			)
			drawText(countText, badgeX + 6, badgeY + 4, config.fontSize - 2, config.fontSpacing, config.subtextColor)

			-- Click handling
			if isHovered and mousePressed then
				category.expanded = not category.expanded
				config.selectedCategoryIndex = i
				updateMiddlePanel()
			end

			currentY = currentY + config.itemHeight

			-- Draw items if expanded
			if category.expanded and category.items then
				for _, item in ipairs(category.items) do
					currentY = drawTreeItem(
						item,
						leftPanel.x + config.padding,
						currentY,
						leftPanel.width - config.padding * 2,
						config.indentSize,
						mousePos,
						mousePressed,
						dt
					)
				end
			end
		end

		local leftContentHeight = currentY - contentStartY
		raylib.lib.EndScissorMode()

		drawScrollbar(leftPanel, config.leftScrollOffset, leftContentHeight, "left", dt)

		-- MIDDLE PANEL: Filtered list
		raylib.lib.BeginScissorMode(middlePanel.x, middlePanel.y, middlePanel.width, middlePanel.height)

		local middleHeaderRect = rect.new(middlePanel.x, middlePanel.y, middlePanel.width, config.headerHeight)
		raylib.lib.DrawRectangle(
			middleHeaderRect.x,
			middleHeaderRect.y,
			middleHeaderRect.width,
			middleHeaderRect.height,
			c3tr(config.headerColor, 0)
		)
		raylib.lib.DrawRectangle(
			middleHeaderRect.x,
			middleHeaderRect.y + config.headerHeight - 1,
			middleHeaderRect.width,
			1,
			c3tr(config.dividerColor, 0)
		)

		if config.selectedCategoryIndex > 0 and config.selectedCategoryIndex <= #config.categories then
			local category = config.categories[config.selectedCategoryIndex]
			drawText(
				category.name,
				middleHeaderRect.x + config.padding,
				middleHeaderRect.y + 16,
				config.headerFontSize,
				config.headerFontSpacing,
				config.textColor
			)
		end

		-- Search bar with focus effect
		local searchRect = rect.new(
			middlePanel.x + config.padding,
			middlePanel.y + config.headerHeight + config.padding,
			middlePanel.width - config.padding * 2,
			config.searchHeight
		)
		local searchHovered = rect.MouseIsInRect(searchRect)
		local searchHoverAlpha = getHoverState("search", dt, searchHovered)

		-- Search background
		raylib.lib.DrawRectangleRounded(rect:translate(searchRect), 0.18, 8, c3tr(config.itemColor, 0))

		-- Search icon
		local searchIconX = searchRect.x + 10
		local searchIconY = searchRect.y + (config.searchHeight - 12) / 2
		raylib.lib.DrawCircleLines(searchIconX + 5, searchIconY + 5, 4, c3tr(config.subtextColor, 0))
		raylib.lib.DrawLineEx(
			vector.create(searchIconX + 8, searchIconY + 8),
			vector.create(searchIconX + 11, searchIconY + 11),
			1.5,
			c3tr(config.subtextColor, 0)
		)

		drawText(
			config.middleSearch == "" and "Search..." or config.middleSearch,
			searchRect.x + 28,
			searchRect.y + (config.searchHeight - config.fontSize) / 2,
			config.fontSize,
			config.fontSpacing,
			config.middleSearch == "" and config.subtextColor or config.textColor
		)

		currentY = middlePanel.y
			+ config.headerHeight
			+ config.searchHeight
			+ config.padding * 2
			- config.middleScrollOffset
		contentStartY = currentY

		if
			rect.MouseIsInRect(
				rect.new(
					middlePanel.x,
					middlePanel.y + config.headerHeight,
					middlePanel.width,
					middlePanel.height - config.headerHeight
				)
			)
		then
			config.middleScrollOffset = math.max(0, config.middleScrollOffset - scrollWheel * 25)
		end

		if #config.middleItems == 0 then
			updateMiddlePanel()
		end

		for i, item in ipairs(config.middleItems) do
			local itemKey = "middle_" .. i
			local itemRect = rect.new(
				middlePanel.x + config.padding,
				currentY,
				middlePanel.width - config.padding * 2,
				config.itemHeight
			)
			local isHovered = rect.MouseIsInRect(itemRect)
			local hoverAlpha = getHoverState(itemKey, dt, isHovered)
			local isSelected = config.selectedItem == item

			-- Background
			if isSelected then
				raylib.lib.DrawRectangleRounded(
					rect:translate(rect.new(itemRect.x + 2, itemRect.y + 1, itemRect.width - 4, itemRect.height - 2)),
					0.15,
					6,
					c3tr(config.selectedColor, 0)
				)
			elseif hoverAlpha > 0 then
				raylib.lib.DrawRectangleRounded(
					rect:translate(rect.new(itemRect.x + 2, itemRect.y + 1, itemRect.width - 4, itemRect.height - 2)),
					0.15,
					6,
					c3tr(config.hoverColor, 1 - hoverAlpha * 0.3)
				)
			end

			-- Icon
			local iconColor = isSelected and config.textColor or config.accentColor
			drawIcon(
				itemRect.x + 6,
				itemRect.y + config.itemHeight / 2 - config.iconSize / 2,
				config.iconSize,
				item.type,
				iconColor
			)

			-- Text
			drawText(
				item.name,
				itemRect.x + config.iconSize + 14,
				itemRect.y + (config.itemHeight - config.fontSize) / 2,
				config.fontSize,
				config.fontSpacing,
				config.textColor
			)

			if isHovered and mousePressed then
				config.selectedItem = item
				if config.onItemSelect then
					config.onItemSelect(item)
				end
			end

			currentY = currentY + config.itemHeight
		end

		local middleContentHeight = currentY - contentStartY
		raylib.lib.EndScissorMode()

		drawScrollbar(middlePanel, config.middleScrollOffset, middleContentHeight, "middle", dt)

		-- RIGHT PANEL: Detail view
		raylib.lib.BeginScissorMode(rightPanel.x, rightPanel.y, rightPanel.width, rightPanel.height)

		local rightHeaderRect = rect.new(rightPanel.x, rightPanel.y, rightPanel.width, config.headerHeight)
		raylib.lib.DrawRectangle(
			rightHeaderRect.x,
			rightHeaderRect.y,
			rightHeaderRect.width,
			rightHeaderRect.height,
			c3tr(config.headerColor, 0)
		)
		raylib.lib.DrawRectangle(
			rightHeaderRect.x,
			rightHeaderRect.y + config.headerHeight - 1,
			rightHeaderRect.width,
			1,
			c3tr(config.dividerColor, 0)
		)

		if config.selectedItem then
			drawText(
				config.selectedItem.name,
				rightHeaderRect.x + config.padding,
				rightHeaderRect.y + 16,
				config.headerFontSize,
				config.headerFontSpacing,
				config.textColor
			)

			currentY = rightPanel.y + config.headerHeight + config.padding * 2 - config.rightScrollOffset
			contentStartY = currentY

			if rect.MouseIsInRect(rightPanel) then
				config.rightScrollOffset = math.max(0, config.rightScrollOffset - scrollWheel * 25)
			end

			-- Type badge
			local typeText = config.selectedItem.type:upper()
			local typeWidth = measureText(typeText, config.fontSize - 2, config.fontSpacing)
			local badgeWidth = typeWidth + 16

			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(rightPanel.x + config.padding, currentY, badgeWidth, 22)),
				0.25,
				6,
				c3tr(config.accentColor, 0.8)
			)
			drawText(
				typeText,
				rightPanel.x + config.padding + 8,
				currentY + 5,
				config.fontSize - 2,
				config.fontSpacing,
				config.textColor
			)
			currentY = currentY + 32

			-- Section divider
			raylib.lib.DrawRectangle(
				rightPanel.x + config.padding,
				currentY,
				rightPanel.width - config.padding * 2,
				1,
				c3tr(config.dividerColor, 0)
			)
			currentY = currentY + 16

			-- Description section
			drawText(
				"Description",
				rightPanel.x + config.padding,
				currentY,
				config.fontSize + 1,
				config.fontSpacing,
				config.textColor
			)
			currentY = currentY + 28

			-- Description content in a subtle box
			local descText = config.selectedItem.description
				or (
					"Detailed information about "
					.. config.selectedItem.name
					.. ". This would typically include usage examples, parameters, return values, and other relevant documentation."
				)
			local descBoxWidth = rightPanel.width - config.padding * 2

			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(rightPanel.x + config.padding, currentY, descBoxWidth, 80)),
				0.12,
				8,
				c3tr(config.panelColor, 0)
			)

			drawText(
				descText,
				rightPanel.x + config.padding + 12,
				currentY + 12,
				config.fontSize,
				config.fontSpacing,
				config.subtextColor
			)

			currentY = currentY + 96

			local rightContentHeight = currentY - contentStartY
		else
			drawText(
				"Details",
				rightHeaderRect.x + config.padding,
				rightHeaderRect.y + 16,
				config.headerFontSize,
				config.headerFontSpacing,
				config.textColor
			)

			-- Empty state
			local emptyY = rightPanel.y + rightPanel.height / 2 - 30
			drawText(
				"Select an item to view details",
				rightPanel.x + config.padding,
				emptyY,
				config.fontSize,
				config.fontSpacing,
				config.subtextColor
			)
		end

		raylib.lib.EndScissorMode()

		if config.selectedItem then
			drawScrollbar(rightPanel, config.rightScrollOffset, currentY - contentStartY, "right", dt)
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
