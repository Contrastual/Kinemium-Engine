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

return function(objects, data)
	local config = {
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4]),
		rounded = data.rounded or { 0.08, 8 },
		modifiers = {},

		title = data.title or "Sodium",
		description = data.description or "The fastest and most compatible rendering optimization mod for Minecraft.",
		downloads = data.downloads or "109.57M",
		likes = data.likes or "32.0k",
		category = data.category or "Optimization",
		icon = data.icon,
		bannerImage = data.bannerImage,
		font = data.font, -- Custom font property

		backgroundColor = color3.new(0.14, 0.14, 0.16),
		darkBackgroundColor = color3.new(0.10, 0.10, 0.12),
		iconBackgroundColor = color3.new(0.35, 0.75, 0.35),
		textColor = color3.new(0.85, 0.85, 0.87),
		dimTextColor = color3.new(0.60, 0.60, 0.63),
		categoryColor = color3.new(0.50, 0.50, 0.53),

		isHovered = false,
		onClick = data.onClick,
	}

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1

		config.isHovered = rect.MouseIsInRect(r)

		raylib.lib.DrawRectangleRounded(
			rect:translate(r),
			config.rounded[1],
			config.rounded[2],
			c3tr(config.backgroundColor, 0)
		)

		local padding = 12
		local bannerHeight = r.height * 0.45
		local iconSize = 48
		local iconPadding = 16

		local bannerRect = rect.new(r.x, r.y, r.width, bannerHeight)

		if config.bannerImage then
			raylib.lib.BeginScissorMode(bannerRect.x, bannerRect.y, bannerRect.width, bannerRect.height)
			raylib.lib.DrawTexturePro(
				config.bannerImage.texture,
				structs.Rectangle:new({ x = 0, y = 0, width = config.bannerImage.x, height = config.bannerImage.y }),
				rect:translate(bannerRect),
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
			raylib.lib.EndScissorMode()
		else
			raylib.lib.DrawRectangleGradientV(
				bannerRect.x,
				bannerRect.y,
				bannerRect.width,
				bannerRect.height,
				c3tr(color3.new(0.45, 0.65, 0.50), 0),
				c3tr(color3.new(0.30, 0.50, 0.70), 0)
			)
		end

		local contentY = r.y + bannerHeight

		local iconY = contentY - iconSize / 2
		local iconRect = rect.new(r.x + iconPadding, iconY, iconSize, iconSize)

		raylib.lib.DrawRectangleRounded(rect:translate(iconRect), 0.15, 8, c3tr(config.iconBackgroundColor, 0))

		if config.icon then
			raylib.lib.DrawTexturePro(
				config.icon.texture,
				structs.Rectangle:new({ x = 0, y = 0, width = config.icon.x, height = config.icon.y }),
				rect:translate(iconRect),
				vector.create(0, 0),
				0,
				raylib.const.WHITE
			)
		end

		-- Title with custom font
		local titleY = contentY + iconSize / 2 + 8
		local titleFontSize = 18
		local titleSpacing = 1.0

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.title,
				vector.create(r.x + iconPadding, titleY),
				titleFontSize,
				titleSpacing,
				c3tr(config.textColor, 0)
			)
		else
			raylib.lib.DrawText(config.title, r.x + iconPadding, titleY, titleFontSize, c3tr(config.textColor, 0))
		end

		-- Description with custom font and word wrapping
		local descY = titleY + 26
		local descWidth = r.width - iconPadding * 2
		local descFontSize = 11
		local descSpacing = 0.5

		local words = {}
		for word in config.description:gmatch("%S+") do
			table.insert(words, word)
		end

		local currentLine = ""
		local lineY = descY

		for _, word in ipairs(words) do
			local testLine = currentLine == "" and word or currentLine .. " " .. word
			local lineWidth

			if config.font then
				local textSize = raylib.lib.MeasureTextEx(config.font, testLine, descFontSize, descSpacing)
				lineWidth = textSize.x
			else
				lineWidth = raylib.lib.MeasureText(testLine, descFontSize)
			end

			if lineWidth > descWidth then
				if config.font then
					raylib.lib.DrawTextEx(
						config.font,
						currentLine,
						vector.create(r.x + iconPadding, lineY),
						descFontSize,
						descSpacing,
						c3tr(config.dimTextColor, 0)
					)
				else
					raylib.lib.DrawText(
						currentLine,
						r.x + iconPadding,
						lineY,
						descFontSize,
						c3tr(config.dimTextColor, 0)
					)
				end
				currentLine = word
				lineY = lineY + 16
			else
				currentLine = testLine
			end
		end

		if currentLine ~= "" then
			if config.font then
				raylib.lib.DrawTextEx(
					config.font,
					currentLine,
					vector.create(r.x + iconPadding, lineY),
					descFontSize,
					descSpacing,
					c3tr(config.dimTextColor, 0)
				)
			else
				raylib.lib.DrawText(currentLine, r.x + iconPadding, lineY, descFontSize, c3tr(config.dimTextColor, 0))
			end
		end

		-- Stats with custom font
		local statsY = r.y + r.height - 32
		local statsIconSize = 12
		local statsFontSize = 11
		local statsSpacing = 0.5

		raylib.lib.DrawRectangle(
			r.x + iconPadding,
			statsY + 4,
			statsIconSize,
			statsIconSize,
			c3tr(config.dimTextColor, 0)
		)

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.downloads,
				vector.create(r.x + iconPadding + statsIconSize + 6, statsY + 2),
				statsFontSize,
				statsSpacing,
				c3tr(config.dimTextColor, 0)
			)
		else
			raylib.lib.DrawText(
				config.downloads,
				r.x + iconPadding + statsIconSize + 6,
				statsY + 2,
				statsFontSize,
				c3tr(config.dimTextColor, 0)
			)
		end

		local likesX = r.x + iconPadding + 100
		raylib.lib.DrawRectangle(likesX, statsY + 4, statsIconSize, statsIconSize, c3tr(config.dimTextColor, 0))

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.likes,
				vector.create(likesX + statsIconSize + 6, statsY + 2),
				statsFontSize,
				statsSpacing,
				c3tr(config.dimTextColor, 0)
			)
		else
			raylib.lib.DrawText(
				config.likes,
				likesX + statsIconSize + 6,
				statsY + 2,
				statsFontSize,
				c3tr(config.dimTextColor, 0)
			)
		end

		local categoryX = r.x + r.width - iconPadding - 100
		raylib.lib.DrawRectangle(categoryX, statsY + 4, statsIconSize, statsIconSize, c3tr(config.categoryColor, 0))

		if config.font then
			raylib.lib.DrawTextEx(
				config.font,
				config.category,
				vector.create(categoryX + statsIconSize + 6, statsY + 2),
				statsFontSize,
				statsSpacing,
				c3tr(config.categoryColor, 0)
			)
		else
			raylib.lib.DrawText(
				config.category,
				categoryX + statsIconSize + 6,
				statsY + 2,
				statsFontSize,
				c3tr(config.categoryColor, 0)
			)
		end

		if config.isHovered then
			raylib.lib.DrawRectangleRounded(
				rect:translate(r),
				config.rounded[1],
				config.rounded[2],
				c3tr(color3.new(1, 1, 1), 0.95)
			)
		end

		if config.isHovered and mousePressed and config.onClick then
			config.onClick()
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
