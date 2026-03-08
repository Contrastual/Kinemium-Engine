local Color3 = require("@Color3")
local signal = require("@kinemium.signal")
local Enum = require("@EnumMap")
local ffi = zune.ffi
local CFrame = require("@CFrame")

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

	_gizmoTransform = ffi.alloc(12 + 16 + 12),
}

return {
	class = "Handles",

	callback = function(instance, renderer)
		local gizmo = require("@gizmo")

		instance.Changed:Connect(function(prop)
			if prop == "Adornee" then
				local part = instance.Adornee
				if part == nil then
					return
				end
				if part and (part:IsA("Part") or part:IsA("MeshPart")) then
					local pos = part.CFrame.Position
					instance._gizmoTransform:writef32(0, pos.X)
					instance._gizmoTransform:writef32(4, pos.Y)
					instance._gizmoTransform:writef32(8, pos.Z)
				end
			end
		end)

		propTable.render = function(handles, renderer, datamodel)
			if handles.Adornee then
				local part = handles.Adornee

				local success = false

				if handles.Style == Enum.HandlesStyle.Movement then
					success = gizmo.DrawGizmo3D(gizmo.Flags.TRANSLATE, handles._gizmoTransform)
				elseif handles.Style == Enum.HandlesStyle.Rotation then
					success = gizmo.DrawGizmo3D(gizmo.Flags.ROTATE, handles._gizmoTransform)
				elseif handles.Style == Enum.HandlesStyle.Resize then
					success = gizmo.DrawGizmo3D(gizmo.Flags.TRANSLATE, handles._gizmoTransform)
				end

				if success then
					local gizmoTransform = handles._gizmoTransform
					local newCF =
						CFrame.new(gizmoTransform:readf32(0), gizmoTransform:readf32(4), gizmoTransform:readf32(8))
					handles.Transform = newCF
					instance.MouseDrag:Fire(newCF)
				end
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
