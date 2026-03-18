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
		obj_rect = rect.new(
			data.x or data[1],
			data.y or data[2],
			data.size or data[3] or 20,
			data.size or data[4] or 20
		),
		value = data.value or false,
		onChanged = data.onChanged,
		ringColor = data.ringColor or color3.new(0.3, 0.3, 0.3),
		fillColor = data.fillColor or color3.new(0.02, 0.5, 1),
		animProgress = data.value and 1 or 0,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.setValue = function(v)
		config.value = v
	end

	wrapper.getValue = function()
		return config.value
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local targetProgress = config.value and 1 or 0
		config.animProgress = config.animProgress + (targetProgress - config.animProgress) * 0.2

		local centerX = r.x + r.width / 2
		local centerY = r.y + r.height / 2
		local radius = r.width / 2

		raylib.lib.DrawCircleV(vector.create(centerX, centerY), radius, c3tr(config.ringColor, 0))

		if config.animProgress > 0.1 then
			local fillRadius = radius * 0.5 * config.animProgress
			raylib.lib.DrawCircleV(vector.create(centerX, centerY), fillRadius, c3tr(config.fillColor, 0))
		end

		if rect.MouseIsInRect(r) and raylib.lib.IsMouseButtonReleased(0) == 1 then
			config.value = true
			if config.onChanged then
				config.onChanged(config.value)
			end
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
