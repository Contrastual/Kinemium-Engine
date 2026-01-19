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
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4] or 30),
		options = data.options or { "Option 1", "Option 2", "Option 3" },
		selectedIndex = data.selectedIndex or 1,
		expanded = false,
		backgroundColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
		hoverColor = data.hoverColor or color3.new(0.3, 0.3, 0.3),
		textColor = data.textColor or color3.new(1, 1, 1),
		fontSize = data.fontSize or 18,
		onSelect = data.onSelect,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.setSelected = function(index)
		config.selectedIndex = math.clamp(index, 1, #config.options)
	end

	wrapper.getSelected = function()
		return config.selectedIndex, config.options[config.selectedIndex]
	end

	wrapper.render = function(dt)
		local r = config.obj_rect

		raylib.lib.DrawRectangleRounded(rect:translate(r), 0.2, 8, c3tr(config.backgroundColor, 0))

		local selectedText = config.options[config.selectedIndex] or "Select..."
		local textX = r.x + 8
		local textY = r.y + (r.height - config.fontSize) / 2

		raylib.lib.DrawText(selectedText, textX, textY, config.fontSize, c3tr(config.textColor, 0))

		local arrowSize = 8
		local arrowX = r.x + r.width - arrowSize - 8
		local arrowY = r.y + r.height / 2
		if config.expanded then
			raylib.lib.DrawTriangle(
				vector.create(arrowX, arrowY + arrowSize / 2),
				vector.create(arrowX + arrowSize, arrowY + arrowSize / 2),
				vector.create(arrowX + arrowSize / 2, arrowY - arrowSize / 2),
				c3tr(config.textColor, 0)
			)
		else
			raylib.lib.DrawTriangle(
				vector.create(arrowX, arrowY - arrowSize / 2),
				vector.create(arrowX + arrowSize, arrowY - arrowSize / 2),
				vector.create(arrowX + arrowSize / 2, arrowY + arrowSize / 2),
				c3tr(config.textColor, 0)
			)
		end

		if rect.MouseIsInRect(r) and raylib.lib.IsMouseButtonReleased(0) == 1 then
			config.expanded = not config.expanded
		end

		if config.expanded then
			local itemHeight = r.height
			local listHeight = itemHeight * #config.options
			local listY = r.y + r.height + 2

			raylib.lib.DrawRectangleRounded(
				structs.Rectangle:new({ x = r.x, y = listY, width = r.width, height = listHeight }),
				0.2,
				8,
				c3tr(config.backgroundColor, 0)
			)

			for i, option in ipairs(config.options) do
				local itemY = listY + (i - 1) * itemHeight
				local itemRect = rect.new(r.x, itemY, r.width, itemHeight)

				if rect.MouseIsInRect(itemRect) then
					raylib.lib.DrawRectangle(
						itemRect.x,
						itemRect.y,
						itemRect.width,
						itemRect.height,
						c3tr(config.hoverColor, 0)
					)

					if raylib.lib.IsMouseButtonReleased(0) == 1 then
						config.selectedIndex = i
						config.expanded = false
						if config.onSelect then
							config.onSelect(i, option)
						end
					end
				end

				raylib.lib.DrawText(
					option,
					r.x + 8,
					itemY + (itemHeight - config.fontSize) / 2,
					config.fontSize,
					c3tr(config.textColor, 0)
				)
			end
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
