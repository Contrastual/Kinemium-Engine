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

		backgroundColor = color3.new(0.11, 0.12, 0.15),
		searchBgColor = color3.new(0.14, 0.15, 0.18),
		hoverColor = color3.new(0.18, 0.22, 0.35),
		selectedColor = color3.new(0.12, 0.22, 0.45),
		textColor = color3.new(0.85, 0.85, 0.85),
		dimTextColor = color3.new(0.55, 0.55, 0.60),
		accentColor = color3.new(0.35, 0.55, 0.95),

		searchText = "",
		files = data.files or {},
		filteredFiles = {},
		selectedIndex = -1,
		hoveredIndex = -1,
		scrollOffset = 0,
		recentlyOpened = data.recentlyOpened or {},

		onFileSelect = data.onFileSelect,
		onClose = data.onClose,

		itemHeight = 24,
		maxVisibleItems = 15,
		padding = 8,
	}

	local function filterFiles()
		config.filteredFiles = {}
		local searchLower = config.searchText:lower()

		if searchLower == "" then
			config.filteredFiles = config.files
		else
			for _, file in ipairs(config.files) do
				local nameLower = file.name:lower()
				if nameLower:find(searchLower, 1, true) then
					table.insert(config.filteredFiles, file)
				end
			end
		end
	end

	filterFiles()

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		if prop == "files" or prop == "searchText" then
			filterFiles()
		end
		return wrapper
	end

	wrapper.addFile = function(name, path, fileType)
		table.insert(config.files, {
			name = name,
			path = path,
			type = fileType or "file",
		})
		filterFiles()
		return wrapper
	end

	wrapper.setSearchText = function(text)
		config.searchText = text
		filterFiles()
		return wrapper
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1
		local scrollWheel = raylib.lib.GetMouseWheelMove()

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		local searchHeight = 36
		local searchRect =
			rect.new(r.x + config.padding, r.y + config.padding, r.width - config.padding * 2, searchHeight)

		raylib.lib.DrawRectangleRounded(rect:translate(searchRect), 0.12, 8, c3tr(config.searchBgColor, 0))

		local searchDisplayText = config.searchText == "" and "init" or config.searchText
		local searchColor = config.searchText == "" and config.dimTextColor or config.textColor
		raylib.lib.DrawText(searchDisplayText, searchRect.x + 10, searchRect.y + 10, 14, c3tr(searchColor, 0))

		local resultsY = r.y + config.padding + searchHeight + config.padding
		local resultsHeight = r.height - searchHeight - config.padding * 3
		local resultsRect = rect.new(r.x + config.padding, resultsY, r.width - config.padding * 2, resultsHeight)

		local headerHeight = 0
		if #config.recentlyOpened > 0 and config.searchText == "" then
			headerHeight = 28
			raylib.lib.DrawText("recently opened", resultsRect.x + 10, resultsY + 6, 11, c3tr(config.dimTextColor, 0))

			-- Icons on the right
			local iconX = resultsRect.x + resultsRect.width - 50
			raylib.lib.DrawRectangle(iconX, resultsY + 8, 14, 14, c3tr(config.dimTextColor, 0.3))
			raylib.lib.DrawRectangle(iconX + 20, resultsY + 8, 14, 14, c3tr(config.dimTextColor, 0.3))
		end

		if rect.MouseIsInRect(resultsRect) then
			config.scrollOffset = config.scrollOffset - scrollWheel * config.itemHeight
		end

		local maxScroll = math.max(0, (#config.filteredFiles * config.itemHeight) - (resultsHeight - headerHeight))
		config.scrollOffset = math.clamp(config.scrollOffset, 0, maxScroll)

		config.hoveredIndex = -1
		local filesToShow = config.searchText == "" and config.recentlyOpened or config.filteredFiles

		for i, file in ipairs(filesToShow) do
			local itemY = resultsY + headerHeight + (i - 1) * config.itemHeight - config.scrollOffset

			-- Skip if not visible
			if itemY + config.itemHeight < resultsY or itemY > resultsY + resultsHeight then
				continue
			end

			local itemRect = rect.new(resultsRect.x, itemY, resultsRect.width, config.itemHeight)
			local isHovered = rect.MouseIsInRect(itemRect)
			local isSelected = i == config.selectedIndex

			if isHovered then
				config.hoveredIndex = i
			end

			if isSelected then
				raylib.lib.DrawRectangleRounded(rect:translate(itemRect), 0.15, 4, c3tr(config.selectedColor, 0))
			elseif isHovered then
				raylib.lib.DrawRectangleRounded(rect:translate(itemRect), 0.15, 4, c3tr(config.hoverColor, 0))
			end

			local iconSize = 16
			local iconX = itemRect.x + 10
			local iconY = itemY + (config.itemHeight - iconSize) / 2

			local iconColor = file.type == "lua" and color3.new(0.8, 0.3, 0.3) or color3.new(0.4, 0.5, 0.6)
			raylib.lib.DrawRectangle(iconX, iconY, iconSize, iconSize, c3tr(iconColor, 0))

			local textX = iconX + iconSize + 8
			local fileName = file.name
			local fileNameColor = config.accentColor

			raylib.lib.DrawText(fileName, textX, itemY + 5, 12, c3tr(fileNameColor, 0))

			local fileNameWidth = raylib.lib.MeasureText(fileName, 12)
			local pathText = file.path or ""
			raylib.lib.DrawText(pathText, textX + fileNameWidth + 4, itemY + 5, 12, c3tr(config.dimTextColor, 0))

			if isHovered or isSelected then
				local iconX = itemRect.x + itemRect.width - 40
				raylib.lib.DrawRectangle(iconX, itemY + 6, 12, 12, c3tr(config.dimTextColor, 0.3))
				raylib.lib.DrawRectangle(iconX + 18, itemY + 6, 12, 12, c3tr(config.dimTextColor, 0.3))
			end

			if isHovered and mousePressed then
				config.selectedIndex = i
				if config.onFileSelect then
					config.onFileSelect(file)
				end
			end

			continue
		end

		if #filesToShow * config.itemHeight > resultsHeight - headerHeight then
			local scrollbarWidth = 4
			local scrollbarHeight = (resultsHeight / (#filesToShow * config.itemHeight)) * resultsHeight
			local scrollbarY = resultsY
				+ headerHeight
				+ (config.scrollOffset / maxScroll) * (resultsHeight - headerHeight - scrollbarHeight)

			raylib.lib.DrawRectangleRounded(
				structs.Rectangle:new({
					x = r.x + r.width - config.padding - scrollbarWidth,
					y = scrollbarY,
					width = scrollbarWidth,
					height = scrollbarHeight,
				}),
				0.5,
				4,
				c3tr(config.dimTextColor, 0.5)
			)
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
