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

local defaultFont = raylib.lib.GetFontDefault()

return function(objects, data)
	local config = {
		obj_rect = rect.new(
			data.x or data[1],
			data.y or data[2],
			data.width or data[3] or 250,
			data.height or data[4] or 400
		),
		Font = data.Font or defaultFont,
		items = data.items or {},
		visible = data.visible ~= false,

		backgroundColor = data.backgroundColor or color3.new(0, 0, 0),
		hoverColor = data.hoverColor or color3.new(0.18, 0.18, 0.2),
		textColor = data.textColor or color3.new(0.9, 0.9, 0.9),
		disabledColor = data.disabledColor or color3.new(0.5, 0.5, 0.5),
		shortcutColor = data.shortcutColor or color3.new(0.6, 0.6, 0.6),
		separatorColor = data.separatorColor or color3.new(0.25, 0.25, 0.25),
		categoryColor = data.categoryColor or color3.new(0.7, 0.7, 0.7),

		fontSize = data.fontSize or 14,
		categoryFontSize = data.categoryFontSize or 12,

		itemHeight = data.itemHeight or 28,
		categoryHeight = data.categoryHeight or 24,
		padding = data.padding or 8,
		leftPadding = data.leftPadding or 12,
		rightPadding = data.rightPadding or 12,
		rounded = data.rounded or { 0.05, 8 },

		openSubmenuPath = {},
		animAlpha = 0,
		submenuRects = {},
	}

	local wrapper = {}

	local function calculateHeight(items)
		local height = config.padding * 2
		for _, item in ipairs(items) do
			if item.type == "separator" then
				height = height + 9
			elseif item.type == "category" then
				height = height + config.categoryHeight
			else
				height = height + config.itemHeight
			end
		end
		return height
	end

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.show = function()
		config.visible = true
		config.animAlpha = 0
		return wrapper
	end

	wrapper.hide = function()
		config.visible = false
		config.openSubmenuPath = {}
		config.submenuRects = {}
		return wrapper
	end

	wrapper.toggle = function()
		config.visible = not config.visible
		if not config.visible then
			config.openSubmenuPath = {}
			config.submenuRects = {}
		end
		return wrapper
	end

	wrapper.setItems = function(items)
		config.items = items
		return wrapper
	end

	wrapper.enable = function(indexOrLabel)
		for i, item in ipairs(config.items) do
			if i == indexOrLabel or item.label == indexOrLabel then
				item.disabled = false
				break
			end
		end
		return wrapper
	end

	wrapper.disable = function(indexOrLabel)
		for i, item in ipairs(config.items) do
			if i == indexOrLabel or item.label == indexOrLabel then
				item.disabled = true
				break
			end
		end
		return wrapper
	end

	wrapper.check = function(indexOrLabel)
		for i, item in ipairs(config.items) do
			if i == indexOrLabel or item.label == indexOrLabel then
				item.checked = true
				break
			end
		end
		return wrapper
	end

	wrapper.uncheck = function(indexOrLabel)
		for i, item in ipairs(config.items) do
			if i == indexOrLabel or item.label == indexOrLabel then
				item.checked = false
				break
			end
		end
		return wrapper
	end

	local function renderSubmenu(submenuItems, x, y, depth)
		if not submenuItems or #submenuItems == 0 then
			return
		end

		local submenuHeight = calculateHeight(submenuItems)
		local submenuWidth = config.obj_rect.width
		local submenuRect = rect.new(x, y, submenuWidth, submenuHeight)

		table.insert(config.submenuRects, submenuRect)

		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(x + 2, y + 2, submenuWidth, submenuHeight)),
			config.rounded[1],
			config.rounded[2],
			c3tr(color3.new(0, 0, 0), 0.7)
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(submenuRect),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		local itemY = y + config.padding

		for i, item in ipairs(submenuItems) do
			if item.type == "separator" then
				raylib.lib.DrawRectangle(
					x + config.leftPadding,
					itemY + 4,
					submenuWidth - config.leftPadding - config.rightPadding,
					1,
					c3tr(config.separatorColor, 0)
				)
				itemY = itemY + 9
			elseif item.type == "category" then
				raylib.lib.DrawTextEx(
					config.Font or defaultFont,
					string.upper(item.label),
					vector.create(x + config.leftPadding, itemY + (config.categoryHeight - config.categoryFontSize) / 2),
					config.categoryFontSize,
					1,
					c3tr(config.categoryColor, 0)
				)
				itemY = itemY + config.categoryHeight
			else
				local itemRect = rect.new(x, itemY, submenuWidth, config.itemHeight)
				local isHovered = rect.MouseIsInRect(itemRect) and not item.disabled

				if isHovered then
					raylib.lib.DrawRectangle(
						x + 4,
						itemY,
						submenuWidth - 8,
						config.itemHeight,
						c3tr(config.hoverColor, 0)
					)
				end

				local textColor = item.disabled and config.disabledColor or config.textColor

				if item.checked then
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						"✓",
						vector.create(x + config.leftPadding, itemY + (config.itemHeight - config.fontSize) / 2),
						config.fontSize,
						1,
						c3tr(textColor, 0)
					)
				end

				local labelX = x + config.leftPadding + (item.checked and 20 or 0)
				raylib.lib.DrawTextEx(
					config.Font or defaultFont,
					item.label,
					vector.create(labelX, itemY + (config.itemHeight - config.fontSize) / 2),
					config.fontSize,
					1,
					c3tr(textColor, 0)
				)

				if item.shortcut then
					local shortcutSize = raylib.lib.MeasureTextEx(defaultFont, item.shortcut, config.fontSize, 1)
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						item.shortcut,
						vector.create(
							x + submenuWidth - config.rightPadding - shortcutSize.x - (item.submenu and 20 or 0),
							itemY + (config.itemHeight - config.fontSize) / 2
						),
						config.fontSize,
						1,
						c3tr(config.shortcutColor, 0)
					)
				end

				if item.submenu then
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						"▶",
						vector.create(
							x + submenuWidth - config.rightPadding - 10,
							itemY + (config.itemHeight - config.fontSize) / 2
						),
						config.fontSize,
						1,
						c3tr(textColor, 0)
					)
				end

				if isHovered and item.submenu then
					local pathMatch = true
					if depth <= #config.openSubmenuPath then
						if config.openSubmenuPath[depth] ~= i then
							for j = depth, #config.openSubmenuPath do
								config.openSubmenuPath[j] = nil
							end
							config.openSubmenuPath[depth] = i
						end
					else
						config.openSubmenuPath[depth] = i
					end
				elseif isHovered and not item.submenu then
					for j = depth, #config.openSubmenuPath do
						config.openSubmenuPath[j] = nil
					end
				end

				if item.submenu and config.openSubmenuPath[depth] == i then
					renderSubmenu(item.submenu, x + submenuWidth - 2, itemY, depth + 1)
				end

				if
					isHovered
					and raylib.lib.IsMouseButtonReleased(0) == 1
					and not item.disabled
					and not item.submenu
				then
					if item.onClick then
						item.onClick()
					end
					wrapper.hide()
				end

				itemY = itemY + config.itemHeight
			end
		end
	end

	wrapper.render = function(dt)
		if not config.visible then
			return
		end

		config.animAlpha = config.animAlpha + (1 - config.animAlpha) * 0.2
		config.submenuRects = {} -- Reset submenu rects each frame

		local menuHeight = calculateHeight(config.items)
		local r = rect.new(config.obj_rect.x, config.obj_rect.y, config.obj_rect.width, menuHeight)

		table.insert(config.submenuRects, r)

		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(r.x + 2, r.y + 2, r.width, r.height)),
			config.rounded[1],
			config.rounded[2],
			c3tr(color3.new(0, 0, 0), 0.7)
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		local itemY = r.y + config.padding

		for i, item in ipairs(config.items) do
			if item.type == "separator" then
				raylib.lib.DrawRectangle(
					r.x + config.leftPadding,
					itemY + 4,
					r.width - config.leftPadding - config.rightPadding,
					1,
					c3tr(config.separatorColor, 0)
				)
				itemY = itemY + 9
			elseif item.type == "category" then
				raylib.lib.DrawTextEx(
					config.Font or defaultFont,
					string.upper(item.label),
					vector.create(
						r.x + config.leftPadding,
						itemY + (config.categoryHeight - config.categoryFontSize) / 2
					),
					config.categoryFontSize,
					1,
					c3tr(config.categoryColor, 0)
				)
				itemY = itemY + config.categoryHeight
			else
				local itemRect = rect.new(r.x, itemY, r.width, config.itemHeight)
				local isHovered = rect.MouseIsInRect(itemRect) and not item.disabled

				if isHovered then
					raylib.lib.DrawRectangle(r.x + 4, itemY, r.width - 8, config.itemHeight, c3tr(config.hoverColor, 0))
				end

				local textColor = item.disabled and config.disabledColor or config.textColor

				-- Checkbox
				if item.checked then
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						"✓",
						vector.create(r.x + config.leftPadding, itemY + (config.itemHeight - config.fontSize) / 2),
						config.fontSize,
						1,
						c3tr(textColor, 0)
					)
				end

				-- Label
				local labelX = r.x + config.leftPadding + (item.checked and 20 or 0)
				raylib.lib.DrawTextEx(
					config.Font or defaultFont,
					item.label,
					vector.create(labelX, itemY + (config.itemHeight - config.fontSize) / 2),
					config.fontSize,
					1,
					c3tr(textColor, 0)
				)

				-- Shortcut
				if item.shortcut then
					local shortcutSize =
						raylib.lib.MeasureTextEx(config.Font or defaultFont, item.shortcut, config.fontSize, 1)
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						item.shortcut,
						vector.create(
							r.x + r.width - config.rightPadding - shortcutSize.x - (item.submenu and 20 or 0),
							itemY + (config.itemHeight - config.fontSize) / 2
						),
						config.fontSize,
						1,
						c3tr(config.shortcutColor, 0)
					)
				end

				-- Submenu arrow
				if item.submenu then
					raylib.lib.DrawTextEx(
						config.Font or defaultFont,
						"▶",
						vector.create(
							r.x + r.width - config.rightPadding - 10,
							itemY + (config.itemHeight - config.fontSize) / 2
						),
						config.fontSize,
						1,
						c3tr(textColor, 0)
					)
				end

				-- Handle hover for submenu
				if isHovered and item.submenu then
					if #config.openSubmenuPath == 0 or config.openSubmenuPath[1] ~= i then
						config.openSubmenuPath = { i }
					end
				elseif isHovered and not item.submenu then
					config.openSubmenuPath = {}
				end

				if item.submenu and config.openSubmenuPath[1] == i then
					renderSubmenu(item.submenu, r.x + r.width - 2, itemY, 2)
				end

				if
					isHovered
					and raylib.lib.IsMouseButtonReleased(0) == 1
					and not item.disabled
					and not item.submenu
				then
					if item.onClick then
						item.onClick()
					end
					wrapper.hide()
				end

				itemY = itemY + config.itemHeight
			end
		end

		--[[
		if raylib.lib.IsMouseButtonReleased(0) == 1 then
			local clickedInside = false
			for _, menuRect in ipairs(config.submenuRects) do
				if rect.MouseIsInRect(menuRect) then
					clickedInside = true
					break
				end
			end

			if not clickedInside then
				wrapper.hide()
			end
		end
		--]]
	end

	table.insert(objects, wrapper)
	return wrapper
end
