local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local Enum = require("@EnumMap")
local signal = require("@Kinemium.signal")
local Vector2 = require("@Vector2")

local raylib = require("@raylib")
local lib = raylib.lib
local r3d = require("@r3d")
local rlib = r3d.lib
local raycastMod = require("../../../modules/raycast")

local Button1Down = signal.new()
local Button1Up = signal.new()
local Button2Down = signal.new()
local Button2Up = signal.new()
local Move = signal.new()
local WheelForward = signal.new()
local WheelBackward = signal.new()

local propTable = {
	Icon = Enum.KinemiumMouseCursor.MOUSE_CURSOR_DEFAULT,
	Target = nil,
	Hit = nil,
	UnitRay = nil,
	TargetFilter = nil,

	IsMouseHidden = false,
	IsMouseOutOfBounds = false,

	X = 0,
	Y = 0,

	ViewSizeX = 0,
	ViewSizeY = 0,

	Button1Down = Button1Down,
	Button1Up = Button1Up,
	Button2Down = Button2Down,
	Button2Up = Button2Up,
	Move = Move,
	WheelForward = WheelForward,
	WheelBackward = WheelBackward,

	SetIcon = function(mouse, icon)
		mouse.Icon = icon
	end,

	GetScreenPosition = function(mouse)
		return mouse.X, mouse.Y
	end,

	Raycast = function(mouse, distance)
		return nil
	end,

	IsButtonDown = function(mouse, button)
		return false
	end,

	Name = "Mouse",
}

local function readRayCollision(buf)
	--[[
	local RayCollision = ffi.struct({
	{ hit = bool },
	{ distance = float },
	{ point = Vector3 },
	{ normal = Vector3 },
})
export type RayCollision = typeof(RayCollision:new({}))
	--]]
	local hit = buffer.readu8(buf, raylib.structs.RayCollision:offset("hit"))
	local distance = buffer.readf32(buf, raylib.structs.RayCollision:offset("distance"))
	local px = buffer.readf32(buf, raylib.structs.RayCollision:offset("point"))
	local py = buffer.readf32(buf, raylib.structs.RayCollision:offset("point") + 4)
	local pz = buffer.readf32(buf, raylib.structs.RayCollision:offset("point") + 8)
	local nx = buffer.readf32(buf, raylib.structs.RayCollision:offset("normal"))
	local ny = buffer.readf32(buf, raylib.structs.RayCollision:offset("normal") + 4)
	local nz = buffer.readf32(buf, raylib.structs.RayCollision:offset("normal") + 8)
	return {
		hit = hit,
		distance = distance,
		point = Vector3.new(px, py, pz),
		normal = Vector3.new(nx, ny, nz),
	}
end

return {
	class = "Mouse",
	non_creatable = true,
	callback = function(instance, renderer, game)
		instance:SetProperties(propTable)

		instance.Changed:Connect(function(property, value)
			if property == "Icon" then
				lib.SetMouseCursor(value.Value)
			end
		end)

		renderer.EventBus:Connect(function(route, data)
			if route == "MouseData" then
				local position = data.position
				local mouse_wheel_move = data.mouse_wheel_move

				instance.X = position.X
				instance.Y = position.Y
				instance.IsMouseHidden = data.is_cursor_hidden
				instance.IsMouseOutOfBounds = data.is_cursor_inbounds

				local bestPart = nil
				local bestPoint = nil
				local bestNormal = nil
				local bestDist = math.huge

				local Workspace = game and game.Workspace
				local camera = Workspace and Workspace.Camera
				local raylibCam = camera and camera._raylibcam

				if raylibCam and Workspace then
					local rayInfo = raycastMod:GetMouseRay(raylibCam)
					local ray = rayInfo.ray

					local preloadedMeshes = renderer.Mesh
						and renderer.Mesh.GetPreloadedMeshes
						and renderer.Mesh.GetPreloadedMeshes()

					local parts = Workspace:Get3DObjects()
					for _, part in ipairs(parts) do
						local isFiltered = false
						if instance.TargetFilter then
							local current = part
							local isTable = type(instance.TargetFilter) == "table"

							while current do
								if isTable then
									if table.find(instance.TargetFilter, current) then
										isFiltered = true
										break
									end
								else
									if instance.TargetFilter == current then
										isFiltered = true
										break
									end
								end
								current = current.Parent
							end
						end

						if isFiltered then
							continue
						end

						local cpuMeshData = nil

						if part:IsA("MeshPart") then
							if part.MeshObject then
								cpuMeshData = part.MeshObject._cpuMeshData
							end
						else
							local shapeName = part.Shape and part.Shape.Name and string.lower(part.Shape.Name)
							if shapeName == "ball" then
								shapeName = "sphere"
							end

							if shapeName and preloadedMeshes then
								local entry = preloadedMeshes[shapeName]
								if entry then
									cpuMeshData = entry[1]
								end
							end
						end

						if not cpuMeshData then
							continue
						end

						local matrix = part.CFrame:ToRaylibMatrixScale(part.Size, raylib.structs)

						local ok, collision = pcall(rlib.R3D_RaycastMesh, ray, cpuMeshData, matrix)
						if not ok or not collision then
							continue
						end

						local result = readRayCollision(collision)

						if result.hit == 1 and result.distance < bestDist then
							bestDist = result.distance
							bestPart = part
							bestPoint = result.point
							bestNormal = result.normal
						end
					end

					local terrain = Workspace:FindFirstChild("Terrain")
					if terrain and terrain._chunks then
						local identity = raylib.lib.MatrixIdentity()
						for _, chunk in pairs(terrain._chunks) do
							if chunk._cpuMeshData then
								local ok, collision = pcall(rlib.R3D_RaycastMesh, ray, chunk._cpuMeshData, identity)
								if ok and collision then
									local result = readRayCollision(collision)

									if result.hit == 1 and result.distance < bestDist then
										bestDist = result.distance
										bestPart = terrain
										bestPoint = result.point
										bestNormal = result.normal
									end
								end
							end
						end
					end
				end

				instance.Target = bestPart
				instance.target = bestPart
				instance.Hit = bestPoint and CFrame.new(bestPoint) or nil
				instance.hit = instance.Hit
				instance.TargetSurface = bestNormal

				if mouse_wheel_move then
					Move:Fire()
				end

				if data.Button1Down then
					Button1Down:Fire()
				end

				if data.Button1Released then
					Button1Up:Fire()
				end

				if data.Button2Down then
					Button2Down:Fire()
				end

				if data.Button2Released then
					Button2Up:Fire()
				end
			end
		end)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
