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

return function(objects, data)
	local config = {
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4]),
		h = 0,
		s = 1,
		v = 1,
		a = 1,
		dragging = nil, -- "sv", "h", "a"
		onChanged = data.onChanged,
		rounded = data.rounded or { 0.1, 8 },
		modifiers = {},

		backgroundColor = color3.new(0.12, 0.12, 0.14),
		backgroundTransparency = 0,

		activeTab = "RGB", -- "RGB" or "HSV"
		recentColors = {}, -- Store recent colors
		maxRecentColors = 12,
	}

	local function updateColor()
		local c = color3.fromHSV(config.h, config.s, config.v)
		if config.onChanged then
			config.onChanged(c, config.a)
		end

		-- Add to recent colors
		local r, g, b = c:ToRGB()
		local newColor = { r = r, g = g, b = b }

		-- Check if color already exists
		local exists = false
		for _, col in ipairs(config.recentColors) do
			if col.r == newColor.r and col.g == newColor.g and col.b == newColor.b then
				exists = true
				break
			end
		end

		if not exists then
			table.insert(config.recentColors, 1, newColor)
			if #config.recentColors > config.maxRecentColors then
				table.remove(config.recentColors)
			end
		end
	end

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.getColor = function()
		return color3.fromHSV(config.h, config.s, config.v)
	end

	wrapper.getAlpha = function()
		return config.a
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mouseDown = raylib.lib.IsMouseButtonDown(0) == 1
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1

		local padding = 16
		local titleHeight = 30
		local sliderWidth = 20
		local spacing = 12
		local hexHeight = 25
		local tabHeight = 35
		local valuesHeight = 80
		local recentHeight = 70

		-- Calculate SV picker size (square)
		local availableHeight = r.height
			- padding * 2
			- titleHeight
			- hexHeight
			- tabHeight
			- valuesHeight
			- recentHeight
			- spacing * 5
		local availableWidth = r.width - padding * 3 - sliderWidth
		local svSize = math.min(availableWidth, availableHeight)

		-- Layout rectangles
		local titleRect = rect.new(r.x + padding, r.y + padding, r.width - padding * 2, titleHeight)
		local svRect = rect.new(r.x + padding, r.y + padding + titleHeight, svSize, svSize)
		local hueRect = rect.new(r.x + padding + svSize + spacing, r.y + padding + titleHeight, sliderWidth, svSize)
		local hexRect = rect.new(
			r.x + padding,
			r.y + padding + titleHeight + svSize + spacing,
			svSize + sliderWidth + spacing,
			hexHeight
		)
		local tabRect = rect.new(
			r.x + padding,
			r.y + padding + titleHeight + svSize + hexHeight + spacing * 2,
			svSize + sliderWidth + spacing,
			tabHeight
		)
		local valuesRect = rect.new(
			r.x + padding,
			r.y + padding + titleHeight + svSize + hexHeight + tabHeight + spacing * 3,
			svSize + sliderWidth + spacing,
			valuesHeight
		)
		local recentRect = rect.new(
			r.x + padding,
			r.y + padding + titleHeight + svSize + hexHeight + tabHeight + valuesHeight + spacing * 4,
			svSize + sliderWidth + spacing,
			recentHeight
		)

		-- Background
		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, config.backgroundTransparency)
		)

		-- Title
		raylib.lib.DrawText("Color Palette", titleRect.x, titleRect.y + 5, 14, c3tr(color3.new(0.86, 0.86, 0.86), 0))

		-- Handle dragging
		if mouseDown then
			if not config.dragging then
				if rect.MouseIsInRect(svRect) then
					config.dragging = "sv"
				elseif rect.MouseIsInRect(hueRect) then
					config.dragging = "h"
				end
			end

			if config.dragging == "sv" then
				config.s = math.clamp((mousePos.x - svRect.x) / svRect.width, 0, 1)
				config.v = 1 - math.clamp((mousePos.y - svRect.y) / svRect.height, 0, 1)
				updateColor()
			elseif config.dragging == "h" then
				config.h = 1 - math.clamp((mousePos.y - hueRect.y) / hueRect.height, 0, 1)
				updateColor()
			end
		else
			config.dragging = nil
		end

		-- SV Picker with gradients
		local baseColor = color3.fromHSV(config.h, 1, 1)
		raylib.lib.DrawRectangleRounded(rect:translate(svRect), 0.05, 8, c3tr(baseColor, 0))

		-- Saturation gradient (white to transparent)
		raylib.lib.DrawRectangleGradientH(
			svRect.x,
			svRect.y,
			svRect.width,
			svRect.height,
			c3tr(color3.new(1, 1, 1), 0),
			c3tr(color3.new(1, 1, 1), 1)
		)

		-- Value gradient (transparent to black)
		raylib.lib.DrawRectangleGradientV(
			svRect.x,
			svRect.y,
			svRect.width,
			svRect.height,
			c3tr(color3.new(0, 0, 0), 1),
			c3tr(color3.new(0, 0, 0), 0)
		)

		local cursorX = svRect.x + config.s * svRect.width
		local cursorY = svRect.y + (1 - config.v) * svRect.height
		raylib.lib.DrawCircleV(vector.create(cursorX, cursorY), 8, c3tr(color3.new(1, 1, 1), 0))
		raylib.lib.DrawCircleV(
			vector.create(cursorX, cursorY),
			6,
			c3tr(color3.fromHSV(config.h, config.s, config.v), 0)
		)

		raylib.lib.DrawRectangleRounded(rect:translate(hueRect), 0.3, 8, c3tr(color3.new(0.08, 0.08, 0.1), 0))

		for i = 0, hueRect.height - 1 do
			local hue = 1 - (i / hueRect.height)
			raylib.lib.DrawRectangle(
				hueRect.x + 2,
				hueRect.y + i,
				hueRect.width - 4,
				1,
				c3tr(color3.fromHSV(hue, 1, 1), 0)
			)
		end

		local hueY = hueRect.y + (1 - config.h) * hueRect.height
		raylib.lib.DrawCircleV(vector.create(hueRect.x + hueRect.width / 2, hueY), 8, c3tr(color3.new(1, 1, 1), 0))
		raylib.lib.DrawCircleV(
			vector.create(hueRect.x + hueRect.width / 2, hueY),
			6,
			c3tr(color3.fromHSV(config.h, 1, 1), 0)
		)

		local r_val, g_val, b_val = color3.fromHSV(config.h, config.s, config.v):ToRGB()
		local hexText = string.format("#%02x%02x%02x", r_val, g_val, b_val)
		raylib.lib.DrawText(hexText, hexRect.x + 30, hexRect.y + 5, 12, c3tr(color3.new(0.39, 0.59, 1), 0))

		-- Tab buttons
		local rgbTabRect = rect.new(tabRect.x, tabRect.y, 40, 20)
		local hsvTabRect = rect.new(tabRect.x + 70, tabRect.y, 40, 20)

		if mousePressed then
			if rect.MouseIsInRect(rgbTabRect) then
				config.activeTab = "RGB"
			elseif rect.MouseIsInRect(hsvTabRect) then
				config.activeTab = "HSV"
			end
		end

		local rgbColor = config.activeTab == "RGB" and color3.new(0.86, 0.86, 0.86) or color3.new(0.47, 0.47, 0.47)
		local hsvColor = config.activeTab == "HSV" and color3.new(0.86, 0.86, 0.86) or color3.new(0.47, 0.47, 0.47)

		raylib.lib.DrawText("RGB", rgbTabRect.x, rgbTabRect.y, 12, c3tr(rgbColor, 0))
		raylib.lib.DrawText("HSV", hsvTabRect.x, hsvTabRect.y, 12, c3tr(hsvColor, 0))

		-- Values display
		local labelColor = color3.new(0.63, 0.63, 0.63)
		local valueColor = color3.new(0.86, 0.86, 0.86)

		if config.activeTab == "RGB" then
			raylib.lib.DrawText("Red", valuesRect.x, valuesRect.y, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(r_val), valuesRect.x + 60, valuesRect.y, 11, c3tr(valueColor, 0))

			raylib.lib.DrawText("Green", valuesRect.x, valuesRect.y + 20, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(g_val), valuesRect.x + 60, valuesRect.y + 20, 11, c3tr(valueColor, 0))

			raylib.lib.DrawText("Blue", valuesRect.x, valuesRect.y + 40, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(b_val), valuesRect.x + 60, valuesRect.y + 40, 11, c3tr(valueColor, 0))

			raylib.lib.DrawText("Hue", valuesRect.x + 120, valuesRect.y, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.h * 360)),
				valuesRect.x + 180,
				valuesRect.y,
				11,
				c3tr(valueColor, 0)
			)

			raylib.lib.DrawText("Sat...", valuesRect.x + 120, valuesRect.y + 20, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.s * 100)),
				valuesRect.x + 180,
				valuesRect.y + 20,
				11,
				c3tr(valueColor, 0)
			)

			raylib.lib.DrawText("Value", valuesRect.x + 120, valuesRect.y + 40, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.v * 100)),
				valuesRect.x + 180,
				valuesRect.y + 40,
				11,
				c3tr(valueColor, 0)
			)
		else
			raylib.lib.DrawText("Hue", valuesRect.x, valuesRect.y, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.h * 360)),
				valuesRect.x + 60,
				valuesRect.y,
				11,
				c3tr(valueColor, 0)
			)

			raylib.lib.DrawText("Sat...", valuesRect.x, valuesRect.y + 20, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.s * 100)),
				valuesRect.x + 60,
				valuesRect.y + 20,
				11,
				c3tr(valueColor, 0)
			)

			raylib.lib.DrawText("Value", valuesRect.x, valuesRect.y + 40, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(
				tostring(math.floor(config.v * 100)),
				valuesRect.x + 60,
				valuesRect.y + 40,
				11,
				c3tr(valueColor, 0)
			)

			raylib.lib.DrawText("Red", valuesRect.x + 120, valuesRect.y, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(r_val), valuesRect.x + 180, valuesRect.y, 11, c3tr(valueColor, 0))

			raylib.lib.DrawText("Green", valuesRect.x + 120, valuesRect.y + 20, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(g_val), valuesRect.x + 180, valuesRect.y + 20, 11, c3tr(valueColor, 0))

			raylib.lib.DrawText("Blue", valuesRect.x + 120, valuesRect.y + 40, 11, c3tr(labelColor, 0))
			raylib.lib.DrawText(tostring(b_val), valuesRect.x + 180, valuesRect.y + 40, 11, c3tr(valueColor, 0))
		end

		raylib.lib.DrawText("Recent colors", recentRect.x, recentRect.y, 11, c3tr(labelColor, 0))

		local colorSize = 20
		local colorSpacing = 5
		local colorsPerRow = 6

		for i, col in ipairs(config.recentColors) do
			local row = math.floor((i - 1) / colorsPerRow)
			local column = (i - 1) % colorsPerRow
			local cx = recentRect.x + column * (colorSize + colorSpacing)
			local cy = recentRect.y + 20 + row * (colorSize + colorSpacing)

			local colorRect = rect.new(cx, cy, colorSize, colorSize)
			raylib.lib.DrawRectangleRounded(
				rect:translate(colorRect),
				0.15,
				4,
				structs.Color:new({ r = col.r, g = col.g, b = col.b, a = 255 })
			)

			if mousePressed and rect.MouseIsInRect(colorRect) then
				local r_norm, g_norm, b_norm = col.r / 255, col.g / 255, col.b / 255
				local max_val = math.max(r_norm, g_norm, b_norm)
				local min_val = math.min(r_norm, g_norm, b_norm)
				local delta = max_val - min_val

				config.v = max_val
				config.s = max_val == 0 and 0 or delta / max_val

				if delta == 0 then
					config.h = 0
				elseif max_val == r_norm then
					config.h = ((g_norm - b_norm) / delta) % 6
				elseif max_val == g_norm then
					config.h = (b_norm - r_norm) / delta + 2
				else
					config.h = (r_norm - g_norm) / delta + 4
				end
				config.h = (config.h / 6) % 1

				if config.onChanged then
					local c = color3.fromHSV(config.h, config.s, config.v)
					config.onChanged(c, config.a)
				end
			end
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
