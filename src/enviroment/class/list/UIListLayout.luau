local Vector2 = require("@datatypes/Vector2")
local Enum = require("@EnumMap")
local UDim = require("@datatypes/UDim")

local propTable = {
	Direction = Enum.FillDirection.Vertical, -- "Horizontal" or "Vertical"
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

		local children = {}

		for _, child in ipairs(parent:GetChildren()) do
			if child.Visible and child ~= object then
				table.insert(children, child)
			end
		end

		if object.SortOrder == Enum.SortOrder.LayoutOrder and #children > 1 then
			table.sort(children, function(a, b)
				return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
			end)
		end

		local offset = 0

		for _, child in ipairs(children) do
			local size = child.Size:ToPixels(parentSize)

			local paddingPx = object.Padding.Scale
					* (object.Direction == Enum.FillDirection.Vertical and parentSize.Y or parentSize.X)
				+ object.Padding.Offset

			rawset(child, "_LayoutControlled", true)
			rawset(child, "_LayoutAbsolutePosition", Vector2.new(0, 0))

			---------------------------
			--   VERTICAL LAYOUT     --
			---------------------------
			if object.Direction == Enum.FillDirection.Vertical then
				local alignedX = 0

				if object.HorizontalAlignment == Enum.HorizontalAlignment.Center then
					alignedX = (parentSize.X - size.X) * 0.5
				elseif object.HorizontalAlignment == Enum.HorizontalAlignment.Right then
					alignedX = parentSize.X - size.X
				end

				rawset(child, "_LayoutRelativePosition", Vector2.new(alignedX, offset))

				offset = offset + size.Y + paddingPx

			---------------------------
			--   HORIZONTAL LAYOUT   --
			---------------------------
			else
				local alignedY = 0

				if object.VerticalAlignment == Enum.VerticalAlignment.Center then
					alignedY = (parentSize.Y - size.Y) * 0.5
				elseif object.VerticalAlignment == Enum.VerticalAlignment.Bottom then
					alignedY = parentSize.Y - size.Y
				end

				rawset(child, "_LayoutRelativePosition", Vector2.new(offset, alignedY))

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
