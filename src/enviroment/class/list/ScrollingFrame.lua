local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local GuiObject = require("@GuiObject")
local Enum = require("@EnumMap")
local raylib = require("@Raylib")
local lib = raylib.lib
local UDim2 = require("@UDim2")
local Color3 = require("@Color3")
local structs = raylib.structs
local const = raylib.const
local Vector2 = require("@Vector2")
local UDim = require("@UDim")

local aereon = require("@Kinemium.Aereon")
local gui = aereon.gui
local arect = aereon.rect()

local propTable = {
	Name = "ScrollingFrame",

	-- layout
	AbsoluteSize = nil,
	AbsolutePosition = nil,

	-- appearance
	ScrollBarTransparency = 0,
	ScrollBarColor3 = Color3.new(0.5, 0.5, 0.5),
	ScrollBarCornerRadius = UDim.new(0, 0),
	ScrollBarBackgroundTransparency = 1,
	ScrollBarBackgroundColor3 = Color3.new(1, 1, 1),

	-- scrolling state
	Scroll = 0, -- normalized 0–1 (thumb position)
	ScrollOffset = 0.08, -- wheel step

	-- lerping
	ScrollTarget = 0, -- where input writes to
	ScrollLerpSpeed = 18, -- higher = snappier

	-- content
	ContentSize = 0, -- total content height (pixels)
	CanvasPosition = 0, -- pixel offset derived from Scroll
	AutoScrollSize = true,
	CanvasSize = 0,

	-- behavior
	ScrollBarThickness = 8,
	ScrollBarVisible = true,
	Elasticity = 0, -- 0 = hard clamp, >0 = overscroll later

	-- internal (do not expose)
	_draggingThumb = false,
	_dragOffsetY = 0,
}

local function c3tr(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

GuiObject.inherit(propTable)

return {
	class = "ScrollingFrame",

	callback = function(instance, renderer, game)
		propTable.render = function(lib, object, dt, structs, renderer)
			object._draggingThumb = object._draggingThumb or false
			object._dragOffsetY = object._dragOffsetY or 0

			local canvasOffset = Vector2.new(0, object.CanvasPosition or 0)

			local pos, size = GuiObject.render(lib, object, dt, structs, renderer)
			object.AbsolutePosition = pos
			object.AbsoluteSize = size

			local backgroundRect = arect.new(pos.X, pos.Y, size.X, size.Y)

			local scrollbarWidth = instance.ScrollBarThickness
			local scrollbarRect = arect.new(pos.X + size.X - scrollbarWidth, pos.Y, scrollbarWidth, size.Y)

			lib.DrawRectangleRec(
				arect:translate(scrollbarRect),
				c3tr(object.ScrollBarBackgroundColor3, object.ScrollBarBackgroundTransparency)
			)

			-- thumb
			local thumbMinHeight = 16
			local thumbHeight = math.max(size.Y * 0.2, thumbMinHeight)
			thumbHeight = math.min(thumbHeight, size.Y)

			local scroll = math.clamp(object.Scroll or 0, 0, 1)
			local thumbY = pos.Y + (size.Y - thumbHeight) * scroll
			local thumbRect = arect.new(pos.X + size.X - scrollbarWidth, thumbY, scrollbarWidth, thumbHeight)

			lib.DrawRectangleRec(arect:translate(thumbRect), c3tr(object.ScrollBarColor3, object.ScrollBarTransparency))

			-- logic
			local mousePos = lib.GetMousePosition()

			-- start dragging
			if lib.IsMouseButtonPressed(0) == 1 and arect.MouseIsInRect(thumbRect) then
				object._draggingThumb = true
				object._dragOffsetY = mousePos.y - thumbY
				raylib.lib.SetMouseCursor(raylib.const.MouseCursor.MOUSE_CURSOR_RESIZE_ALL)
			end

			-- stop dragging
			if lib.IsMouseButtonReleased(0) == 1 then
				object._draggingThumb = false
				raylib.lib.SetMouseCursor(raylib.const.MouseCursor.MOUSE_CURSOR_DEFAULT)
			end

			-- drag update
			if object._draggingThumb then
				local minY = pos.Y
				local maxY = pos.Y + size.Y - thumbHeight

				local newThumbY = mousePos.y - object._dragOffsetY
				newThumbY = math.clamp(newThumbY, minY, maxY)

				object.ScrollTarget = (newThumbY - minY) / (maxY - minY)
			end

			-- detect scroll
			if arect.MouseIsInRect(backgroundRect) then
				local wheel = lib.GetMouseWheelMove()

				if wheel ~= 0 then
					object.ScrollTarget =
						math.clamp((object.ScrollTarget or object.Scroll) + wheel * object.ScrollOffset, 0, 1)
				end
			end

			-- hard clamp (safety)
			object.ScrollTarget = math.clamp(object.ScrollTarget or object.Scroll, 0, 1)

			object.Scroll = object.Scroll
				+ (object.ScrollTarget - object.Scroll) * math.clamp(dt * object.ScrollLerpSpeed, 0, 1)

			-- compute total content height
			local contentHeight = 0
			for _, child in pairs(object:GetChildren()) do
				local childOffset = child.Position.Y.Offset
				local childHeight = child.Size.Y.Offset
				local childRelativeBottom = childOffset + childHeight
				contentHeight = math.max(contentHeight, childRelativeBottom)
			end
			object.ContentSize = object.AutoScrollSize and contentHeight or object.CanvasSize

			local maxScroll = math.max(0, object.ContentSize - object.AbsoluteSize.Y)
			object.CanvasPosition = object.Scroll * maxScroll

			for _, child in pairs(object:GetChildren()) do
				if child.render then
					local originalPos = child.Position

					child._basePosition = child._basePosition or child.Position

					local base = child._basePosition
					child.Position =
						UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset - object.CanvasPosition)

					lib.BeginScissorMode(pos.X, pos.Y, size.X, size.Y)
					child.render(lib, child, dt, structs, renderer)
					lib.EndScissorMode()
				end
			end
		end

		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		GuiObject.inherit(tble)
	end,
}
