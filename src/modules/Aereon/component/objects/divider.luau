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
		x = data.x or data[1],
		y = data.y or data[2],
		width = data.width or data[3],
		vertical = data.vertical or false,
		height = data.height or data[4] or 1,
		color = data.color or color3.new(0.3, 0.3, 0.3),
	}

	local wrapper = {}

	wrapper.render = function(dt)
		if config.vertical then
			raylib.lib.DrawRectangle(config.x, config.y, config.height, config.width, c3tr(config.color, 0))
		else
			raylib.lib.DrawRectangle(config.x, config.y, config.width, config.height, c3tr(config.color, 0))
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
