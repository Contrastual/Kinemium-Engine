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
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4]),
		backgroundColor = data.backgroundColor or color3.new(0.15, 0.15, 0.15),
		shadowColor = data.shadowColor or color3.new(0, 0, 0),
		elevation = data.elevation or 4,
		rounded = data.rounded or { 0.15, 8 },
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.render = function(dt)
		local r = config.obj_rect

		for i = config.elevation, 1, -1 do
			local shadowOffset = i * 0.5
			local shadowRect = rect.new(r.x + shadowOffset, r.y + shadowOffset, r.width, r.height)
			raylib.lib.DrawRectangleRounded(
				rect:translate(shadowRect),
				config.rounded[1],
				config.rounded[2],
				c3tr(config.shadowColor, 0.9 + (i / config.elevation) * 0.1)
			)
		end

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)
	end

	table.insert(objects, wrapper)
	return wrapper
end
