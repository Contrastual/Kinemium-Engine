local UDim2 = require("@UDim2")

local propTable = {
	Name = "UIPadding",
	Padding = UDim2.new(0, 0, 0, 0),
	BaseClass = "Instance",

	_CachedPadding = nil,
	_CachedParentSize = nil,
}

function propTable.GetEffectivePadding(object, parentSize)
	local padding = object.Padding
	local cachedSize = object._CachedParentSize
	local cachedPadding = object._CachedPadding

	if not cachedSize or not cachedPadding or cachedSize ~= parentSize then
		local paddingPixels = padding:ToPixels(parentSize)
		object._CachedPadding = paddingPixels
		object._CachedParentSize = parentSize
		return paddingPixels
	end

	return cachedPadding
end

function propTable.GetEffectiveContainerSize(object, containerSize)
	local parent = object.Parent
	if not parent then
		return containerSize
	end

	local paddingPixels = object:GetEffectivePadding(containerSize)

	local effectiveWidth = containerSize.X - paddingPixels.X * 2
	local effectiveHeight = containerSize.Y - paddingPixels.Y * 2

	effectiveWidth = math.max(0, effectiveWidth)
	effectiveHeight = math.max(0, effectiveHeight)

	return Vector2.new(effectiveWidth, effectiveHeight)
end

function propTable.GetEffectiveContainerOffset(object, containerSize)
	local paddingPixels = object:GetEffectivePadding(containerSize)
	return Vector2.new(paddingPixels.X, paddingPixels.Y)
end

function propTable.GetEffectiveChildPosition(object, childRelativePosition, containerSize)
	local paddingOffset = object:GetEffectiveContainerOffset(containerSize)
	return childRelativePosition + paddingOffset
end

function propTable.GetAllPaddings(container)
	local paddings = {}

	for _, child in ipairs(container:GetChildren()) do
		if child.ClassName == "UIPadding" then
			table.insert(paddings, child)
		end
	end

	return paddings
end

function propTable.GetTotalEffectivePadding(container, containerSize)
	local totalPaddingX = 0
	local totalPaddingY = 0

	local paddings = propTable.GetAllPaddings(container)

	for _, padding in ipairs(paddings) do
		local effectivePadding = padding:GetEffectivePadding(containerSize)
		totalPaddingX = totalPaddingX + effectivePadding.X
		totalPaddingY = totalPaddingY + effectivePadding.Y
	end

	return Vector2.new(totalPaddingX, totalPaddingY)
end

function propTable.GetTotalEffectiveContainerSize(container, containerSize)
	local totalPadding = propTable.GetTotalEffectivePadding(container, containerSize)

	local effectiveWidth = containerSize.X - totalPadding.X * 2
	local effectiveHeight = containerSize.Y - totalPadding.Y * 2

	effectiveWidth = math.max(0, effectiveWidth)
	effectiveHeight = math.max(0, effectiveHeight)

	return Vector2.new(effectiveWidth, effectiveHeight)
end

function propTable.GetTotalEffectiveContainerOffset(container, containerSize)
	local totalPadding = propTable.GetTotalEffectivePadding(container, containerSize)
	return Vector2.new(totalPadding.X, totalPadding.Y)
end

function propTable.GetTotalEffectiveChildPosition(container, childRelativePosition, containerSize)
	local totalPaddingOffset = propTable.GetTotalEffectiveContainerOffset(container, containerSize)
	return childRelativePosition + totalPaddingOffset
end

return {
	class = "UIPadding",
	render = function(lib, object, dt, structs, renderer)
		return nil
	end,
	callback = function(instance)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			if not tble[prop] then
				tble[prop] = val
			end
		end
	end,
}
