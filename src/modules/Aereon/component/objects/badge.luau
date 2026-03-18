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
		x = data.x or data[1],
		y = data.y or data[2],
		text = data.text or "1",
		fontSize = data.fontSize or 12,
		backgroundColor = data.backgroundColor or color3.new(1, 0.2, 0.2),
		textColor = data.textColor or color3.new(1, 1, 1),
		minWidth = data.minWidth or 18,
	}

	local wrapper = {}

	wrapper.setText = function(t)
		config.text = t
	end

	wrapper.render = function(dt)
		local textWidth = raylib.lib.MeasureText(config.text, config.fontSize)
		local badgeWidth = math.max(config.minWidth, textWidth + 8)
		local badgeHeight = config.fontSize + 6

		local badgeRect = rect.new(config.x, config.y, badgeWidth, badgeHeight)

		raylib.lib.DrawRectangleRounded(rect:translate(badgeRect), 0.5, 8, c3tr(config.backgroundColor, 0))

		local textX = config.x + (badgeWidth - textWidth) / 2
		local textY = config.y + 3

		raylib.lib.DrawText(config.text, textX, textY, config.fontSize, c3tr(config.textColor, 0))
	end

	table.insert(objects, wrapper)
	return wrapper
end
