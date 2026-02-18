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
			data.size or data[3] or 20,
			data.size or data[4] or 20
		),
		value = data.value or false,
		onChanged = data.onChanged,
		boxColor = data.boxColor or color3.new(0.2, 0.2, 0.2),
		checkColor = data.checkColor or color3.new(0.02, 0.5, 1),
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

		raylib.lib.DrawRectangleRounded(rect:translate(r), 0.2, 8, config.boxColor:ToRaylib(0))
		raylib.lib.DrawRectangleRoundedLinesEx(rect:translate(r), 0.2, 8, 1, config.checkColor:ToRaylib(0))

		if config.animProgress > 0.01 then
			local innerRect = rect.new(r.x, r.y, r.width, r.height)

			local scale = config.animProgress
			local scaledWidth = innerRect.width * scale
			local scaledHeight = innerRect.height * scale
			local offsetX = (innerRect.width - scaledWidth) / 2
			local offsetY = (innerRect.height - scaledHeight) / 2

			local scaledRect = rect.new(innerRect.x + offsetX, innerRect.y + offsetY, scaledWidth, scaledHeight)

			raylib.lib.DrawRectangleRounded(rect:translate(scaledRect), 0.3, 8, config.checkColor:ToRaylib(0))
		end

		if rect.MouseIsInRect(r) and raylib.lib.IsMouseButtonReleased(0) == 1 then
			config.value = not config.value
			if config.onChanged then
				config.onChanged(config.value)
			end
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
