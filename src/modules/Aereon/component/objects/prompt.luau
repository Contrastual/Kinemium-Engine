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
			data.x or data[1] or 0,
			data.y or data[2] or 0,
			data.width or data[3] or 600,
			data.height or data[4] or 200
		),
		title = data.title or "Prompt",
		message = data.message or "",
		visible = data.visible ~= false,

		backgroundColor = data.backgroundColor or color3.new(0.08, 0.1, 0.12),
		titleColor = data.titleColor or color3.new(1, 1, 1),
		messageColor = data.messageColor or color3.new(0.8, 0.8, 0.8),

		titleFontSize = data.titleFontSize or 24,
		messageFontSize = data.messageFontSize or 14,

		padding = data.padding or 24,
		rounded = data.rounded or { 0.08, 12 },

		buttons = data.buttons or {
			{ text = "OK", onClick = nil, color = color3.new(0.02, 0.5, 1) },
		},
		buttonHeight = data.buttonHeight or 40,
		buttonSpacing = data.buttonSpacing or 12,

		bodyRenderer = data.bodyRenderer, -- function(x, y, width, height)
		bodyHeight = data.bodyHeight or 0,

		showCloseButton = data.showCloseButton ~= false,
		onClose = data.onClose,

		animScale = 0,
		animAlpha = 0,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.show = function()
		config.visible = true
		config.animScale = 0
		config.animAlpha = 0
		return wrapper
	end

	wrapper.hide = function()
		config.visible = false
		return wrapper
	end

	wrapper.setBodyRenderer = function(renderer)
		config.bodyRenderer = renderer
		return wrapper
	end

	wrapper.setButtons = function(buttons)
		config.buttons = buttons
		return wrapper
	end

	wrapper.render = function(dt)
		if not config.visible then
			return
		end

		config.animScale = config.animScale + (1 - config.animScale) * 0.2
		config.animAlpha = config.animAlpha + (1 - config.animAlpha) * 0.2

		local screenWidth = raylib.lib.GetScreenWidth()
		local screenHeight = raylib.lib.GetScreenHeight()

		local promptX = config.obj_rect.x
		local promptY = config.obj_rect.y
		if config.obj_rect.x == 0 and config.obj_rect.y == 0 then
			promptX = (screenWidth - config.obj_rect.width) / 2
			promptY = (screenHeight - config.obj_rect.height) / 2
		end

		local scaledWidth = config.obj_rect.width * config.animScale
		local scaledHeight = config.obj_rect.height * config.animScale
		local scaledX = promptX + (config.obj_rect.width - scaledWidth) / 2
		local scaledY = promptY + (config.obj_rect.height - scaledHeight) / 2

		local promptRect = rect.new(scaledX, scaledY, scaledWidth, scaledHeight)

		local shadowOffset = 4
		raylib.lib.DrawRectangleRounded(
			rect:translate(
				rect.new(promptRect.x + shadowOffset, promptRect.y + shadowOffset, promptRect.width, promptRect.height)
			),
			config.rounded[1],
			config.rounded[2],
			c3tr(color3.new(0, 0, 0), 0.85)
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(promptRect),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		if config.showCloseButton then
			local closeSize = 32
			local closeX = promptRect.x + promptRect.width - config.padding - closeSize
			local closeY = promptRect.y + config.padding
			local closeRect = rect.new(closeX, closeY, closeSize, closeSize)

			local isCloseHovered = rect.MouseIsInRect(closeRect)
			if isCloseHovered then
				raylib.lib.DrawRectangleRounded(rect:translate(closeRect), 0.3, 8, c3tr(color3.new(0.3, 0.3, 0.3), 0))
			end

			local lineOffset = 8
			raylib.lib.DrawLine(
				closeX + lineOffset,
				closeY + lineOffset,
				closeX + closeSize - lineOffset,
				closeY + closeSize - lineOffset,
				c3tr(config.titleColor, 0)
			)
			raylib.lib.DrawLine(
				closeX + closeSize - lineOffset,
				closeY + lineOffset,
				closeX + lineOffset,
				closeY + closeSize - lineOffset,
				c3tr(config.titleColor, 0)
			)

			if isCloseHovered and raylib.lib.IsMouseButtonReleased(0) == 1 then
				if config.onClose then
					config.onClose()
				end
				wrapper.hide()
			end
		end

		local contentY = promptRect.y + config.padding

		if config.title ~= "" then
			raylib.lib.DrawTextEx(
				defaultFont,
				config.title,
				vector.create(promptRect.x + config.padding, contentY),
				config.titleFontSize,
				1,
				c3tr(config.titleColor, 0)
			)
			contentY = contentY + config.titleFontSize + 16
		end

		if config.message ~= "" then
			raylib.lib.DrawTextEx(
				defaultFont,
				config.message,
				vector.create(promptRect.x + config.padding, contentY),
				config.messageFontSize,
				1,
				c3tr(config.messageColor, 0)
			)
			contentY = contentY + config.messageFontSize + 20
		end

		if config.bodyRenderer then
			local bodyWidth = promptRect.width - config.padding * 2
			local bodyHeight = config.bodyHeight > 0 and config.bodyHeight
				or (
					promptRect.height
					- (contentY - promptRect.y)
					- config.padding
					- config.buttonHeight
					- config.buttonSpacing
				)

			config.bodyRenderer(dt, promptRect.x + config.padding, contentY, bodyWidth, bodyHeight)
			contentY = contentY + bodyHeight + config.buttonSpacing
		end

		-- Draw buttons
		local totalButtonWidth = 0
		for i, button in ipairs(config.buttons) do
			local btnWidth = button.width or 100
			totalButtonWidth = totalButtonWidth + btnWidth
			if i < #config.buttons then
				totalButtonWidth = totalButtonWidth + config.buttonSpacing
			end
		end

		local buttonY = promptRect.y + promptRect.height - config.padding - config.buttonHeight
		local buttonX = promptRect.x + promptRect.width - config.padding - totalButtonWidth

		for i, button in ipairs(config.buttons) do
			local btnWidth = button.width or 100
			local btnRect = rect.new(buttonX, buttonY, btnWidth, config.buttonHeight)

			local isHovered = rect.MouseIsInRect(btnRect)
			local btnColor = button.color or color3.new(0.3, 0.3, 0.3)
			local hoverColor =
				color3.new(math.min(btnColor.R + 0.1, 1), math.min(btnColor.G + 0.1, 1), math.min(btnColor.B + 0.1, 1))

			raylib.lib.DrawRectangleRounded(
				rect:translate(btnRect),
				0.3,
				8,
				c3tr(isHovered and hoverColor or btnColor, 0)
			)

			local textSize = raylib.lib.MeasureTextEx(defaultFont, button.text, 16, 1)
			local textX = buttonX + (btnWidth - textSize.x) / 2
			local textY = buttonY + (config.buttonHeight - textSize.y) / 2

			raylib.lib.DrawTextEx(
				defaultFont,
				button.text,
				vector.create(textX, textY),
				16,
				1,
				c3tr(color3.new(1, 1, 1), 0)
			)

			if isHovered and raylib.lib.IsMouseButtonReleased(0) == 1 then
				if button.onClick then
					button.onClick()
				end
				wrapper.hide()
			end

			buttonX = buttonX + btnWidth + config.buttonSpacing
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
