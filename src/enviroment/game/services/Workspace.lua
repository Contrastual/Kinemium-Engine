--!optimize 2
--!native
local Instance = require("@Instance")
local Vector3 = require("@Vector3")
local Workspace = Instance.new("Workspace")
local Color3 = require("@Color3")
local Enum = require("@EnumMap")
local pool = {}

local raylib = require("@raylib")
local lib = raylib.lib
local r3d = raylib.r3d
local structs = raylib.structs

local function Color3ToRaylib(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

local allowed_to_render = {
	["Part"] = "Part",
	["MeshPart"] = "MeshPart",
	["BasePart"] = "BasePart",
	["Model"] = "Model",
}

--[[
chunks = {
  ["cx,cy,cz"] = {
      parts = {},
      aabbMin = Vector3,
      aabbMax = Vector3
  }
}

--]]

local CHUNK_SIZE = 32
local chunks = {}

local function worldToChunk(pos)
	if not pos then return 0, 0, 0 end
	return math.floor(pos.X / CHUNK_SIZE), math.floor(pos.Y / CHUNK_SIZE), math.floor(pos.Z / CHUNK_SIZE)
end

local function ShouldDrawPart(part, camera, cam_pos, cam_target, cam_fovy)
	local cx, cy, cz = part.Position.X, part.Position.Y, part.Position.Z
	local pos = vector.create(cx, cy, cz)

	local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
	local radius = vector.magnitude(vector.create(sx, sy, sz)) * 0.5

	local toPart = pos - cam_pos
	local dist = vector.magnitude(toPart)

	if dist > radius * 2000 then
		return false
	end

	if dist < radius then
		return true
	end

	local forward = cam_target - cam_pos
	local fwdLen = vector.magnitude(forward)
	if fwdLen < 0.0001 then
		return true
	end
	forward = forward / fwdLen

	if vector.dot(forward, toPart) <= -radius then
		return false
	end

	local screen = lib.GetWorldToScreen(pos, camera)
	local w = lib.GetScreenWidth()
	local h = lib.GetScreenHeight()

	if screen.x >= -radius and screen.x <= w + radius and screen.y >= -radius and screen.y <= h + radius then
		return true
	end

	local projected_size = radius / dist * (h / math.tan(math.rad(cam_fovy * 0.5)))

	if projected_size >= 1 then
		return true
	end

	return false
end

local function drawChunkWireframe(chunk)
	local min = chunk.aabbMin
	local max = chunk.aabbMax

	local center = vector.create((min.X + max.X) * 0.5, (min.Y + max.Y) * 0.5, (min.Z + max.Z) * 0.5)

	local size = Vector3.new(max.X - min.X, max.Y - min.Y, max.Z - min.Z)

	raylib.lib.DrawCubeWires(center, size.X, size.Y, size.Z, raylib.const.RED)
end

Workspace.InitRenderer = function(renderer, signal, game)
	local proptable = {
		Gravity = -9.81,
		GlobalWind = Vector3.new(0, 0, 0),
		FallenPartsDestroyHeight = 90,
		AirTurbulenceIntensity = 0,
		AirDensity = 0,
		StreamingEnabled = false,

		-- rendering
		MAX_VIEW_DISTANCE = 150,

		-- debugging
		IsInPool = function(part)
			for i, v in pairs(pool) do
				if v == part then
					return true
				end
			end
			return false
		end,

		GetPoolCount = function()
			return #pool
		end,
	}

	local function addPart(part)
		local cx, cy, cz = worldToChunk(part.Position)
		local key = cx .. "," .. cy .. "," .. cz

		local chunk = chunks[key]
		if not chunk then
			chunk = {
				parts = {},
				aabbMin = Vector3.new(cx * CHUNK_SIZE, cy * CHUNK_SIZE, cz * CHUNK_SIZE),
				aabbMax = Vector3.new((cx + 1) * CHUNK_SIZE, (cy + 1) * CHUNK_SIZE, (cz + 1) * CHUNK_SIZE),
			}
			chunks[key] = chunk
		end

		chunk.parts[#chunk.parts + 1] = part
		part._chunk = chunk
	end

	local function chunkVisible(chunk, camPos, maxDist)
		local min = chunk.aabbMin
		local max = chunk.aabbMax

		-- AABB center
		local cx = (min.X + max.X) * 0.5
		local cy = (min.Y + max.Y) * 0.5
		local cz = (min.Z + max.Z) * 0.5

		local dx = cx - camPos.X
		local dy = cy - camPos.Y
		local dz = cz - camPos.Z

		return (dx * dx + dy * dy + dz * dz) <= (maxDist * maxDist)
	end

	local Kinemium_camera = renderer.Kinemium_camera
	local raylib_camera = renderer.camera
	local meshlib = renderer.meshlib
	local materialList = renderer.materialList
	local loadedMaterials = {}

	local preloadedMeshes
	if not IsHeadless then
		preloadedMeshes = meshlib.PreloadStandardMeshes()

		local material_index = 0
		for material_name, material_path in pairs(materialList) do
			local texture = lib.LoadTexture(material_path)
			local default = lib.LoadMaterialDefault()
			lib.SetMaterialTexture(default, 0, texture)

			loadedMaterials[material_name] = {
				index = material_index,
				material = default,
				texture = texture,
			}
			material_index += 1
			print(`Loaded custom material: {material_name}`)
		end
	end

	proptable.materials = loadedMaterials

	signal:Connect(function(route, data) end)

	local function isRenderable(obj)
		return obj:IsA("Part") or obj:IsA("MeshPart")
	end

	Workspace.DescendantAdded:Connect(function(v)
		pool[v.UniqueId] = v
		addPart(v)
		if isRenderable(v) then
			signal:Fire("UpdatePart", v)
			pool[v.UniqueId]._renderable = true
		end
	end)

	Workspace.DescendantRemoving:Connect(function(v)
		pool[v.UniqueId] = nil
	end)

	local function drawRaylib(part, model, mesh)
		local data = loadedMaterials[part.Material.Value]
		if not part._raylibMatrix or part._lastCFrame ~= part.CFrame or part._lastSize ~= part.Size then
			part._raylibMatrix = part.CFrame:ToRaylibMatrixScale(part.Size, raylib.structs)
			part._lastCFrame = part.CFrame
			part._lastSize = part.Size
		end

		local matrix = part._raylibMatrix

		part._cfvec = part._cfvec or vector.create(0, 0, 0)
		part._sizevec = part._sizevec or vector.create(0, 0, 0)

		if part._lastCFrame ~= part.CFrame then
			part._cfvec = vector.create(part.CFrame.Position.X, part.CFrame.Position.Y, part.CFrame.Position.Z)
			part._lastCFrame = part.CFrame
		end

		if part._lastSize ~= part.Size then
			part._sizevec = vector.create(part.Size.X, part.Size.Y, part.Size.Z)
			part._lastSize = part.Size
		end

		local color

		if model then
			raylib.lib.DrawModel(model, part._cfvec, part.MeshScale or 1, raylib.const.WHITE)
		elseif mesh and data then
			raylib.lib.DrawMesh(mesh, data.material, matrix)
		else
			print(`  ERROR: Cannot draw - mesh={mesh}, data={data}`)
		end
	end

	for _, child in pairs(Workspace:GetDescendants()) do
		pool[child.UniqueId] = child
		if isRenderable(child) then
			pool[child.UniqueId]._renderable = true
		end
	end

	local camera = renderer.camera

	local function drawChunks()
		local camPos = Kinemium_camera.CFrame.Position
		local camTarget = Kinemium_camera.CFrame.LookVector
		local camFovy = Kinemium_camera.FieldOfView

		for _, chunk in pairs(chunks) do
			if chunkVisible(chunk, camPos, Workspace.MAX_VIEW_DISTANCE) then
				for i = 1, #chunk.parts do
					local part = chunk.parts[i]
					if
						isRenderable(part)
						and ShouldDrawPart(
							part,
							camera,
							vector.create(camPos.X, camPos.Y, camPos.Z),
							vector.create(camTarget.X, camTarget.Y, camTarget.Z),
							camFovy
						)
					then
						local mesh = preloadedMeshes[part.Shape.Value][2]
						drawRaylib(part, part._model, mesh)
					end
				end

				drawChunkWireframe(chunk)
			end
		end
	end

	local function draw()
		renderer.Signal:Fire("WorkspaceStart")

		drawChunks()

		local KinemiumPhysicsService = game:GetService("PhysicsService")
		KinemiumPhysicsService.setGravity(Workspace.Gravity, Workspace.GlobalWind)
		renderer.Signal:Fire("WorkspaceFinish")
	end

	proptable.Add3DStack = renderer.Add3DStack
	proptable.Add2DStack = renderer.Add2DStack
	Workspace:SetProperties(proptable)

	if not IsHeadless then
		renderer.Add3DStack(draw)
	end
end

return Workspace
