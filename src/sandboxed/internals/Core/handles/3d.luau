local ffi = game:GetService("KinemiumFFI")
local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs
local renderer = rlservice.renderer
local Selection = game:GetService("Selection")
-- first time this service has ever been used in any script lmao

local StartCFrame
local StartSize

local gizmo = import("@gizmo")
local flags = gizmo.Flags

local Movement, Resize = Instance.new("Handles"), Instance.new("Handles")
Movement.Style = Enum.HandlesStyle.Movement
Resize.Style = Enum.HandlesStyle.Resize

local type = "MOVEMENT"
local ScaleDragging = true
local PreviousScale = vector.create(0, 0, 0)

-- Read Offsets:
-- 0, 4, 8 = Position (x,y,z) (Vector3)
-- 12, 16, 20, 24 = Rotation (x,y,z,w) (Quaternion)
-- 28, 32, 36 = Scale (x,y,z) (Vector3)

local connection

Selection.SelectionAdded:Connect(function(selected)
	Movement.Adornee = nil
	Resize.Adornee = nil
	if connection then
		connection:Disconnect()
	end
	if selected then
		if not selected:IsA("Part") then
			return
		end
		if type == "MOVEMENT" then
			Resize.Adornee = nil
			Movement.Adornee = selected
		elseif type == "SCALE" then
			Resize.Adornee = selected
		end
	end
end)

workspace.Add3DStack(function()
	Movement.render(Movement, renderer, game)
	Resize.render(Resize, renderer, game)

	local selected = Selection:Get()[1]

	if selected then
		if not selected:IsA("Part") and not selected:IsA("MeshPart") then
			return
		end

		local size = selected.Size

		if type == "MOVEMENT" then
			if not Movement.Transform then
				return
			end
			local pos = Movement.Transform.Position
			lib.DrawCubeWires(vector.create(pos.X, pos.Y, pos.Z), size.X, size.Y, size.Z, const.BLUE)

			if connection then
				connection:Disconnect()
			end
			connection = Movement.MouseDrag:Connect(function(newCF)
				selected.CFrame = newCF
			end)
		elseif type == "SCALE" then
			if connection then
				connection:Disconnect()
			end

			if not ScaleDragging then
				StartCFrame = selected.CFrame
				StartSize = selected.Size
				ScaleDragging = true
			end

			connection = Resize.MouseDrag:Connect(function(newCF)
				local startPos = StartCFrame.Position
				local t = newCF.Position

				local dx = (t.X - startPos.X)
				local dy = (t.Y - startPos.Y)
				local dz = (t.Z - startPos.Z)

				local newSize = Vector3.new(
					math.max(StartSize.X + dx, 0.01),
					math.max(StartSize.Y + dy, 0.01),
					math.max(StartSize.Z + dz, 0.01)
				)

				local offset = Vector3.new(
					(newSize.X - StartSize.X) / 2,
					(newSize.Y - StartSize.Y) / 2,
					(newSize.Z - StartSize.Z) / 2
				)

				selected.Size = newSize
				selected.CFrame = StartCFrame + offset
			end)
		end
	else
		ScaleDragging = false
	end
end)
