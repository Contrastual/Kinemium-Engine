local raylib = require("@raylib")
local MergedCell = require("./cellItem")
local arect = require("@arect")(raylib.lib)

return function(objects, data)
	local cells = {}
	local cellRefs = {}
	local cellOffsets = {}

	local config = {
		obj_rect = arect.new(data.x or data[1] or 0, data.y or data[2] or 0, data.width or data[3] or 800, 0),
		cellHeight = data.cellHeight or 70,
		spacing = data.spacing or 0,
		groupSpacing = data.groupSpacing or 20,
		sections = data.sections or {},
	}

	local function createCell(cellConfig, position, yOffset)
		local cell = MergedCell(objects, {
			x = cellConfig.x or config.obj_rect.x,
			y = (cellConfig.y or config.obj_rect.y) + yOffset,
			width = cellConfig.width or config.obj_rect.width,
			height = cellConfig.height or config.cellHeight,

			propertyName = cellConfig.name or cellConfig.propertyName or "Property",
			propertyDescription = cellConfig.description or cellConfig.propertyDescription,
			propertyValue = cellConfig.value or cellConfig.propertyValue,
			font = cellConfig.font,
			roundness = 0.3,

			position = position,
			showSeparator = cellConfig.showSeparator,

			backgroundColor = cellConfig.backgroundColor,
			backgroundTransparency = cellConfig.backgroundTransparency,
			hoverColor = cellConfig.hoverColor,
			separatorColor = cellConfig.separatorColor,
			textColor = cellConfig.textColor,
			descriptionColor = cellConfig.descriptionColor,

			editorComponent = cellConfig.editor or cellConfig.editorComponent,
			editorWidth = cellConfig.editorWidth or 200,

			onValueChange = cellConfig.onValueChange,
			onClick = cellConfig.onClick,
		})

		return cell
	end

	local function clearCells()
		for _, cell in ipairs(cells) do
			for i, obj in ipairs(objects) do
				if obj == cell then
					table.remove(objects, i)
					break
				end
			end
		end
		table.clear(cells)
		table.clear(cellRefs)
		table.clear(cellOffsets)
	end

	local function rebuild()
		clearCells()
		local currentY = 0
		local sections = config.sections

		for groupName, groupConfig in pairs(sections) do
			if type(groupConfig) == "table" then
				local groupCells = {}
				local groupItems = {}

				if groupConfig.items then
					groupItems = groupConfig.items
				elseif groupConfig[1] then
					groupItems = groupConfig
				else
					groupItems = { groupConfig }
				end

				local itemCount = #groupItems
				for i, itemConfig in ipairs(groupItems) do
					local position = "middle"
					if itemCount == 1 then
						position = "single"
					elseif i == 1 then
						position = "first"
					elseif i == itemCount then
						position = "last"
					end

					if itemConfig.showSeparator == nil then
						itemConfig.showSeparator = i < itemCount
					end

					local cell = createCell(itemConfig, position, currentY)
					table.insert(groupCells, cell)
					table.insert(cells, cell)
					table.insert(cellOffsets, currentY)

					currentY = currentY + (itemConfig.height or config.cellHeight)
				end

				cellRefs[groupName] = groupCells
				currentY = currentY + (groupConfig.spacing or config.groupSpacing)
			end
		end
		config.obj_rect.height = currentY
	end

	if not data.sections then
		for k, v in pairs(data) do
			if type(v) == "table" and type(k) == "string" and k ~= "obj_rect" then
				config.sections[k] = v
			end
		end
	end

	rebuild()

	local wrapper = {}

	wrapper.set = function(prop, value)
		if prop == "obj_rect" then
			config.obj_rect = value
			for i, cell in ipairs(cells) do
				local cellRect = cell.getRect()
				local offsetY = cellOffsets[i]
				cell.set(
					"obj_rect",
					arect.new(config.obj_rect.x, config.obj_rect.y + offsetY, config.obj_rect.width, cellRect.height)
				)
			end
		elseif prop == "width" then
			config.obj_rect.width = value
			for _, cell in ipairs(cells) do
				local cellRect = cell.getRect()
				cell.set("obj_rect", arect.new(cellRect.x, cellRect.y, value, cellRect.height))
			end
		elseif prop == "sections" then
			if config.sections ~= value then
				config.sections = value
				rebuild()
			end
		else
			config[prop] = value
		end
		return wrapper
	end

	wrapper.get = function(prop)
		return config[prop]
	end

	wrapper.get_rect = function()
		return config.obj_rect
	end

	wrapper.render = function(dt)
		for _, cell in ipairs(cells) do
			cell.render(dt)
		end
	end

	wrapper.getValue = function(groupName, index)
		local group = cellRefs[groupName]
		if group and group[index] then
			return group[index].getPropertyValue()
		end
		return nil
	end

	wrapper.setValue = function(groupName, index, value)
		local group = cellRefs[groupName]
		if group and group[index] then
			group[index].setPropertyValue(value)
		end
		return wrapper
	end

	wrapper.getGroup = function(name)
		return cellRefs[name]
	end

	table.insert(objects, wrapper)
	return wrapper
end
