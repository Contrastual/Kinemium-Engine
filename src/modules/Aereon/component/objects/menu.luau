local raylib = require("@raylib")
local structs = raylib.structs
local rect = require("@arect")(raylib.lib)
local color3 = require("@Color3")

local defaultFont = raylib.lib.GetFontDefault()

return function(objects, data)
	local config = {
		obj_rect = rect.new(
			data.x or data[1],
			data.y or data[2],
			data.width or data[3] or 220,
			data.height or data[4] or 400
		),
		Font = data.Font or defaultFont,
		items = data.items or {},
		visible = data.visible ~= false,

		backgroundColor = data.backgroundColor or color3.new(0.98, 0.98, 0.97),
		hoverColor = data.hoverColor or color3.new(0.93, 0.93, 0.92),
		textColor = data.textColor or color3.new(0.10, 0.10, 0.10),
		disabledColor = data.disabledColor or color3.new(0.65, 0.65, 0.63),
		shortcutColor = data.shortcutColor or color3.new(0.55, 0.55, 0.53),
		separatorColor = data.separatorColor or color3.new(0.88, 0.88, 0.87),
		categoryColor = data.categoryColor or color3.new(0.52, 0.52, 0.50),
		dangerColor = data.dangerColor or color3.new(0.80, 0.20, 0.18),
		dangerHoverColor = data.dangerHoverColor or color3.new(0.98, 0.93, 0.93),
		checkColor = data.checkColor or color3.new(0.20, 0.47, 0.95),

		fontSize = data.fontSize or 13,
		categoryFontSize = data.categoryFontSize or 10,

		itemHeight = data.itemHeight or 30,
		categoryHeight = data.categoryHeight or 22,
		padding = data.padding or 4,
		leftPadding = data.leftPadding or 8,
		rightPadding = data.rightPadding or 8,
		iconWidth = data.iconWidth or 20,
		rounded = data.rounded or { 0.06, 8 },
		itemRounded = data.itemRounded or { 0.1, 6 },

		openSubmenuPath = {},
		animAlpha = 0,
		submenuRects = {},
	}

	local wrapper = {}

	local function calculateHeight(items)
		local height = config.padding * 2
		for _, item in ipairs(items) do
			if item.type == "separator" then
				height = height + 7
			elseif item.type == "category" then
				height = height + config.categoryHeight
			else
				height = height + config.itemHeight
			end
		end
		return height
	end

	local function drawPanel(x, y, w, h)
		for i = 1, 3 do
			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(x + i, y + i * 2, w, h)),
				config.rounded[1],
				config.rounded[2],
				color3.new(0, 0, 0):ToRaylib(1 - (0.06 - i * 0.015))
			)
		end
		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(x, y, w, h)),
			config.rounded[1],
			config.rounded[2],
			config.backgroundColor:ToRaylib(0)
		)
	end

	local function drawItems(items, x, y, menuW, depth)
		local itemY = y + config.padding

		for i, item in ipairs(items) do
			if item.type == "separator" then
				raylib.lib.DrawRectangle(
					x + config.leftPadding,
					itemY + 3,
					menuW - config.leftPadding - config.rightPadding,
					1,
					config.separatorColor:ToRaylib(0)
				)
				itemY = itemY + 7
			elseif item.type == "category" then
				raylib.lib.DrawTextEx(
					config.Font,
					string.upper(item.label),
					vector.create(
						x + config.leftPadding + config.iconWidth,
						itemY + (config.categoryHeight - config.categoryFontSize) / 2
					),
					config.categoryFontSize,
					1,
					config.categoryColor:ToRaylib(0)
				)
				itemY = itemY + config.categoryHeight
			else
				if item.appearif and not item.appearif() then
					continue
				end

				local itemRect = rect.new(x + 4, itemY, menuW - 8, config.itemHeight)
				local isHovered = rect.MouseIsInRect(itemRect) and not item.disabled
				local isDanger = item.danger == true

				if isHovered then
					local hov = isDanger and config.dangerHoverColor or config.hoverColor
					raylib.lib.DrawRectangleRounded(
						rect:translate(itemRect),
						config.itemRounded[1],
						config.itemRounded[2],
						hov:ToRaylib(0)
					)
				end

				local textColor = item.disabled and config.disabledColor
					or (isDanger and config.dangerColor)
					or config.textColor

				local iconX = x + config.leftPadding
				local labelX = iconX + config.iconWidth
				local midY = itemY + (config.itemHeight - config.fontSize) / 2

				if item.checked then
					raylib.lib.DrawTextEx(
						config.Font,
						"✓",
						vector.create(iconX, midY),
						config.fontSize,
						1,
						config.checkColor:ToRaylib(0)
					)
				elseif item.icon then
					raylib.lib.DrawTextEx(
						config.Font,
						item.icon,
						vector.create(iconX, midY),
						config.fontSize,
						1,
						textColor:ToRaylib(item.disabled and 0.4 or 0.3)
					)
				end

				raylib.lib.DrawTextEx(
					config.Font,
					item.label,
					vector.create(labelX, midY),
					config.fontSize,
					1,
					textColor:ToRaylib(0)
				)

				if item.shortcut then
					local shortcutSize = raylib.lib.MeasureTextEx(config.Font, item.shortcut, config.fontSize, 1)
					raylib.lib.DrawTextEx(
						config.Font,
						item.shortcut,
						vector.create(
							x + menuW - config.rightPadding - shortcutSize.x - (item.submenu and 16 or 0),
							midY
						),
						config.fontSize,
						1,
						config.shortcutColor:ToRaylib(0)
					)
				end

				if item.submenu then
					raylib.lib.DrawTextEx(
						config.Font,
						"›",
						vector.create(x + menuW - config.rightPadding - 10, midY),
						config.fontSize + 2,
						1,
						config.shortcutColor:ToRaylib(0)
					)
				end

				if isHovered and item.submenu then
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
					local submenuHeight = calculateHeight(item.submenu)
					local submenuRect = rect.new(x + menuW - 2, itemY, menuW, submenuHeight)
					table.insert(config.submenuRects, submenuRect)
					drawPanel(submenuRect.x, submenuRect.y, submenuRect.width, submenuRect.height)
					drawItems(item.submenu, submenuRect.x, submenuRect.y, submenuRect.width, depth + 1)
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

	wrapper.enable = function(k)
		for i, item in ipairs(config.items) do
			if i == k or item.label == k then
				item.disabled = false
				break
			end
		end
		return wrapper
	end

	wrapper.disable = function(k)
		for i, item in ipairs(config.items) do
			if i == k or item.label == k then
				item.disabled = true
				break
			end
		end
		return wrapper
	end

	wrapper.check = function(k)
		for i, item in ipairs(config.items) do
			if i == k or item.label == k then
				item.checked = true
				break
			end
		end
		return wrapper
	end

	wrapper.uncheck = function(k)
		for i, item in ipairs(config.items) do
			if i == k or item.label == k then
				item.checked = false
				break
			end
		end
		return wrapper
	end

	wrapper.render = function(dt)
		if not config.visible then
			return
		end

		config.animAlpha = config.animAlpha + (1 - config.animAlpha) * 0.2
		config.submenuRects = {}

		local menuHeight = calculateHeight(config.items)
		local r = rect.new(config.obj_rect.x, config.obj_rect.y, config.obj_rect.width, menuHeight)
		table.insert(config.submenuRects, r)

		drawPanel(r.x, r.y, r.width, r.height)
		drawItems(config.items, r.x, r.y, r.width, 1)
	end

	table.insert(objects, wrapper)
	return wrapper
end
