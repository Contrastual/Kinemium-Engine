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
		rounded = data.rounded or { 0.08, 8 },
		modifiers = {},

		-- Colors
		backgroundColor = data.backgroundColor or color3.new(0.10, 0.10, 0.11),
		itemBackgroundColor = data.itemBackgroundColor or color3.new(0.14, 0.14, 0.16),
		hoverColor = data.hoverColor or color3.new(0.18, 0.18, 0.20),
		selectedColor = data.selectedColor or color3.new(0.12, 0.35, 0.25),
		iconColor = data.iconColor or color3.new(0.65, 0.65, 0.68),
		selectedIconColor = data.selectedIconColor or color3.new(0.35, 0.85, 0.55),
		textColor = data.textColor or color3.new(0.85, 0.85, 0.87),
		dividerColor = data.dividerColor or color3.new(0.20, 0.20, 0.22),
		categoryColor = data.categoryColor or color3.new(0.55, 0.55, 0.57),

		-- Navigation items
		items = data.items,

		-- Layout
		collapsedWidth = 72,
		expandedWidth = 240,
		currentWidth = 60,
		targetWidth = 60,
		itemSize = 48,
		iconSize = 24,
		padding = 8,
		spacing = 8,
		dividerHeight = 1,
		expandSpeed = 12,
		font = data.font or raylib.lib.GetFontDefault(),

		-- Interaction
		hoveredIndex = -1,
		selectedIndex = -1,
		scrollOffset = 0,
		isExpanded = false,
		textAlpha = 0,

		onItemClick = data.onItemClick,
	}

	local function DrawText(text, posX, posY, fontSize, color)
		raylib.lib.DrawTextEx(config.font, text, vector.create(posX, posY), fontSize, 1, color)
	end

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.addItem = function(icon, itemType, label, texture)
		table.insert(config.items, {
			icon = icon,
			type = itemType or "icon",
			label = label,
			texture = texture,
			selected = false,
		})
		return wrapper
	end

	wrapper.setSelected = function(index)
		for i, item in ipairs(config.items) do
			item.selected = (i == index)
		end
		config.selectedIndex = index
		return wrapper
	end

	local function drawIcon(x, y, size, iconName, color)
		local centerX = x + size / 2
		local centerY = y + size / 2

		if iconName == "home" then
			raylib.lib.DrawRectangle(centerX - 6, centerY - 2, 12, 10, c3tr(color, 0))
			raylib.lib.DrawTriangle(
				vector.create(centerX, centerY - 8),
				vector.create(centerX - 8, centerY - 2),
				vector.create(centerX + 8, centerY - 2),
				c3tr(color, 0)
			)
		elseif iconName == "compass" then
			raylib.lib.DrawCircleLines(centerX, centerY, 8, c3tr(color, 0))
			raylib.lib.DrawLineEx(
				vector.create(centerX, centerY - 6),
				vector.create(centerX, centerY + 6),
				2,
				c3tr(color, 0)
			)
		elseif iconName == "shirt" then
			raylib.lib.DrawRectangle(centerX - 6, centerY - 2, 12, 10, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX - 8, centerY - 4, 4, 6, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX + 4, centerY - 4, 4, 6, c3tr(color, 0))
		elseif iconName == "stats" then
			raylib.lib.DrawRectangle(centerX - 8, centerY + 2, 3, 6, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX - 3, centerY - 2, 3, 10, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX + 2, centerY - 6, 3, 14, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX + 7, centerY, 3, 8, c3tr(color, 0))
		elseif iconName == "fire" then
			raylib.lib.DrawCircle(centerX, centerY + 2, 6, c3tr(color, 0))
			raylib.lib.DrawTriangle(
				vector.create(centerX, centerY - 8),
				vector.create(centerX - 6, centerY + 2),
				vector.create(centerX + 6, centerY + 2),
				c3tr(color, 0)
			)
		elseif iconName == "cube" then
			raylib.lib.DrawRectangle(centerX - 6, centerY - 6, 12, 12, c3tr(color, 0))
		elseif iconName == "cube-outline" then
			raylib.lib.DrawRectangleLines(centerX - 6, centerY - 6, 12, 12, c3tr(color, 0))
		elseif iconName == "add" then
			raylib.lib.DrawRectangle(centerX - 1, centerY - 8, 2, 16, c3tr(color, 0))
			raylib.lib.DrawRectangle(centerX - 8, centerY - 1, 16, 2, c3tr(color, 0))
		elseif iconName == "settings" then
			raylib.lib.DrawCircleLines(centerX, centerY, 6, c3tr(color, 0))
			raylib.lib.DrawCircle(centerX, centerY, 3, c3tr(color, 0))
		elseif iconName == "logout" then
			raylib.lib.DrawLineEx(
				vector.create(centerX - 6, centerY),
				vector.create(centerX + 6, centerY),
				2,
				c3tr(color, 0)
			)
			raylib.lib.DrawLineEx(
				vector.create(centerX + 2, centerY - 4),
				vector.create(centerX + 6, centerY),
				2,
				c3tr(color, 0)
			)
			raylib.lib.DrawLineEx(
				vector.create(centerX + 2, centerY + 4),
				vector.create(centerX + 6, centerY),
				2,
				c3tr(color, 0)
			)
		else
			raylib.lib.DrawCircle(centerX, centerY, 6, c3tr(color, 0))
		end
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1
		local scrollWheel = raylib.lib.GetMouseWheelMove()

		-- Check if mouse is hovering over the navigation
		local navRect = rect.new(r.x, r.y, config.currentWidth, r.height)
		local isHovering = rect.MouseIsInRect(navRect)

		-- Update expansion state
		if isHovering then
			config.targetWidth = config.expandedWidth
			config.isExpanded = true
		else
			config.targetWidth = config.collapsedWidth
			config.isExpanded = false
		end

		-- Animate width
		local widthDiff = config.targetWidth - config.currentWidth
		config.currentWidth = config.currentWidth + widthDiff * config.expandSpeed * dt

		-- Animate text alpha
		if config.isExpanded then
			config.textAlpha = math.min(1, config.textAlpha + 5 * dt)
		else
			config.textAlpha = math.max(0, config.textAlpha - 5 * dt)
		end

		-- Background
		raylib.lib.DrawRectangle(r.x, r.y, config.currentWidth, r.height, c3tr(config.backgroundColor, 0))

		-- Handle scrolling
		if isHovering then
			config.scrollOffset = config.scrollOffset - scrollWheel * 20
		end

		config.hoveredIndex = -1
		local currentY = r.y + config.padding - config.scrollOffset

		raylib.lib.BeginScissorMode(r.x, r.y, config.currentWidth, r.height)

		for i, item in ipairs(config.items) do
			if item.type == "divider" then
				-- Draw divider
				raylib.lib.DrawRectangle(
					r.x + config.padding * 2,
					currentY + config.spacing,
					config.currentWidth - config.padding * 4,
					config.dividerHeight,
					c3tr(config.dividerColor, 0)
				)
				currentY = currentY + config.spacing * 2 + config.dividerHeight
			elseif item.type == "spacer" then
				local usedSpace = currentY - r.y
				local totalItemHeight = 0

				for j = i + 1, #config.items do
					if config.items[j].type ~= "spacer" then
						totalItemHeight = totalItemHeight + config.itemSize + config.spacing
					end
				end

				local remainingSpace = r.height - usedSpace - totalItemHeight - config.padding
				currentY = currentY + math.max(0, remainingSpace)
			elseif item.type == "category" then
				-- Draw category title (only visible when expanded)
				if config.textAlpha > 0.1 then
					local categoryText = item.label or "CATEGORY"
					DrawText(
						categoryText,
						r.x + config.padding * 2,
						currentY + 4,
						10,
						c3tr(config.categoryColor, 1 - config.textAlpha)
					)
				end
				currentY = currentY + 20
			else
				-- Regular item
				local itemX = config.isExpanded and r.x + config.padding
					or r.x + (config.currentWidth - config.itemSize) / 2
				local itemRect = rect.new(itemX, currentY, config.itemSize, config.itemSize)

				local isHovered = rect.MouseIsInRect(itemRect)
				local isSelected = item.selected or config.selectedIndex == i

				if isHovered then
					config.hoveredIndex = i
				end

				-- Item background
				local bgColor = config.itemBackgroundColor
				if isSelected then
					bgColor = config.selectedColor
				elseif isHovered then
					bgColor = config.hoverColor
				end

				-- Adjust item width when expanded
				local itemRenderWidth = config.isExpanded and (config.currentWidth - config.padding * 2)
					or config.itemSize
				local adjustedItemRect = rect.new(itemX, currentY, itemRenderWidth, config.itemSize)

				raylib.lib.DrawRectangleRounded(rect:translate(adjustedItemRect), 0.15, 8, c3tr(bgColor, 0))

				if item.texture ~= nil then
					raylib.lib.DrawTexturePro(
						item.texture.texture,
						structs.Rectangle:new({ x = 0, y = 0, width = item.texture.x, height = item.texture.y }),
						structs.Rectangle:new({
							x = itemX + (config.itemSize - config.iconSize) / 2,
							y = currentY + (config.itemSize - config.iconSize) / 2,
							width = config.iconSize,
							height = config.iconSize,
						}),
						vector.create(0, 0),
						0,
						raylib.const.WHITE
					)
				else
					local iconColor = isSelected and config.selectedIconColor or config.iconColor
					drawIcon(
						itemX + (config.itemSize - config.iconSize) / 2,
						currentY + (config.itemSize - config.iconSize) / 2,
						config.iconSize,
						item.icon,
						iconColor
					)
				end

				if item.label and config.textAlpha > 0.1 then
					local textX = itemX + config.itemSize + 8
					local textY = currentY + (config.itemSize - 14) / 2
					DrawText(item.label, textX, textY, 14, c3tr(config.textColor, 1 - config.textAlpha))
				end

				-- Click handling
				if isHovered and mousePressed then
					wrapper.setSelected(i)
					if config.onItemClick then
						config.onItemClick(item, i)
					end
				end

				currentY = currentY + config.itemSize + config.spacing
			end
		end

		raylib.lib.EndScissorMode()

		local contentHeight = currentY - r.y + config.padding
		if contentHeight > r.height then
			local maxScroll = contentHeight - r.height
			config.scrollOffset = math.clamp(config.scrollOffset, 0, maxScroll)

			local scrollbarWidth = 3
			local scrollbarHeight = (r.height / contentHeight) * r.height
			local scrollbarY = r.y + (config.scrollOffset / maxScroll) * (r.height - scrollbarHeight)

			raylib.lib.DrawRectangle(
				r.x + config.currentWidth - scrollbarWidth - 2,
				scrollbarY,
				scrollbarWidth,
				scrollbarHeight,
				c3tr(config.iconColor, 0.3)
			)
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
