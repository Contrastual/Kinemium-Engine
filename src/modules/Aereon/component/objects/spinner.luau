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
		radius = data.radius or data[3] or 20,
		color = data.color or color3.new(0.02, 0.5, 1),
		thickness = data.thickness or 3,
		rotation = 0,
	}

	local wrapper = {}

	wrapper.render = function(dt)
		config.rotation = config.rotation + dt * 180
		if config.rotation >= 360 then
			config.rotation = config.rotation - 360
		end

		raylib.lib.DrawRing(
			vector.create(config.x, config.y),
			config.radius - config.thickness,
			config.radius,
			config.rotation,
			config.rotation + 270,
			32,
			c3tr(config.color, 0)
		)
	end

	table.insert(objects, wrapper)
	return wrapper
end
