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

local color3 = require("@Color3")

local defaultFont = raylib.lib.GetFontDefault()

return function(objects, data)
	local config = {
		x = data.x or data[1],
		y = data.y or data[2],
		text = data.text or "Label",
		fontSize = data.fontSize or 18,
		color = data.color or color3.new(1, 1, 1),
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.setText = function(t)
		config.text = t
	end

	wrapper.render = function(dt)
		raylib.lib.DrawText(config.text, config.x, config.y, config.fontSize, c3tr(config.color, 0))
	end

	table.insert(objects, wrapper)
	return wrapper
end
