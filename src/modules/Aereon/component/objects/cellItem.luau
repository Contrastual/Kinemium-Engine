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
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4] or 60),

		-- Property data
		propertyName = data.propertyName or "Property",
		propertyDescription = data.propertyDescription, -- Optional description text
		propertyValue = data.propertyValue,

		-- Visual settings
		backgroundColor = data.backgroundColor or color3.new(0.15, 0.15, 0.15),
		hoverColor = data.hoverColor or color3.new(0.18, 0.18, 0.18),
		separatorColor = data.separatorColor or color3.new(0.25, 0.25, 0.25),
		textColor = data.textColor or color3.new(0.9, 0.9, 0.9),
		descriptionColor = data.descriptionColor or color3.new(0.6, 0.6, 0.6),

		-- Position in list
		position = data.position or "middle", -- "first", "middle", "last", "single"
		showSeparator = data.showSeparator ~= false, -- Show separator line at bottom

		-- Layout
		padding = data.padding or 16,
		nameFontSize = data.nameFontSize or 19,
		descFontSize = data.descFontSize or 14,
		fontSpacing = data.fontSpacing or 1,
		roundness = data.roundness or 0.08,
		segments = data.segments or 8,
		separatorHeight = data.separatorHeight or 1,

		-- State
		isHovered = false,
		font = data.font or raylib.lib.GetFontDefault(),

		-- Editor component (placed on the right side)
		editorComponent = data.editorComponent,
		editorWidth = data.editorWidth or 200, -- Width of the editor area

		-- Callbacks
		onValueChange = data.onValueChange,
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

	wrapper.setPropertyValue = function(value)
		config.propertyValue = value
		if config.editorComponent and config.editorComponent.setText then
			config.editorComponent:setText(tostring(value))
		elseif config.editorComponent and config.editorComponent.set then
			config.editorComponent.set("value", value)
		end

		if config.onValueChange then
			config.onValueChange(value)
		end
	end

	wrapper.setEditorComponent = function(component)
		config.editorComponent = component
	end

	wrapper.getPropertyValue = function()
		return config.propertyValue
	end

	wrapper.setPosition = function(pos)
		config.position = pos
	end

	wrapper.getRect = function()
		return config.obj_rect
	end

	local function drawRoundedCellBackground(r, bgColor, position, roundness, segments)
		-- Draw rectangle with selective corner rounding based on position
		-- "first" = round top corners only
		-- "middle" = no rounded corners
		-- "last" = round bottom corners only
		-- "single" = round all corners

		if position == "single" then
			-- All corners rounded
			raylib.lib.DrawRectangleRounded(rect:translate(r), roundness, segments, c3tr(bgColor, 0))
		elseif position == "first" then
			-- Top corners rounded, bottom square
			-- Draw main rectangle
			raylib.lib.DrawRectangle(
				r.x,
				r.y + r.height * roundness,
				r.width,
				r.height * (1 - roundness),
				c3tr(bgColor, 0)
			)

			-- Draw rounded top
			raylib.lib.DrawRectangleRounded(
				structs.Rectangle:new({
					x = r.x,
					y = r.y,
					width = r.width,
					height = r.height * roundness * 3,
				}),
				roundness * 2,
				segments,
				c3tr(bgColor, 0)
			)
		elseif position == "last" then
			-- Bottom corners rounded, top square
			-- Draw main rectangle
			raylib.lib.DrawRectangle(r.x, r.y, r.width, r.height * (1 - roundness), c3tr(bgColor, 0))

			-- Draw rounded bottom
			raylib.lib.DrawRectangleRounded(
				structs.Rectangle:new({
					x = r.x,
					y = r.y + r.height * (1 - roundness * 3),
					width = r.width,
					height = r.height * roundness * 3,
				}),
				roundness * 2,
				segments,
				c3tr(bgColor, 0)
			)
		else -- "middle"
			-- No rounded corners
			raylib.lib.DrawRectangle(r.x, r.y, r.width, r.height, c3tr(bgColor, 0))
		end
	end

	wrapper.render = function(dt)
		local r = config.obj_rect
		local mousePos = raylib.lib.GetMousePosition()
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1

		config.isHovered = rect.MouseIsInRect(r)

		local bgColor = config.isHovered and config.hoverColor or config.backgroundColor

		drawRoundedCellBackground(r, bgColor, config.position, config.roundness, config.segments)

		if config.showSeparator and config.position ~= "last" and config.position ~= "single" then
			raylib.lib.DrawRectangle(
				r.x + config.padding,
				r.y + r.height - config.separatorHeight,
				r.width - config.padding * 2,
				config.separatorHeight,
				c3tr(config.separatorColor, 0)
			)
		end

		-- Calculate text layout
		local nameX = r.x + config.padding
		local nameY = r.y + config.padding

		-- If there's a description, adjust name positioning
		if config.propertyDescription then
			nameY = r.y + (r.height - config.nameFontSize - config.descFontSize - 4) / 2
		else
			nameY = r.y + (r.height - config.nameFontSize) / 2
		end

		-- Draw property name
		raylib.lib.DrawTextEx(
			config.font,
			config.propertyName,
			vector.create(nameX, nameY),
			config.nameFontSize,
			config.fontSpacing,
			c3tr(config.textColor, 0)
		)

		-- Draw description if provided
		if config.propertyDescription then
			local descY = nameY + config.nameFontSize + 4
			raylib.lib.DrawTextEx(
				config.font,
				config.propertyDescription,
				vector.create(nameX, descY),
				config.descFontSize,
				config.fontSpacing,
				c3tr(config.descriptionColor, 0)
			)
		end

		-- Calculate editor position (right side)
		local editorX = r.x + r.width - config.editorWidth - config.padding
		local editorY = r.y + (r.height - 30) / 2 -- Center vertically
		local editorWidth = config.editorWidth
		local editorHeight = 30

		-- Render editor component if provided
		if config.editorComponent then
			if config.editorComponent.drawWithExtras then
				-- Textbox-style component
				config.editorComponent:drawWithExtras(editorX, editorY, editorWidth, editorHeight)
			elseif config.editorComponent.render then
				-- Custom render method
				if config.editorComponent.set then
					config.editorComponent.set("obj_rect", rect.new(editorX, editorY, editorWidth, editorHeight))
				end
				config.editorComponent.render(dt)
			elseif config.editorComponent.draw then
				-- Simple draw method
				config.editorComponent.draw(editorX, editorY, editorWidth, editorHeight)
			end
		end

		-- Handle click
		if config.isHovered and mousePressed and config.onClick then
			config.onClick()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
