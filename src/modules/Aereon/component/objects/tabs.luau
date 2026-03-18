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
local color3 = require("@datatypes/Color3")

local defaultFont = raylib.lib.GetFontDefault()

return function(objects, data)
	local config = {
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4] or 40),
		tabs = data.tabs or { "Tab 1", "Tab 2", "Tab 3" },
		activeIndex = data.activeIndex or 1,
		onTabChange = data.onTabChange,
		backgroundColor = data.backgroundColor or color3.new(0.15, 0.15, 0.15),
		activeColor = data.activeColor or color3.new(0.02, 0.5, 1),
		textColor = data.textColor or color3.new(1, 1, 1),
		fontSize = data.fontSize or 16,
		animX = 0,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.setActive = function(index)
		config.activeIndex = math.clamp(index, 1, #config.tabs)
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local tabWidth = r.width / #config.tabs

		raylib.lib.DrawRectangleRounded(rect:translate(r), 0.2, 8, c3tr(config.backgroundColor, 0))

		local targetX = r.x + (config.activeIndex - 1) * tabWidth
		config.animX = config.animX + (targetX - config.animX) * 0.15

		local indicatorRect = rect.new(config.animX, r.y + r.height - 3, tabWidth, 3)
		raylib.lib.DrawRectangle(
			indicatorRect.x,
			indicatorRect.y,
			indicatorRect.width,
			indicatorRect.height,
			c3tr(config.activeColor, 0)
		)

		for i, tab in ipairs(config.tabs) do
			local tabX = r.x + (i - 1) * tabWidth
			local tabRect = rect.new(tabX, r.y, tabWidth, r.height)

			local textWidth = raylib.lib.MeasureText(tab, config.fontSize)
			local textX = tabX + (tabWidth - textWidth) / 2
			local textY = r.y + (r.height - config.fontSize) / 2

			raylib.lib.DrawText(tab, textX, textY, config.fontSize, c3tr(config.textColor, 0))

			if rect.MouseIsInRect(tabRect) and raylib.lib.IsMouseButtonReleased(0) == 1 then
				config.activeIndex = i
				if config.onTabChange then
					config.onTabChange(i, tab)
				end
			end
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
