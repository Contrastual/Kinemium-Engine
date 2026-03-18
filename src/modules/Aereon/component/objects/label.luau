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
		obj_rect = rect.new(data.x or data[1] or 0, data.y or data[2] or 0, 0, data.fontSize or 18),
		text = data.text or "Label",
		font = data.font or raylib.lib.GetFontDefault(),
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

	wrapper.get = function(prop)
		return config[prop]
	end

	wrapper.get_rect = function()
		if config.obj_rect.width == 0 then
			-- Calculate width if it hasn't been set
			config.obj_rect.width = raylib.lib.MeasureText(config.text, config.fontSize)
		end
		return config.obj_rect
	end

	wrapper.setText = function(t)
		config.text = t
		config.obj_rect.width = 0
	end

	wrapper.render = function(dt)
		local r = wrapper.get_rect()
		raylib.lib.DrawTextEx(
			config.font,
			config.text,
			vector.create(r.x, r.y),
			config.fontSize,
			2,
			c3tr(config.color, 0)
		)
	end

	table.insert(objects, wrapper)
	return wrapper
end
