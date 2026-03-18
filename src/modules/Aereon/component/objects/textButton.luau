local raylib = require("@raylib")
local structs = raylib.structs
local color3 = require("@datatypes/Color3")
local rect = require("@arect")(raylib.lib)

local function c3tr(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

return function(objects, data)
	local config = {
		obj_rect = rect.new(
			data.x or data[1] or 0,
			data.y or data[2] or 0,
			data.width or data[3] or 100,
			data.height or data[4] or 32
		),
		text = data.text or "Button",
		font = data.font,
		fontSize = data.fontSize or 18,
		backgroundColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
		hoverColor = data.hoverColor or color3.new(0.3, 0.3, 0.3),
		pressColor = data.pressColor or color3.new(0.15, 0.15, 0.15),
		textColor = data.textColor or color3.new(1, 1, 1),
		rounded = data.rounded or { 0.3, 8 },
		onClick = data.onClick,
		currentColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		config[prop] = value
		return wrapper
	end

	wrapper.get = function(prop)
		return config[prop]
	end

	wrapper.get_rect = function()
		return config.obj_rect
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local isHovered = rect.MouseIsInRect(r)
		local isPressed = isHovered and raylib.lib.IsMouseButtonDown(0) == 1

		local targetColor = config.backgroundColor
		if isPressed then
			targetColor = config.pressColor
		elseif isHovered then
			targetColor = config.hoverColor
		end

		config.currentColor = color3.new(
			config.currentColor.R + (targetColor.R - config.currentColor.R) * 0.2,
			config.currentColor.G + (targetColor.G - config.currentColor.G) * 0.2,
			config.currentColor.B + (targetColor.B - config.currentColor.B) * 0.2
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.currentColor, 0)
		)

		local textWidth
		if config.font then
			textWidth = raylib.lib.MeasureTextEx(config.font, config.text, config.fontSize, 1).x
		else
			textWidth = raylib.lib.MeasureText(config.text, config.fontSize)
		end

		local textX = r.x + (r.width - textWidth) / 2
		local textY = r.y + (r.height - config.fontSize) / 2

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.text,
				vector.create(textX, textY),
				config.fontSize,
				1,
				c3tr(config.textColor, 0)
			)
		else
			raylib.lib.DrawText(config.text, textX, textY, config.fontSize, c3tr(config.textColor, 0))
		end

		if isHovered and raylib.lib.IsMouseButtonReleased(0) == 1 and config.onClick then
			config.onClick()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
