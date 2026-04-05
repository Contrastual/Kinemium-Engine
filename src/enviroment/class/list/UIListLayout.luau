local Vector2 = require("@Vector2")
local Enum = require("@EnumMap")
local UDim = require("@UDim")

local propTable = {
	FillDirection = Enum.FillDirection.Vertical, -- "Horizontal" or "Vertical"
	Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder, -- "LayoutOrder" or "None"
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Enabled = true,
	Name = "UIListLayout",

	render = function(lib, object, dt, structs)
		if not object.Enabled then
			return
		end
		local parent = object.Parent
		if not parent then
			return
		end

		local function GetAbsoluteSize(obj)
			if obj.AbsoluteSize then
				return obj.AbsoluteSize
			end
			if obj:IsA("ScreenGui") then
				return Vector2.new(lib.GetRenderWidth(), lib.GetRenderHeight())
			else
				local parentSize = GetAbsoluteSize(obj.Parent)
				return obj.Size:ToPixels(parentSize)
			end
		end

		local parentSize = GetAbsoluteSize(parent)

		local totalPaddingX = 0
		local totalPaddingY = 0

		for _, child in ipairs(parent:GetChildren()) do
			if child.ClassName == "UIPadding" then
				local padding = child.Padding
				local paddingPixels = padding:ToPixels(parentSize)
				totalPaddingX = totalPaddingX + paddingPixels.X
				totalPaddingY = totalPaddingY + paddingPixels.Y
			end
		end

		local effectiveWidth = parentSize.X - totalPaddingX * 2
		local effectiveHeight = parentSize.Y - totalPaddingY * 2
		effectiveWidth = math.max(0, effectiveWidth)
		effectiveHeight = math.max(0, effectiveHeight)
		local effectiveContainerSize = Vector2.new(effectiveWidth, effectiveHeight)

		local children = {}

		for _, child in ipairs(parent:GetChildren()) do
			if child.Visible and child ~= object and child.ClassName ~= "UIPadding" then
				table.insert(children, child)
			end
		end

		if object.SortOrder == Enum.SortOrder.LayoutOrder and #children > 1 then
			table.sort(children, function(a, b)
				return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
			end)
		end

		local paddingPx = object.Padding.Scale
				* (object.FillDirection == Enum.FillDirection.Vertical and effectiveContainerSize.Y or effectiveContainerSize.X)
			+ object.Padding.Offset
		local contentSpan = 0
		local childSizes = {}

		for index, child in ipairs(children) do
			local size = child.Size:ToPixels(effectiveContainerSize)
			childSizes[child] = size
			contentSpan += object.FillDirection == Enum.FillDirection.Vertical and size.Y or size.X

			if index < #children then
				contentSpan += paddingPx
			end
		end

		local offset

		if object.FillDirection == Enum.FillDirection.Vertical then
			offset = totalPaddingY

			if object.VerticalAlignment == Enum.VerticalAlignment.Center then
				offset += math.max(0, (effectiveContainerSize.Y - contentSpan) * 0.5)
			elseif object.VerticalAlignment == Enum.VerticalAlignment.Bottom then
				offset += math.max(0, effectiveContainerSize.Y - contentSpan)
			end
		else
			offset = totalPaddingX

			if object.HorizontalAlignment == Enum.HorizontalAlignment.Center then
				offset += math.max(0, (effectiveContainerSize.X - contentSpan) * 0.5)
			elseif object.HorizontalAlignment == Enum.HorizontalAlignment.Right then
				offset += math.max(0, effectiveContainerSize.X - contentSpan)
			end
		end

		for _, child in ipairs(children) do
			local size = childSizes[child]

			rawset(child, "_LayoutControlled", true)
			rawset(child, "_LayoutAbsolutePosition", Vector2.new(0, 0))

			---------------------------
			--   VERTICAL LAYOUT     --
			---------------------------
			if object.FillDirection == Enum.FillDirection.Vertical then
				local alignedX = 0

				if object.HorizontalAlignment == Enum.HorizontalAlignment.Center then
					alignedX = (effectiveContainerSize.X - size.X) * 0.5
				elseif object.HorizontalAlignment == Enum.HorizontalAlignment.Right then
					alignedX = effectiveContainerSize.X - size.X
				end

				-- Add padding offset to position
				local finalX = alignedX + totalPaddingX
				rawset(child, "_LayoutRelativePosition", Vector2.new(finalX, offset))

				offset = offset + size.Y + paddingPx

			---------------------------
			--   HORIZONTAL LAYOUT   --
			---------------------------
			else
				local alignedY = 0

				if object.VerticalAlignment == Enum.VerticalAlignment.Center then
					alignedY = (effectiveContainerSize.Y - size.Y) * 0.5
				elseif object.VerticalAlignment == Enum.VerticalAlignment.Bottom then
					alignedY = effectiveContainerSize.Y - size.Y
				end

				-- Add padding offset to position
				local finalY = alignedY + totalPaddingY
				rawset(child, "_LayoutRelativePosition", Vector2.new(offset, finalY))

				offset = offset + size.X + paddingPx
			end
		end
	end,
}

return {
	class = "UIListLayout",
	render = propTable.render,
	callback = function(instance)
		instance:SetProperties(propTable)
		return instance
	end,
}
