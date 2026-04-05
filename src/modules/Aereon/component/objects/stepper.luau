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
		steps = data.steps or 3,
		currentStep = data.currentStep or 1,
		size = data.size or 30,
		spacing = data.spacing or 60,
		font = data.font or defaultFont,
		fontSpacing = data.fontSpacing or 1,
		activeColor = data.activeColor or color3.new(0.02, 0.5, 1),
		inactiveColor = data.inactiveColor or color3.new(0.3, 0.3, 0.3),
		textColor = data.textColor or color3.new(1, 1, 1),
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.setStep = function(step)
		config.currentStep = math.clamp(step, 1, config.steps)
		return wrapper
	end

	wrapper.render = function(dt)
		for i = 1, config.steps do
			local stepX = config.x + (i - 1) * config.spacing
			local stepY = config.y
			local isActive = i <= config.currentStep
			local stepColor = isActive and config.activeColor or config.inactiveColor

			if i < config.steps then
				raylib.lib.DrawRectangle(
					stepX + config.size,
					stepY + config.size / 2 - 1,
					config.spacing - config.size,
					2,
					c3tr(stepColor, 0)
				)
			end

			raylib.lib.DrawCircleV(
				vector.create(stepX + config.size / 2, stepY + config.size / 2),
				config.size / 2,
				c3tr(stepColor, 0)
			)

			local stepText = tostring(i)
			local fontSize = config.size / 2
			local textWidth = raylib.lib.MeasureTextEx(config.font, stepText, fontSize, config.fontSpacing).x
			raylib.lib.DrawTextEx(
				config.font,
				stepText,
				vector.create(stepX + config.size / 2 - textWidth / 2, stepY + config.size / 2 - fontSize / 2),
				fontSize,
				config.fontSpacing,
				c3tr(config.textColor, 0)
			)
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
