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

		font = data.font or defaultFont,
		backgroundColor = data.backgroundColor or color3.new(0.12, 0.13, 0.15),
		overlayColor = data.overlayColor or color3.new(0, 0, 0),
		titleColor = data.titleColor or color3.new(0.95, 0.95, 0.97),
		messageColor = data.messageColor or color3.new(0.7, 0.72, 0.75),
		borderColor = data.borderColor or color3.new(0.22, 0.23, 0.26),

		titleFontSize = data.titleFontSize or 22,
		messageFontSize = data.messageFontSize or 15,

		padding = data.padding or 28,
		rounded = data.rounded or { 0.12, 10 },

		buttons = data.buttons or {
			{ text = "OK", onClick = nil, color = color3.new(0.2, 0.5, 0.9) },
		},
		buttonHeight = data.buttonHeight or 42,
		buttonSpacing = data.buttonSpacing or 10,

		bodyRenderer = data.bodyRenderer,
		bodyHeight = data.bodyHeight or 0,

		showCloseButton = data.showCloseButton ~= false,
		onClose = data.onClose,

		animScale = 0,
		animAlpha = 0,
		animSlideY = 0, -- 0 = off screen bottom, 1 = centered
		closeButtonHover = 0,
		buttonHoverStates = {},
		isClosing = false,
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
		config.isClosing = false
		config.animScale = 0
		config.animAlpha = 0
		config.animSlideY = 0
		return wrapper
	end

	wrapper.hide = function()
		config.isClosing = true
		return wrapper
	end

	wrapper.setBodyRenderer = function(renderer)
		config.bodyRenderer = renderer
		return wrapper
	end

	wrapper.setButtons = function(buttons)
		config.buttons = buttons
		config.buttonHoverStates = {}
		return wrapper
	end

	wrapper.render = function(dt)
		if not config.visible and not config.isClosing then
			return
		end

		if config.bodyHeight > 0 then
			local titleH = config.title ~= "" and (config.titleFontSize + 16) or 0
			local msgH = config.message ~= "" and (config.messageFontSize + 20) or 0

			config.obj_rect.height = config.padding
				+ titleH
				+ msgH
				+ config.bodyHeight
				+ config.buttonSpacing
				+ config.buttonHeight
				+ config.padding
		end

		-- Smooth animations
		if config.isClosing then
			-- Animate out
			config.animSlideY = config.animSlideY + (0 - config.animSlideY) * 0.2
			config.animAlpha = config.animAlpha + (0 - config.animAlpha) * 0.2

			-- When animation is complete, hide completely
			if config.animSlideY < 0.01 and config.animAlpha < 0.01 then
				config.visible = false
				config.isClosing = false
			end
		else
			-- Animate in
			config.animSlideY = config.animSlideY + (1 - config.animSlideY) * 0.12
			config.animAlpha = config.animAlpha + (1 - config.animAlpha) * 0.15
		end

		config.animScale = config.animScale + (1 - config.animScale) * 0.18

		local screenWidth = raylib.lib.GetScreenWidth()
		local screenHeight = raylib.lib.GetScreenHeight()

		-- Draw overlay background with lerped alpha
		local overlayAlpha = config.animAlpha * 0.6
		raylib.lib.DrawRectangle(0, 0, screenWidth, screenHeight, c3tr(config.overlayColor, 1 - overlayAlpha))

		local promptX = config.obj_rect.x
		local promptY = config.obj_rect.y
		if config.obj_rect.x == 0 and config.obj_rect.y == 0 then
			promptX = (screenWidth - config.obj_rect.width) / 2
			promptY = (screenHeight - config.obj_rect.height) / 2
		end

		-- Calculate slide position (starts below screen, moves to center)
		local startY = screenHeight -- Start below screen
		local targetY = promptY -- Center position
		local currentY = startY + (targetY - startY) * config.animSlideY

		local scaledWidth = config.obj_rect.width * config.animScale
		local scaledHeight = config.obj_rect.height * config.animScale
		local scaledX = promptX + (config.obj_rect.width - scaledWidth) / 2
		local scaledY = currentY + (config.obj_rect.height - scaledHeight) / 2

		local promptRect = rect.new(scaledX, scaledY, scaledWidth, scaledHeight)

		local shadowOffset = 6
		local shadowSpread = 3
		for i = 0, shadowSpread do
			local offset = shadowOffset + i * 2
			local alpha = 0.92 + (i * 0.02)
			raylib.lib.DrawRectangleRounded(
				rect:translate(
					rect.new(
						promptRect.x + offset - i,
						promptRect.y + offset,
						promptRect.width + i * 2,
						promptRect.height + i
					)
				),
				config.rounded[1],
				config.rounded[2],
				c3tr(color3.new(0, 0, 0), alpha)
			)
		end

		raylib.lib.DrawRectangleRounded(
			rect:translate(promptRect),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.borderColor, 0)
		)

		raylib.lib.DrawRectangleRounded(
			rect:translate(rect.new(promptRect.x + 1, promptRect.y + 1, promptRect.width - 2, promptRect.height - 2)),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		if config.showCloseButton then
			local closeSize = 36
			local closeX = promptRect.x + promptRect.width - config.padding - closeSize
			local closeY = promptRect.y + config.padding
			local closeRect = rect.new(closeX, closeY, closeSize, closeSize)

			local isCloseHovered = rect.MouseIsInRect(closeRect)

			if isCloseHovered then
				config.closeButtonHover = math.min(config.closeButtonHover + dt * 8, 1)
			else
				config.closeButtonHover = math.max(config.closeButtonHover - dt * 8, 0)
			end

			if config.closeButtonHover > 0 then
				raylib.lib.DrawRectangleRounded(
					rect:translate(closeRect),
					0.25,
					8,
					c3tr(color3.new(0.8, 0.2, 0.2), 1 - config.closeButtonHover * 0.85)
				)
			end

			local lineOffset = 10
			local lineThickness = 2
			local xColor = color3.new(
				0.6 + config.closeButtonHover * 0.4,
				0.6 - config.closeButtonHover * 0.4,
				0.6 - config.closeButtonHover * 0.4
			)

			raylib.lib.DrawLineEx(
				vector.create(closeX + lineOffset, closeY + lineOffset),
				vector.create(closeX + closeSize - lineOffset, closeY + closeSize - lineOffset),
				lineThickness,
				c3tr(xColor, 0)
			)
			raylib.lib.DrawLineEx(
				vector.create(closeX + closeSize - lineOffset, closeY + lineOffset),
				vector.create(closeX + lineOffset, closeY + closeSize - lineOffset),
				lineThickness,
				c3tr(xColor, 0)
			)

			if isCloseHovered and raylib.lib.IsMouseButtonReleased(0) == 1 then
				if config.onClose then
					config.onClose()
				end
				wrapper.hide()
			end
		end

		local contentY = promptRect.y + config.padding

		-- Draw title
		if config.title ~= "" then
			raylib.lib.DrawTextEx(
				config.font or defaultFont,
				config.title,
				vector.create(promptRect.x + config.padding, contentY),
				config.titleFontSize,
				1,
				c3tr(config.titleColor, 0)
			)
			contentY = contentY + config.titleFontSize + 16
		end

		-- Draw message
		if config.message ~= "" then
			raylib.lib.DrawTextEx(
				config.font or defaultFont,
				config.message,
				vector.create(promptRect.x + config.padding, contentY),
				config.messageFontSize,
				1,
				c3tr(config.messageColor, 0)
			)
			contentY = contentY + config.messageFontSize + 20
		end

		-- Render body content
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
			local btnWidth = button.width or 110
			totalButtonWidth = totalButtonWidth + btnWidth
			if i < #config.buttons then
				totalButtonWidth = totalButtonWidth + config.buttonSpacing
			end
		end

		local buttonY = promptRect.y + promptRect.height - config.padding - config.buttonHeight
		local buttonX = promptRect.x + promptRect.width - config.padding - totalButtonWidth

		for i, button in ipairs(config.buttons) do
			local btnWidth = button.width or 110
			local btnRect = rect.new(buttonX, buttonY, btnWidth, config.buttonHeight)

			local isHovered = rect.MouseIsInRect(btnRect)

			if not config.buttonHoverStates[i] then
				config.buttonHoverStates[i] = 0
			end

			if isHovered then
				config.buttonHoverStates[i] = math.min(config.buttonHoverStates[i] + dt * 10, 1)
			else
				config.buttonHoverStates[i] = math.max(config.buttonHoverStates[i] - dt * 10, 0)
			end

			local btnColor = button.color or color3.new(0.25, 0.27, 0.3)
			local hoverBrightness = 0.15 * config.buttonHoverStates[i]
			local hoverColor = color3.new(
				math.min(btnColor.R + hoverBrightness, 1),
				math.min(btnColor.G + hoverBrightness, 1),
				math.min(btnColor.B + hoverBrightness, 1)
			)

			-- Button shadow
			raylib.lib.DrawRectangleRounded(
				rect:translate(rect.new(btnRect.x + 2, btnRect.y + 2, btnRect.width, btnRect.height)),
				0.22,
				8,
				c3tr(color3.new(0, 0, 0), 0.8)
			)

			-- Button background
			raylib.lib.DrawRectangleRounded(rect:translate(btnRect), 0.22, 8, c3tr(hoverColor, 0))

			-- Button text
			local textSize = raylib.lib.MeasureTextEx(config.font or defaultFont, button.text, 15, 1)
			local textX = buttonX + (btnWidth - textSize.x) / 2
			local textY = buttonY + (config.buttonHeight - textSize.y) / 2

			raylib.lib.DrawTextEx(
				config.font or defaultFont,
				button.text,
				vector.create(textX, textY),
				15,
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
