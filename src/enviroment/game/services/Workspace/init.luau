local Instance = require("@Instance")
local Vector3 = require("@Vector3")
local Workspace = Instance.new("Workspace")
local Enum = require("@EnumMap")
local pool = {}
local renderablePool = {}

local raylib = require("@raylib")
local lib = raylib.lib
local structs = raylib.structs
local bufferUtils = require("@bufferUtils")
local r3d = require("@r3d")
local rlib = r3d.lib

local material_shader_manager = require("./Workspace/materialShaders")

local CHUNK_SIZE = 32
local chunks = {}

local function worldToChunk(pos)
	if not pos then
		return 0, 0, 0
	end
	return math.floor(pos.X / CHUNK_SIZE), math.floor(pos.Y / CHUNK_SIZE), math.floor(pos.Z / CHUNK_SIZE)
end

Workspace.InitRenderer = function(renderer, signal, game)
	local IdPool = {}

	local mtsh_sh = material_shader_manager:AddFilters()

	local proptable = {
		Gravity = -9.81,
		GlobalWind = Vector3.new(0, 0, 0),
		FallenPartsDestroyHeight = 90,
		AirTurbulenceIntensity = 0,
		AirDensity = 0,
		StreamingEnabled = false,
		PhysicsEngine = Enum.PhysicsEngine.Default, -- jolt

		-- rendering
		MAX_VIEW_DISTANCE = 150,
		EnableDefaultPlayerMenu = true,

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

		Get3DObjects = function()
			return renderablePool
		end,

		Pool = {
			GetAllUniqueIds = function()
				local result = {}
				for _, part in pairs(Workspace:GetDescendants()) do
					result[part.UniqueId] = part
				end
				return result
			end,

			GetIdPool = function()
				return IdPool
			end,

			GetPartByUniqueId = function(uniqueId)
				return IdPool[uniqueId]
			end,
		},
	}

	IdPool = proptable.Pool.GetAllUniqueIds()

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

	local meshlib = renderer.Mesh
	local materialList = renderer.Texture.GetMaterials()
	local loadedMaterials = {}
	local MAX_INSTANCES = 150000
	local MATRIX_SIZE = 64 -- 16 floats x 4 bytes = 64 bytes per matrix
	local COLOR_SIZE = 4 -- 4 bytes: R, G, B, A

	-- Batch storage: key = "shape|material", value = batch object
	local shapeMaterialBatches = {}

	local preloadedMeshes
	if not IsHeadless then
		preloadedMeshes = meshlib.PreloadStandardMeshes()

		local material_index = 0
		for material_name, material_path in pairs(materialList) do
			local default = rlib.R3D_GetDefaultMaterial()

			local normal = rlib.R3D_LoadNormalMap(material_path, 1)
			local albedo = rlib.R3D_LoadAlbedoMap(material_path, raylib.const.WHITE)

			loadedMaterials[material_name] = {
				index = material_index,
				material = default,
				--shader = mtsh_sh[material_name] and mtsh_sh[material_name].shader or nil,
			}

			if mtsh_sh[material_name] then
				mtsh_sh[material_name].Apply(default)
			end

			buffer.copy(albedo, r3d.structs.R3D_AlbedoMap:offset("color"), raylib.const.WHITE)
			buffer.copy(default, r3d.structs.R3D_Material:offset("normal"), normal, 0, r3d.structs.R3D_NormalMap:size())
			buffer.copy(default, r3d.structs.R3D_Material:offset("albedo"), albedo, 0, r3d.structs.R3D_AlbedoMap:size())

			material_index += 1
			iodebug(`Loaded custom material: {material_name}`)
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
			table.insert(renderablePool, v)
		end
		IdPool = proptable.Pool.GetAllUniqueIds()
	end)

	Workspace.DescendantRemoving:Connect(function(v)
		pool[v.UniqueId] = nil
		IdPool = proptable.Pool.GetAllUniqueIds()
		table.remove(renderablePool, table.find(renderablePool, v))
	end)

	for _, child in pairs(Workspace:GetDescendants()) do
		pool[child.UniqueId] = child
		if isRenderable(child) then
			pool[child.UniqueId]._renderable = true
		end
		IdPool = proptable.Pool.GetAllUniqueIds()
	end

	local function drawChunks()
		local Kinemium_camera = Workspace.Camera
		local camPos = Kinemium_camera.CFrame.Position
		local camTarget = Kinemium_camera.CFrame:GetLookVector()
		local camFovy = Kinemium_camera.FieldOfView

		for _, batch in pairs(shapeMaterialBatches) do
			batch.count = 0
		end

		for _, chunk in pairs(chunks) do
			if chunkVisible(chunk, camPos, Workspace.MAX_VIEW_DISTANCE) then
				for i = 1, #chunk.parts do
					local part = chunk.parts[i]

					if isRenderable(part) then
						local meshData = preloadedMeshes[part.Shape.Value]
						local matData = loadedMaterials[part.Material.Value]
						local matrix = part.CFrame:ToRaylibMatrixScale(part.Size, raylib.structs)
						local mesh = meshData[2]

						local tmpAlbedo = buffer.create(r3d.structs.R3D_AlbedoMap:size())

						buffer.copy(
							tmpAlbedo,
							0,
							matData.material,
							r3d.structs.R3D_Material:offset("albedo"),
							r3d.structs.R3D_AlbedoMap:size()
						)

						buffer.copy(
							tmpAlbedo,
							r3d.structs.R3D_AlbedoMap:offset("color"),
							part.Color:ToRaylib(part.Transparency)
						)

						local tmpMaterial = buffer.create(r3d.structs.R3D_Material:size())
						buffer.copy(tmpMaterial, 0, matData.material, 0, r3d.structs.R3D_Material:size())
						buffer.copy(tmpMaterial, r3d.structs.R3D_Material:offset("albedo"), tmpAlbedo)
						buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("transparencyMode"), 1)
						buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("cullMode"), 1)

						if mtsh_sh[part.Material.Value] then
							mtsh_sh[part.Material.Value].Apply3DObj(part, tmpAlbedo, tmpMaterial)
						end

						renderer.MeshPool.DrawMesh(mesh, tmpMaterial, matrix)

						--drawRaylibInstanced(part, meshBuf, matData)
					end
				end
			end
		end

		--[[
		for _, batch in pairs(shapeMaterialBatches) do
			if batch.count > 0 then
				lib.DrawMeshInstanced(batch.mesh, batch.material, batch.matrices, batch.count)
			end
		end
		--]]
	end

	Workspace:SetProperties(proptable)

	if not IsHeadless then
		repeat
			task.wait()
		until renderer
		renderer.Pool.new("3d", drawChunks)
	end
end

return Workspace
