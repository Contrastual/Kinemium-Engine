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
			data.size or data[3] or 40,
			data.size or data[4] or 40
		),
		icon = data.icon,
		backgroundColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
		hoverColor = data.hoverColor or color3.new(0.3, 0.3, 0.3),
		pressColor = data.pressColor or color3.new(0.15, 0.15, 0.15),
		onClick = data.onClick,
		currentColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
	}

	local wrapper = {}

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

		raylib.lib.DrawRectangleRounded(rect:translate(r), 0.5, 8, c3tr(config.currentColor, 0))

		if config.icon then
			local iconSize = r.width * 0.6
			local iconX = r.x + (r.width - iconSize) / 2
			local iconY = r.y + (r.height - iconSize) / 2

			raylib.lib.DrawTexturePro(
				config.icon.texture,
				structs.Rectangle:new({ x = 0, y = 0, width = config.icon.x, height = config.icon.y }),
				structs.Rectangle:new({ x = iconX, y = iconY, width = iconSize, height = iconSize }),
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
		end

		if isHovered and raylib.lib.IsMouseButtonReleased(0) == 1 and config.onClick then
			config.onClick()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
