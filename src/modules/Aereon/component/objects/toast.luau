local raylib = require("@raylib")
local structs = raylib.structs
local color3 = require("@Color3")
local rect = require("@arect")



return function(objects, data)
	local config = {
		message = data.message or "Notification",
		type = data.type or "info", -- "info", "success", "warning", "error"
		duration = data.duration or 3,
		elapsed = 0,
		isClosing = false,
		alpha = 0,
		targetAlpha = 1,

		-- Layout (Toasts usually appear in a corner)
		width = data.width or 250,
		height = data.height or 60,
		padding = 12,

		x = data.x or 0,
		y = data.y or 0,

		-- Colors
		colors = {
			info = color3.new(0.1, 0.5, 1),
			success = color3.new(0.2, 0.8, 0.2),
			warning = color3.new(1, 0.7, 0),
			error = color3.new(1, 0.2, 0.2),
			background = color3.new(0.08, 0.08, 0.1),
			text = color3.new(1, 1, 1),
		},
	}

	local wrapper = {}

	wrapper.close = function()
		config.isClosing = true
		config.targetAlpha = 0
	end

	wrapper.render = function(dt)
		config.elapsed = config.elapsed + dt

		-- Animate alpha
		config.alpha = config.alpha + (config.targetAlpha - config.alpha) * 10 * dt

		if config.elapsed >= config.duration and not config.isClosing then
			wrapper.close()
		end

		if config.isClosing and config.alpha < 0.01 then
			-- Mark for removal
			for i, v in ipairs(objects) do
				if v == wrapper then
					table.remove(objects, i)
					break
				end
			end
			return
		end

		local drawAlpha = 1 - config.alpha
		local r = rect.new(config.x, config.y, config.width, config.height)

		-- Background with drop shadow effect
		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(config.x + 4, config.y + 4, config.width, config.height)),
			0.2,
			8,
			color3.new(0:ToRaylib(0, 0), 0.8 + 0.2 * drawAlpha)
		)

		raylib.lib.DrawRectangleRounded(rect:translate(r), 0.2, 8, config.colors.background:ToRaylib(drawAlpha))

		-- Type indicator bar
		local typeColor = config.colors[config.type] or config.colors.info
		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(config.x, config.y, 6, config.height)),
			0.2,
			8,
			typeColor:ToRaylib(drawAlpha)
		)

		-- Icon (simplified representation)
		local iconX = config.x + config.padding + 10
		local iconY = config.y + config.height / 2
		raylib.lib.DrawCircle(iconX, iconY, 6, typeColor:ToRaylib(drawAlpha))

		-- Text
		raylib.lib.DrawText(
			config.message,
			iconX + 20,
			config.y + (config.height - 16) / 2,
			16,
			config.colors.text:ToRaylib(drawAlpha)
		)

		-- Progress bar (timer)
		if not config.isClosing then
			local progress = 1 - (config.elapsed / config.duration)
			raylib.lib.DrawRectangle(
				config.x + 10,
				config.y + config.height - 4,
				(config.width - 20) * progress,
				2,
				typeColor:ToRaylib(drawAlpha)
			)
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
