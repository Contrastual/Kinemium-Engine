local raylib = require("@raylib")
local structs = raylib.structs
local color3 = require("@Color3")
local rect = require("@arect")(raylib.lib)
local LayoutEngine = require("@LayoutEngine")

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
		obj_rect = rect.new(
			data.x or data[1] or 0,
			data.y or data[2] or 0,
			data.width or data[3] or 120,
			data.height or data[4] or 32
		),
		text = data.text or "Button",
		icon = data.icon,
		font = data.font,
		fontSize = data.fontSize or 16,
		iconPosition = data.iconPosition or "left", -- "left" or "right"
		gap = data.gap or 8,
		padding = data.padding or { left = 12, right = 12, top = 0, bottom = 0 },

		backgroundColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
		hoverColor = data.hoverColor or color3.new(0.3, 0.3, 0.3),
		pressColor = data.pressColor or color3.new(0.15, 0.15, 0.15),
		textColor = data.textColor or color3.new(1, 1, 1),
		rounded = data.rounded or { 0.3, 8 },

		onClick = data.onClick,
		currentColor = data.backgroundColor or color3.new(0.2, 0.2, 0.2),
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		config[prop] = value
		return wrapper
	end

	wrapper.get = function(prop)
		return config[prop]
	end

	wrapper.get_rect = function()
		return config.obj_rect
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local isHovered = rect.MouseIsInRect(r)
		local isPressed = isHovered and raylib.lib.IsMouseButtonDown(0) == 1

		local targetColor = config.backgroundColor
		if isPressed then
			targetColor = config.pressColor
		elseif isHovered then
			targetColor = config.hoverColor
		end

		config.currentColor = color3.new(
			config.currentColor.R + (targetColor.R - config.currentColor.R) * 0.2,
			config.currentColor.G + (targetColor.G - config.currentColor.G) * 0.2,
			config.currentColor.B + (targetColor.B - config.currentColor.B) * 0.2
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.currentColor, 0)
		)

		-- Layout Internal Parts
		local textWidth
		if config.font then
			textWidth = raylib.lib.MeasureTextEx(config.font, config.text, config.fontSize, 1).x
		else
			textWidth = raylib.lib.MeasureText(config.text, config.fontSize)
		end

		local iconSize = config.icon and (r.height * 0.6) or 0

		local layoutItems = {
			LayoutEngine.createItem(
				"icon",
				iconSize,
				iconSize,
				{ layoutOrder = config.iconPosition == "left" and 1 or 2 }
			),
			LayoutEngine.createItem(
				"text",
				textWidth,
				config.fontSize,
				{ layoutOrder = config.iconPosition == "left" and 2 or 1 }
			),
		}

		local containerData = {
			width = r.width,
			height = r.height,
			direction = LayoutEngine.Direction.Row,
			justifyContent = LayoutEngine.JustifyContent.Center,
			alignItems = LayoutEngine.AlignItems.Center,
			gap = config.gap,
			padding = config.padding,
		}

		LayoutEngine.calculate(containerData, layoutItems)

		local function get_item(id)
			for _, it in ipairs(layoutItems) do
				if it.id == id then
					return it
				end
			end
			return nil
		end

		-- Render Icon
		if config.icon then
			local itIcon = get_item("icon")
			local iconX = r.x + itIcon._x
			local iconY = r.y + itIcon._y

			raylib.lib.DrawTexturePro(
				config.icon.texture,
				structs.Rectangle:new({ x = 0, y = 0, width = config.icon.x, height = config.icon.y }),
				structs.Rectangle:new({ x = iconX, y = iconY, width = iconSize, height = iconSize }),
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
		end

		-- Render Text
		local itText = get_item("text")
		local textX = r.x + itText._x
		local textY = r.y + itText._y

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.text,
				vector.create(textX, textY),
				config.fontSize,
				1,
				c3tr(config.textColor, 0)
			)
		else
			raylib.lib.DrawText(config.text, textX, textY, config.fontSize, c3tr(config.textColor, 0))
		end

		if isHovered and raylib.lib.IsMouseButtonReleased(0) == 1 and config.onClick then
			config.onClick()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
