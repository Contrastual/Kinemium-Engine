local Color3 = require("@Color3")
local signal = require("@kinemium.signal")
local Enum = require("@EnumMap")
local ffi = zune.ffi

local CFrame = require("@CFrame")
local gizmo = require("@gizmo")

local propTable = {
	Color = Color3.new(0.5, 0.5, 0.5),
	Adornee = nil,
	CastShadows = false,
	Name = "Handles",

	-- signals
	MouseButton1Down = signal.new(),
	MouseButton1Up = signal.new(),
	MouseDrag = signal.new(),
	MouseEnter = signal.new(),
	MouseLeave = signal.new(),

	-- enum
	Style = Enum.HandlesStyle.Movement,

	_gizmoTransform = gizmo.newTransform(),
}

local fired = {}
local activeDrag = nil

return {
	class = "Handles",

	callback = function(instance, renderer)
		instance.Changed:Connect(function(prop)
			if prop == "Adornee" then
				local part = instance.Adornee
				if part == nil then
					return
				end
				if part and (part:IsA("Part") or part:IsA("MeshPart")) then
					local pos = part.CFrame.Position
					--	instance._gizmoTransform.translation = vector.create(pos.X, pos.Y, pos.Z)
				end
			end
		end)

		propTable.render = function(handles, renderer, datamodel)
			if handles.Adornee then
				local part = handles.Adornee

				local success = false

				local Position = renderer.Freecam.GetPos()
				local camPos = vector.create(Position.X, Position.Y, Position.Z)

				if handles.Style == Enum.HandlesStyle.Movement then
					success = gizmo.DrawGizmo3D(gizmo.GIZMO_TRANSLATE, handles._gizmoTransform, camPos)
				elseif handles.Style == Enum.HandlesStyle.Rotation then
					success = gizmo.DrawGizmo3D(gizmo.GIZMO_ROTATE, handles._gizmoTransform, camPos)
				elseif handles.Style == Enum.HandlesStyle.Resize then
					success = gizmo.DrawGizmo3D(gizmo.GIZMO_TRANSLATE, handles._gizmoTransform, camPos)
				end

				local t = handles._gizmoTransform
				local newCF = CFrame.new(t.translation.x, t.translation.y, t.translation.z)

				handles.Transform = newCF
				instance.MouseDrag:Fire(newCF)
			end
		end

		instance:SetProperties(propTable)

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
