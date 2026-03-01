local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local Enum = require("@EnumMap")
local UDim2 = require("@UDim2")
local UDim = require("@UDim")
local signal = require("@Kinemium.signal")
local Vector2 = require("@Vector2")

local segments = 16
local ZERO_VECTOR2 = Vector2.new(0, 0)

local function GetAbsoluteSize(object, lib)
	if object.BaseClass == "UIContainer" then
		return Vector2.new(object.Size.X.Offset, object.Size.Y.Offset)
	end
	return object.Size:ToPixels(GetAbsoluteSize(object.Parent, lib))
end

local function getAbsoluteDrawPos(object, lib)
	if object.BaseClass == "UIContainer" then
		return object.RenderOffset
	end
	local parent = object.Parent
	local parentAbsPos = getAbsoluteDrawPos(parent, lib)
	local parentSize = GetAbsoluteSize(parent, lib)
	local pos = object.Position:ToPixels(parentSize)
	local size = object.Size:ToPixels(parentSize)
	local anchor = object.AnchorPoint or ZERO_VECTOR2
	return Vector2.new(parentAbsPos.X + pos.X - size.X * anchor.X, parentAbsPos.Y + pos.Y - size.Y * anchor.Y)
end

local function IsMouseInGuiRecursive(object, mousePos, lib)
	local size = object.Size:ToPixels(GetAbsoluteSize(object.Parent, lib))
	local drawPos = getAbsoluteDrawPos(object, lib)

	if
		mousePos.X >= drawPos.X
		and mousePos.X <= drawPos.X + size.X
		and mousePos.Y >= drawPos.Y
		and mousePos.Y <= drawPos.Y + size.Y
	then
		return true
	end

	if object.GetChildren then
		for _, child in ipairs(object:GetChildren()) do
			if child.Position and IsMouseInGuiRecursive(child, mousePos, lib) then
				return true
			end
		end
	end

	return false
end

local function calculateDrawParams(object, lib)
	local parentSize = GetAbsoluteSize(object.Parent, lib)
	local size, drawPos, anchor

	if object._EditorOverride then
		size = object.AbsoluteSize or ZERO_VECTOR2
		drawPos = object.AbsolutePosition or ZERO_VECTOR2
		anchor = object.AnchorPoint or ZERO_VECTOR2
	elseif object._LayoutControlled and object._LayoutRelativePosition then
		size = object.Size:ToPixels(parentSize)
		anchor = object.AnchorPoint or ZERO_VECTOR2
		local parentDrawPos = getAbsoluteDrawPos(object.Parent, lib)
		drawPos = Vector2.new(
			parentDrawPos.X + object._LayoutRelativePosition.X - size.X * anchor.X,
			parentDrawPos.Y + object._LayoutRelativePosition.Y - size.Y * anchor.Y
		)
	else
		size = object.Size:ToPixels(parentSize)
		anchor = object.AnchorPoint or ZERO_VECTOR2
		drawPos = getAbsoluteDrawPos(object, lib)
	end

	return drawPos, size
end

local propTable = {
	BaseClass = "GuiObject",
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 100, 0, 100),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0,
	Visible = true,
	BorderSize = 0,
	BorderColor = Color3.new(0, 0, 0),
	BorderTransparency = 0,
	Rotation = 0,
	AbsolutePosition = nil,
	Anchored = true,
	AbsoluteSize = nil,
	ClipsDescendants = false,
	ZIndex = 1,
	AnchorPoint = ZERO_VECTOR2,
	MouseIsInObject = false,

	render = function(lib, object, dt, structs, renderer)
		if not object.Visible then
			return
		end

		local mousePos = Vector2.new(lib.GetMouseX(), lib.GetMouseY())
		object.MouseIsInObject = IsMouseInGuiRecursive(object, mousePos, lib)
		object.MouseEnter:FireOncePerPress("MouseEnter", object.MouseIsInObject)
		object.MouseLeave:FireOncePerPress("MouseLeave", not object.MouseIsInObject)

		local drawPos, size = calculateDrawParams(object, lib)
		local color = object.BackgroundColor3:ToRaylib(object.BackgroundTransparency)

		local corner = object:FindFirstChildOfClass("UICorner")
		local stroke = object:FindFirstChildOfClass("UIStroke")
		local gradient = object:FindFirstChildOfClass("UIGradient")
		local blur = object:FindFirstChild("BlurEffect")

		local rec = structs.Rectangle:new({ x = drawPos.X, y = drawPos.Y, width = size.X, height = size.Y })
		local origin = vector.create(0, 0)

		if blur and object.AbsolutePosition and object.AbsoluteSize then
			renderer.Blur.blurRadius = blur.Size
			renderer.Blur:DrawBlurredRegion(
				object.AbsolutePosition.X,
				object.AbsolutePosition.Y,
				object.AbsoluteSize.X,
				object.AbsoluteSize.Y,
				Color3.new(1, 1, 1):ToRaylib(0)
			)
		end

		local minDim = math.min(size.X, size.Y)
		local cornerRadius = 0
		local roundness = 0

		if corner then
			cornerRadius = corner.CornerRadius.Scale * minDim + corner.CornerRadius.Offset
			roundness = cornerRadius / minDim
		end

		if gradient then
			local steps = 50
			local stepHeight = size.Y / steps

			for i = 0, steps - 1 do
				local t1 = i / steps
				local t2 = (i + 1) / steps
				local color1 = gradient.ColorSequence:Evaluate(t1)
				local color2 = gradient.ColorSequence:Evaluate(t2)

				local offsetLeft, offsetRight = 0, 0
				if cornerRadius > 0 then
					local yPos1 = i * stepHeight
					local yPos2 = (i + 1) * stepHeight

					if yPos1 < cornerRadius then
						local ratio = (cornerRadius - yPos1) / cornerRadius
						offsetLeft = cornerRadius * (1 - math.sqrt(1 - ratio ^ 2))
						offsetRight = offsetLeft
					end
					if yPos2 > (size.Y - cornerRadius) then
						local ratio = (yPos2 - (size.Y - cornerRadius)) / cornerRadius
						local bottomOffset = cornerRadius * (1 - math.sqrt(1 - ratio ^ 2))
						offsetLeft = math.max(offsetLeft, bottomOffset)
						offsetRight = math.max(offsetRight, bottomOffset)
					end
				end

				local sliceRec = structs.Rectangle:new({
					x = drawPos.X + offsetLeft,
					y = drawPos.Y + i * stepHeight,
					width = size.X - offsetLeft - offsetRight,
					height = stepHeight,
				})

				lib.DrawRectangleGradientEx(
					sliceRec,
					color1:ToRaylib(0),
					color1:ToRaylib(0),
					color2:ToRaylib(0),
					color2:ToRaylib(0)
				)
			end

			if stroke then
				if corner then
					if stroke.Transparency ~= 1 then
						lib.DrawRectangleRoundedLinesEx(
							rec,
							roundness,
							segments,
							stroke.Thickness,
							stroke.Color:ToRaylib(stroke.Transparency)
						)
					end
				else
					if stroke.Transparency ~= 1 then
						lib.DrawRectangleLinesEx(rec, stroke.Thickness, stroke.Color:ToRaylib(stroke.Transparency))
					end
				end
			end
		elseif corner then
			if object.Rotation ~= 0 then
				if object.BackgroundTransparency ~= 1 then
					lib.DrawRectanglePro(rec, origin, object.Rotation, color)
				end
			else
				if object.BackgroundTransparency ~= 1 then
					lib.DrawRectangleRounded(rec, roundness, segments, color)
				end
			end

			if stroke then
				if object.Rotation ~= 0 then
					if stroke.Transparency ~= 1 then
						lib.DrawRectangleLinesEx(rec, stroke.Thickness, stroke.Color:ToRaylib(stroke.Transparency))
					end
				else
					if stroke.Transparency ~= 1 then
						lib.DrawRectangleRoundedLinesEx(
							rec,
							roundness,
							segments,
							stroke.Thickness,
							stroke.Color:ToRaylib(stroke.Transparency)
						)
					end
				end
			end
		elseif stroke then
			if object.Rotation ~= 0 then
				if object.BackgroundTransparency ~= 1 then
					lib.DrawRectanglePro(rec, origin, object.Rotation, color)
				end
			else
				if object.BackgroundTransparency ~= 1 then
					lib.DrawRectangleRec(rec, color)
				end
			end
			if stroke.Transparency ~= 1 then
				lib.DrawRectangleLinesEx(rec, stroke.Thickness, stroke.Color:ToRaylib(stroke.Transparency))
			end
		else
			if object.BackgroundTransparency ~= 1 then
				lib.DrawRectanglePro(rec, origin, object.Rotation, color)
			end
		end

		object.AbsolutePosition = drawPos
		object.AbsoluteSize = size

		return drawPos, size
	end,
}

local function createSignals()
	return {
		MouseEnter = signal.new(),
		MouseLeave = signal.new(),
		MouseMoved = signal.new(),
		MouseWheelForward = signal.new(),
		MouseWheelBackward = signal.new(),
		TouchTap = signal.new(),
		TouchLongPress = signal.new(),
		InputBegan = signal.new(),
		InputChanged = signal.new(),
		InputEnded = signal.new(),
	}
end

return {
	class = "GuiObject",
	non_creatable = true,
	render = propTable.render,

	IsParentGuiContainer = function(object)
		return object.Parent.BaseClass == "UIContainer"
	end,

	renderChildren = function(lib, object, dt, structs, renderer)
		for _, child in pairs(object:GetChildren()) do
			if child.render then
				child.render(lib, child, dt, structs, renderer)
			end
		end
	end,

	calculatePositions = function(lib, object, dt, structs, renderer)
		local mousePos = Vector2.new(lib.GetMouseX(), lib.GetMouseY())
		object.MouseIsInObject = IsMouseInGuiRecursive(object, mousePos, lib)

		if object.MouseEnter then
			object.MouseEnter:FireOncePerPress("MouseEnter", object.MouseIsInObject)
		end
		if object.MouseLeave then
			object.MouseLeave:FireOncePerPress("MouseLeave", not object.MouseIsInObject)
		end

		local drawPos, size = calculateDrawParams(object, lib)

		object.AbsolutePosition = drawPos
		object.AbsoluteSize = size

		return drawPos, size
	end,

	callback = function(instance, renderer)
		local signals = createSignals()

		for k, v in pairs(signals) do
			propTable[k] = v
		end

		instance:SetProperties(propTable)
		return instance
	end,

	inherit = function(tble)
		local signals = createSignals()

		for k, v in pairs(signals) do
			tble[k] = v
		end

		for prop, val in pairs(propTable) do
			if not tble[prop] then
				tble[prop] = val
			end
		end
	end,
}
