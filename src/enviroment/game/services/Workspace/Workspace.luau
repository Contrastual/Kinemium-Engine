local Instance = require("@Instance")
local Vector3 = require("@Vector3")
local Workspace = Instance.new("Workspace")
local Enum = require("@EnumMap")
local pool = {}
local renderablePool = {}
local RaycastResult = require("@RaycastResult")

local raylib = require("@raylib")
local structs = raylib.structs
local r3d = require("@r3d")
local const = r3d.constants
local rlib = r3d.lib

local material_shader_manager = require("./materialShaders/_main")

local CHUNK_SIZE = 32
local chunks = {}
local chunkList = {}

local function worldToChunk(pos)
	if not pos then
		return 0, 0, 0
	end
	return math.floor(pos.X / CHUNK_SIZE), math.floor(pos.Y / CHUNK_SIZE), math.floor(pos.Z / CHUNK_SIZE)
end

Workspace.InitRenderer = function(renderer, signal, game)
	table.clear(chunks)
	table.clear(chunkList)
	table.clear(pool)
	table.clear(renderablePool)

	local IdPool = {}
	local visibleChunks = {}
	local visibleChunkCacheDirty = true
	local lastVisibleChunkSettingsKey = nil
	local lastVisibilityCameraPos = nil
	local lastVisibilityCameraLook = nil
	local lastVisibilityMaxDistance = nil

	local mtsh_sh = material_shader_manager:AddFilters()

	local proptable = {
		Gravity = -9.81,
		GlobalWind = Vector3.new(0, 0, 0),
		FallenPartsDestroyHeight = 90,
		AirTurbulenceIntensity = 0,
		AirDensity = 0,
		StreamingEnabled = false,
		UseFixedSimulation = true,
		PlayerScriptsUseInputActionSystem = true,
		NextGenerationReplication = true,
		ServerAuthority = {
			AuthorityMode = Enum.AuthorityMode.Client,
		},
		PhysicsEngine = Enum.PhysicsEngine.Default, -- jolt

		-- rendering
		MAX_VIEW_DISTANCE = 40000,
		UseGpuInstancing = true,
		MinInstancesPerBatch = 10,
		EnableViewFrustumCulling = true,
		ViewFrustumPadding = 12,
		VisibilityRefreshDistance = 16,
		VisibilityRefreshDotThreshold = 0.9925,
		EnableDefaultPlayerMenu = true,

		ChunkRebuildBudget = 8,
		ChunkInstanceUpdateBudget = 20,

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

	local function markVisibleChunkCacheDirty()
		visibleChunkCacheDirty = true
	end

	local function makeChunk(cx, cy, cz, key)
		local min = Vector3.new(cx * CHUNK_SIZE, cy * CHUNK_SIZE, cz * CHUNK_SIZE)
		local max = Vector3.new((cx + 1) * CHUNK_SIZE, (cy + 1) * CHUNK_SIZE, (cz + 1) * CHUNK_SIZE)
		local center = Vector3.new((min.X + max.X) * 0.5, (min.Y + max.Y) * 0.5, (min.Z + max.Z) * 0.5)
		local halfExtentX = (max.X - min.X) * 0.5
		local halfExtentY = (max.Y - min.Y) * 0.5
		local halfExtentZ = (max.Z - min.Z) * 0.5
		local chunk = {
			key = key,
			parts = {},
			aabbMin = min,
			aabbMax = max,
			center = center,
			boundsRadius = math.sqrt(halfExtentX * halfExtentX + halfExtentY * halfExtentY + halfExtentZ * halfExtentZ),
			dirty = true,
			instanceDataDirty = true,
			batches = {},
			batchList = {},
			singleParts = {},
			r3dAABB = structs.BoundingBox:new({
				min = vector.create(min.X, min.Y, min.Z),
				max = vector.create(max.X, max.Y, max.Z),
			}),
		}

		chunk.listIndex = #chunkList + 1
		chunkList[chunk.listIndex] = chunk
		chunks[key] = chunk
		markVisibleChunkCacheDirty()

		return chunk
	end

	local function addPart(part)
		local pos = part.CFrame and part.CFrame.Position or part.Position
		local cx, cy, cz = worldToChunk(pos)
		local key = cx .. "," .. cy .. "," .. cz

		local chunk = chunks[key]
		if not chunk then
			chunk = makeChunk(cx, cy, cz, key)
		end

		chunk.parts[#chunk.parts + 1] = part
		chunk.dirty = true
		chunk.instanceDataDirty = true
		rawset(part, "__workspaceChunk", chunk)
		rawset(part, "__workspaceChunkKey", key)
		rawset(part, "__workspaceChunkIndex", #chunk.parts)
	end

	local function markChunkDirty(chunk, structureChanged)
		if chunk then
			if structureChanged == true then
				chunk.dirty = true
			end
			chunk.instanceDataDirty = true
		end
	end

	local function unloadChunkBatches(chunk)
		if not chunk or not chunk.batches then
			return
		end
		for _, batch in pairs(chunk.batches) do
			if batch.instanceBuffer then
				pcall(rlib.R3D_UnloadInstanceBuffer, batch.instanceBuffer)
				batch.instanceBuffer = nil
			end
		end
	end

	local function removePart(part)
		local chunk = rawget(part, "__workspaceChunk")
		local key = rawget(part, "__workspaceChunkKey")
		local index = rawget(part, "__workspaceChunkIndex")
		if not chunk then
			return
		end

		if index then
			local lastIndex = #chunk.parts
			local lastPart = chunk.parts[lastIndex]
			chunk.parts[index] = lastPart
			chunk.parts[lastIndex] = nil
			if lastPart and lastPart ~= part then
				rawset(lastPart, "__workspaceChunkIndex", index)
			end
		end
		chunk.dirty = true
		chunk.instanceDataDirty = true

		rawset(part, "__workspaceChunk", nil)
		rawset(part, "__workspaceChunkKey", nil)
		rawset(part, "__workspaceChunkIndex", nil)

		if #chunk.parts <= 0 and key then
			unloadChunkBatches(chunk)
			local listIndex = chunk.listIndex
			local lastChunk = chunkList[#chunkList]
			chunkList[listIndex] = lastChunk
			chunkList[#chunkList] = nil
			if lastChunk and lastChunk ~= chunk then
				lastChunk.listIndex = listIndex
			end
			chunks[key] = nil
			markVisibleChunkCacheDirty()
		end
	end

	local function updatePartChunk(part)
		local oldChunk = rawget(part, "__workspaceChunk")
		local oldKey = rawget(part, "__workspaceChunkKey")
		local pos = part.CFrame and part.CFrame.Position or part.Position
		local cx, cy, cz = worldToChunk(pos)
		local newKey = cx .. "," .. cy .. "," .. cz

		if oldKey == newKey then
			markChunkDirty(oldChunk, false)
			return
		end

		removePart(part)
		addPart(part)
	end

	local function watchRenderablePart(part)
		if rawget(part, "__workspaceRenderConn") ~= nil then
			return
		end

		local conn = part.Changed:Connect(function(prop)
			if prop == "Position" or prop == "CFrame" then
				updatePartChunk(part)
				-- Invalidate cached transform matrix (position/rotation changed)
				rawset(part, "__cachedMatrix", nil)
				-- For batched parts, mark the batch instance data as dirty so
				-- the GPU buffer is refreshed with the new position/rotation.
				local batch = rawget(part, "__workspaceBatch")
				if batch then
					batch.instancesDirty = true
				end
				return
			end

			if prop == "Size" then
				rawset(part, "__cachedMaterial", nil)
				rawset(part, "__cachedMatrix", nil)
				-- Batched parts need GPU buffer refresh; singleParts use the
				-- material/matrix cache which was just cleared above.
				local batch = rawget(part, "__workspaceBatch")
				if batch then
					batch.instancesDirty = true
					local chunk = rawget(part, "__workspaceChunk")
					if chunk then
						chunk.instanceDataDirty = true
					end
				end
			elseif prop == "Color" or prop == "Transparency" then
				rawset(part, "__cachedMaterial", nil)
				-- Same: only GPU update needed for batched parts.
				local batch = rawget(part, "__workspaceBatch")
				if batch then
					batch.instancesDirty = true
					local chunk = rawget(part, "__workspaceChunk")
					if chunk then
						chunk.instanceDataDirty = true
					end
				end
			elseif prop == "Material" or prop == "Shape" or prop == "MeshObject" or prop == "Destroyed" then
				markChunkDirty(rawget(part, "__workspaceChunk"), true)
				rawset(part, "__cachedMaterial", nil)
				rawset(part, "__cachedMatrix", nil)
			end
		end)

		rawset(part, "__workspaceRenderConn", conn)
	end

	local function chunkVisible(chunk, camera, camPos, maxDist)
		local toCenter = chunk.center - camPos
		local distSq = toCenter:MagnitudeSquared()
		local maxReach = maxDist + chunk.boundsRadius
		if distSq > (maxReach * maxReach) then
			return false
		end

		if not Workspace.EnableViewFrustumCulling then
			return true
		end

		local dist = math.sqrt(distSq)
		if dist <= chunk.boundsRadius then
			return true
		end

		local cf = camera.CFrame
		local forward = cf:GetLookVector()
		local right = cf:GetRightVector()
		local up = cf:GetUpVector()

		-- Roblox FieldOfView is vertical; derive horizontal from aspect ratio
		local viewport = camera.ViewportSize
		local aspect = viewport.X / viewport.Y

		local halfVFov = math.rad((camera.FieldOfView or 70) * 0.5)
		local halfHFov = math.atan(math.tan(halfVFov) * aspect)

		local padding = math.rad(Workspace.ViewFrustumPadding or 0)

		local tocNorm = toCenter / dist

		-- Check vertical frustum plane
		local dotForward = forward:Dot(tocNorm)
		local dotUp = up:Dot(tocNorm)
		local dotRight = right:Dot(tocNorm)

		local radiusAllowance = chunk.boundsRadius / dist

		-- Vertical cull
		local cosVFov = math.cos(halfVFov + padding)
		local vertAngle = math.abs(math.atan2(math.abs(dotUp), dotForward))
		if vertAngle > halfVFov + padding + math.asin(math.min(1, radiusAllowance)) then
			return false
		end

		-- Horizontal cull
		local cosHFov = math.cos(halfHFov + padding)
		local horizAngle = math.abs(math.atan2(math.abs(dotRight), dotForward))
		if horizAngle > halfHFov + padding + math.asin(math.min(1, radiusAllowance)) then
			return false
		end

		-- Behind camera cull (dot against forward with sphere allowance)
		if dotForward < -radiusAllowance then
			return false
		end

		return true
	end

	local meshlib = renderer.Mesh
	local materialList = renderer.Texture.GetMaterials()
	local loadedMaterials = {}
	local availableMaterials = {}
	local INSTANCE_POSITION_STRIDE = 12 -- vec3 (f32 x3)
	local INSTANCE_ROTATION_STRIDE = 16 -- quat (f32 x4)
	local INSTANCE_SCALE_STRIDE = 12 -- vec3 (f32 x3)
	local INSTANCE_COLOR_STRIDE = 4 -- rgba8
	local INSTANCE_FLAGS = bit32.bor(
		const.R3D_INSTANCE_POSITION,
		const.R3D_INSTANCE_ROTATION,
		const.R3D_INSTANCE_SCALE,
		const.R3D_INSTANCE_COLOR
	)
	local instancedMaterialCache = {}
	local lastUseGpuInstancing = true
	local lastMinInstancesPerBatch = 1

	local fallbackMaterial = {
		index = -1,
		material = rlib.R3D_GetDefaultMaterial(),
	}

	local preloadedMeshes
	if not IsHeadless then
		local stdMeshPreloadStart = os.clock()
		preloadedMeshes = meshlib.PreloadStandardMeshes()
		iodebug(string.format("Preloaded standard meshes in %.3fms", (os.clock() - stdMeshPreloadStart) * 1000))

		local default = rlib.R3D_GetDefaultMaterial()

		local material_index = 0
		for material_name, material_path in pairs(materialList) do
			local material = buffer.create(buffer.len(default))
			buffer.copy(material, 0, default)

			availableMaterials[material_name] = {
				index = material_index,
				material = material,
				path = material_path,
			}

			if mtsh_sh[material_name] then
				mtsh_sh[material_name].Apply(material)
			end

			material_index += 1
		end
	end

	proptable.materials = availableMaterials

	signal:Connect(function(route, data) end)

	local function isRenderable(obj)
		return obj:IsA("Part") or obj:IsA("MeshPart")
	end

	local function visitSubtree(root, callback)
		if not root then
			return
		end

		callback(root)
		for _, descendant in ipairs(root:GetDescendants()) do
			callback(descendant)
		end
	end

	local function registerWorkspaceObject(v)
		pool[v.UniqueId] = v
		IdPool[v.UniqueId] = v
		if isRenderable(v) and rawget(v, "__workspaceRenderableIndex") == nil then
			addPart(v)
			watchRenderablePart(v)
			signal:Fire("UpdatePart", v)
			pool[v.UniqueId]._renderable = true
			renderablePool[#renderablePool + 1] = v
			rawset(v, "__workspaceRenderableIndex", #renderablePool)
		end
	end

	local function unregisterWorkspaceObject(v)
		if isRenderable(v) then
			local conn = rawget(v, "__workspaceRenderConn")
			if conn and conn.Disconnect then
				conn:Disconnect()
			end
			rawset(v, "__workspaceRenderConn", nil)
			removePart(v)
		end
		pool[v.UniqueId] = nil
		IdPool[v.UniqueId] = nil
		local idx = rawget(v, "__workspaceRenderableIndex")
		if idx then
			local lastIndex = #renderablePool
			local lastRenderable = renderablePool[lastIndex]
			renderablePool[idx] = lastRenderable
			renderablePool[lastIndex] = nil
			if lastRenderable and lastRenderable ~= v then
				rawset(lastRenderable, "__workspaceRenderableIndex", idx)
			end
			rawset(v, "__workspaceRenderableIndex", nil)
		end
	end

	Workspace.DescendantAdded:Connect(function(v)
		visitSubtree(v, registerWorkspaceObject)
	end)

	Workspace.DescendantRemoving:Connect(function(v)
		visitSubtree(v, unregisterWorkspaceObject)
	end)

	for _, child in pairs(Workspace:GetDescendants()) do
		registerWorkspaceObject(child)
	end

	local function loadMaterial(materialName, sync)
		if loadedMaterials[materialName] then
			return loadedMaterials[materialName]
		end
		if not availableMaterials[materialName] or availableMaterials[materialName].loading then
			return nil
		end

		zune.task.spawn(function()
			local mtl_info = availableMaterials[materialName]
			local material = mtl_info.material

			mtl_info.loading = true

			local function read(path): (buffer?, string?)
				if not path then
					return nil, nil
				end
				local success, result = pcall(zune.fs.readFileSync, path, true)
				if success then
					return result, raylib.lib.GetFileExtension(path)
				else
					return nil, nil
				end
			end

			iodebug(string.format("Loading custom material %s", materialName))
			local materialLoadStart = os.clock()
			local data_albedo, data_albedo_ext = read(mtl_info.path.albedo)
			local data_normal, data_normal_ext = read(mtl_info.path.normal)
			local data_orm, data_orm_ext = read(mtl_info.path.orm)
			-- local data_emission, data_emission_ext = read(path.emission)
			iodebug(
				string.format(
					"Loaded custom material %s in %.3fms",
					materialName,
					(os.clock() - materialLoadStart) * 1000
				)
			)

			local materialProcessStart = os.clock()
			if data_albedo then
				iodebug(string.format("Found albedo map, processing"))
				local map = rlib.R3D_LoadAlbedoMapFromMemory(
					data_albedo_ext,
					data_albedo,
					buffer.len(data_albedo),
					raylib.const.WHITE
				)
				buffer.copy(
					material,
					r3d.structs.R3D_Material:offset("albedo"),
					map,
					0,
					r3d.structs.R3D_AlbedoMap:size()
				)
			end
			if data_normal then
				iodebug(string.format("Found normal map, processing"))
				local map = rlib.R3D_LoadNormalMapFromMemory(data_normal_ext, data_normal, buffer.len(data_normal), 1)
				buffer.copy(
					material,
					r3d.structs.R3D_Material:offset("normal"),
					map,
					0,
					r3d.structs.R3D_NormalMap:size()
				)
			end
			if data_orm then
				iodebug(string.format("Found ORM map, processing"))
				local map = rlib.R3D_LoadOrmMapFromMemory(data_orm_ext, data_orm, buffer.len(data_orm), 1, 1, 0)
				buffer.copy(material, r3d.structs.R3D_Material:offset("orm"), map, 0, r3d.structs.R3D_OrmMap:size())
			end
			if mtsh_sh[materialName] then
				mtsh_sh[materialName].Apply(material)
			end

			availableMaterials[materialName].loading = false

			loadedMaterials[materialName] = availableMaterials[materialName]

			iodebug(
				string.format(
					"Processed custom material %s in %.3fms",
					materialName,
					(os.clock() - materialProcessStart) * 1000
				)
			)
		end)
		return nil
	end

	local function getInstancedMaterial(materialName)
		-- local cached = instancedMaterialCache[materialName]
		-- if cached then
		-- 	return cached
		-- end

		-- local matData = loadedMaterials[materialName] or loadMaterial(materialName) or fallbackMaterial
		-- if not matData then
		-- 	return nil
		-- end

		-- local material = buffer.create(r3d.structs.R3D_Material:size())
		-- buffer.copy(material, 0, matData.material, 0, r3d.structs.R3D_Material:size())
		-- buffer.writei32(material, r3d.structs.R3D_Material:offset("transparencyMode"), 1)
		-- buffer.writei32(material, r3d.structs.R3D_Material:offset("cullMode"), 1)

		-- instancedMaterialCache[materialName] = material
		local matData = loadedMaterials[materialName] or loadMaterial(materialName) or fallbackMaterial
		return matData.material
	end

	local function queueSinglePartDraw(part, r3dAABB)
		local isMeshPart = part:IsA("MeshPart")
		local shapeName = part.Shape and part.Shape.Value
		local materialName = part.Material and part.Material.Value

		local mesh = nil
		if isMeshPart then
			if part.MeshObject and part.MeshObject._meshgenHandle then
				mesh = part.MeshObject._meshgenHandle
			end
		elseif shapeName then
			local meshData = preloadedMeshes and preloadedMeshes[shapeName]
			if meshData then
				mesh = meshData[2]
			end
		end

		if not mesh or not materialName then
			return
		end

		local matData = loadedMaterials[materialName] or loadMaterial(materialName) or fallbackMaterial
		if not matData then
			return
		end

		-- Cache the transform matrix per-part. Only recomputed when CFrame or Size
		-- changes (invalidated via watchRenderablePart). For static/anchored maps
		-- this eliminates the matrix decompose + multiply every frame.
		local matrix = rawget(part, "__cachedMatrix")
		if not matrix then
			matrix = part.CFrame:ToRaylibMatrixScale(part.Size, raylib.structs)
			rawset(part, "__cachedMatrix", matrix)
		end

		-- Cache the combined material buffer per-part. Only rebuilt when Color,
		-- Transparency, Size (UV scale), or Material changes -- NOT every frame.
		-- For a 1000-part map at 60fps this eliminates ~120,000 buffer.create()
		-- calls per second down to 0 for static geometry.
		local tmpMaterial = rawget(part, "__cachedMaterial")
		if not tmpMaterial then
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
				part.Color:ToRaylib(part.Transparency or 0)
			)

			tmpMaterial = buffer.create(r3d.structs.R3D_Material:size())
			buffer.copy(tmpMaterial, 0, matData.material, 0, r3d.structs.R3D_Material:size())
			buffer.copy(tmpMaterial, r3d.structs.R3D_Material:offset("albedo"), tmpAlbedo)
			buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("transparencyMode"), 1)
			buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("cullMode"), 1)

			local size = part.Size
			buffer.writef32(tmpMaterial, r3d.structs.R3D_Material:offset("uvScale"), size.X)
			buffer.writef32(tmpMaterial, r3d.structs.R3D_Material:offset("uvScale") + 4, size.Z)

			local materialShader = mtsh_sh[materialName]
			local applyPerObject = materialShader and (materialShader.Apply3Dbj or materialShader.Apply3DObj)
			if applyPerObject then
				applyPerObject(part, tmpAlbedo, tmpMaterial)
			end

			rawset(part, "__cachedMaterial", tmpMaterial)
		end

		renderer.MeshPool.DrawMesh(mesh, tmpMaterial, matrix, function()
			rlib.R3D_BeginCluster(r3dAABB)
		end, function()
			rlib.R3D_EndCluster()
		end)
	end

	local function uploadBatchInstances(batch)
		local count = #batch.parts
		if count <= 0 then
			return false
		end

		if batch.instanceBuffer and batch.capacity and batch.capacity < count then
			pcall(rlib.R3D_UnloadInstanceBuffer, batch.instanceBuffer)
			batch.instanceBuffer = nil
			batch.capacity = 0
		end

		if not batch.instanceBuffer then
			local okLoad, loadedBuffer = pcall(rlib.R3D_LoadInstanceBuffer, count, INSTANCE_FLAGS)
			if not okLoad or not loadedBuffer then
				return false
			end
			batch.instanceBuffer = loadedBuffer
			batch.capacity = count
		end

		local mappedPosition = nil
		local mappedRotation = nil
		local mappedScale = nil
		local mappedColor = nil

		local okMap = pcall(function()
			mappedPosition = rlib.R3D_MapInstances(batch.instanceBuffer, const.R3D_INSTANCE_POSITION)
			mappedRotation = rlib.R3D_MapInstances(batch.instanceBuffer, const.R3D_INSTANCE_ROTATION)
			mappedScale = rlib.R3D_MapInstances(batch.instanceBuffer, const.R3D_INSTANCE_SCALE)
			mappedColor = rlib.R3D_MapInstances(batch.instanceBuffer, const.R3D_INSTANCE_COLOR)
		end)

		local okUpload = false
		local mappedFlags = bit32.bor(
			mappedPosition and const.R3D_INSTANCE_POSITION or 0,
			mappedRotation and const.R3D_INSTANCE_ROTATION or 0,
			mappedScale and const.R3D_INSTANCE_SCALE or 0,
			mappedColor and const.R3D_INSTANCE_COLOR or 0
		)

		if okMap and mappedFlags == INSTANCE_FLAGS then
			local okWrite = pcall(function()
				-- Localize the parts array and stride constants to reduce table
				-- indexing and upvalue lookups in the hot inner loop.
				local parts = batch.parts
				local posStride = INSTANCE_POSITION_STRIDE
				local rotStride = INSTANCE_ROTATION_STRIDE
				local sclStride = INSTANCE_SCALE_STRIDE
				local clrStride = INSTANCE_COLOR_STRIDE
				for i = 1, count do
					local part = parts[i]
					local cf = part.CFrame
					local position = cf and cf.Position or part.Position
					local size = part.Size
					local qx, qy, qz, qw = cf:ToQuaternion()
					local color = part.Color
					local r, g, b = color:ToRGB()
					local alpha = math.clamp(math.floor(255 * (1 - (part.Transparency or 0))), 0, 255)

					local pOffset = (i - 1) * posStride
					mappedPosition:writef32(pOffset, position.X)
					mappedPosition:writef32(pOffset + 4, position.Y)
					mappedPosition:writef32(pOffset + 8, position.Z)

					local rOffset = (i - 1) * rotStride
					mappedRotation:writef32(rOffset, qx)
					mappedRotation:writef32(rOffset + 4, qy)
					mappedRotation:writef32(rOffset + 8, qz)
					mappedRotation:writef32(rOffset + 12, qw)

					local sOffset = (i - 1) * sclStride
					mappedScale:writef32(sOffset, size.X)
					mappedScale:writef32(sOffset + 4, size.Y)
					mappedScale:writef32(sOffset + 8, size.Z)

					local cOffset = (i - 1) * clrStride
					mappedColor:writeu8(cOffset, r)
					mappedColor:writeu8(cOffset + 1, g)
					mappedColor:writeu8(cOffset + 2, b)
					mappedColor:writeu8(cOffset + 3, alpha)
				end
			end)

			local okUnmap = pcall(rlib.R3D_UnmapInstances, batch.instanceBuffer, INSTANCE_FLAGS)
			okUpload = okWrite and okUnmap
		else
			if mappedFlags ~= 0 then
				pcall(rlib.R3D_UnmapInstances, batch.instanceBuffer, mappedFlags)
			end

			local positionBuffer = buffer.create(count * INSTANCE_POSITION_STRIDE)
			local rotationBuffer = buffer.create(count * INSTANCE_ROTATION_STRIDE)
			local scaleBuffer = buffer.create(count * INSTANCE_SCALE_STRIDE)
			local colorBuffer = buffer.create(count * INSTANCE_COLOR_STRIDE)

			local parts = batch.parts
			for i = 1, count do
				local part = parts[i]
				local cf = part.CFrame
				local position = cf and cf.Position or part.Position
				local size = part.Size
				local qx, qy, qz, qw = cf:ToQuaternion()
				local color = part.Color
				local r, g, b = color:ToRGB()
				local alpha = math.clamp(math.floor(255 * (1 - (part.Transparency or 0))), 0, 255)

				local pOffset = (i - 1) * INSTANCE_POSITION_STRIDE
				buffer.writef32(positionBuffer, pOffset, position.X)
				buffer.writef32(positionBuffer, pOffset + 4, position.Y)
				buffer.writef32(positionBuffer, pOffset + 8, position.Z)

				local rOffset = (i - 1) * INSTANCE_ROTATION_STRIDE
				buffer.writef32(rotationBuffer, rOffset, qx)
				buffer.writef32(rotationBuffer, rOffset + 4, qy)
				buffer.writef32(rotationBuffer, rOffset + 8, qz)
				buffer.writef32(rotationBuffer, rOffset + 12, qw)

				local sOffset = (i - 1) * INSTANCE_SCALE_STRIDE
				buffer.writef32(scaleBuffer, sOffset, size.X)
				buffer.writef32(scaleBuffer, sOffset + 4, size.Y)
				buffer.writef32(scaleBuffer, sOffset + 8, size.Z)

				local cOffset = (i - 1) * INSTANCE_COLOR_STRIDE
				buffer.writeu8(colorBuffer, cOffset, r)
				buffer.writeu8(colorBuffer, cOffset + 1, g)
				buffer.writeu8(colorBuffer, cOffset + 2, b)
				buffer.writeu8(colorBuffer, cOffset + 3, alpha)
			end

			okUpload = pcall(function()
				rlib.R3D_UploadInstances(batch.instanceBuffer, const.R3D_INSTANCE_POSITION, 0, count, positionBuffer)
				rlib.R3D_UploadInstances(batch.instanceBuffer, const.R3D_INSTANCE_ROTATION, 0, count, rotationBuffer)
				rlib.R3D_UploadInstances(batch.instanceBuffer, const.R3D_INSTANCE_SCALE, 0, count, scaleBuffer)
				rlib.R3D_UploadInstances(batch.instanceBuffer, const.R3D_INSTANCE_COLOR, 0, count, colorBuffer)
			end)
		end

		if not okUpload then
			pcall(rlib.R3D_UnloadInstanceBuffer, batch.instanceBuffer)
			batch.instanceBuffer = nil
			batch.capacity = 0
			return false
		end

		batch.count = count
		return true
	end

	local function refreshChunkInstanceBuffers(chunk)
		if not chunk or not chunk.batches then
			return
		end

		-- Per-batch dirty tracking: only re-upload GPU buffers for batches whose
		-- data has actually changed. Skips clean batches entirely, saving GPU
		-- bandwidth and Luau overhead when only a few parts move each frame.
		-- SinglParts don't have GPU instance buffers, so they're not touched here.
		for i = 1, #chunk.batchList do
			local batch = chunk.batchList[i]
			if batch.instancesDirty and #batch.parts >= Workspace.MinInstancesPerBatch then
				uploadBatchInstances(batch)
				batch.instancesDirty = false
			end
		end

		chunk.instanceDataDirty = false
	end

	local function rebuildChunkBatches(chunk)
		unloadChunkBatches(chunk)
		chunk.batches = {}
		chunk.batchList = {}
		chunk.singleParts = {}

		-- Per-rebuild transform deduplication table.
		-- Parts that share the exact CFrame (position + rotation) and Size with
		-- a previously-processed part are completely occluded — skip them to
		-- save draw calls and GPU overdraw. This catches accidentally duplicated
		-- or layered-but-identical geometry common in imported maps.
		-- The key encodes position and size to 0.01-stud precision and rotation
		-- (via quaternion) to 0.001 precision. q and -q are the same rotation
		-- so we normalise the sign before hashing.
		local seenTransforms = {}

		for i = 1, #chunk.parts do
			local part = chunk.parts[i]
			if not isRenderable(part) or part.Destroyed then
				continue
			end

			-- Deduplication: build a compact transform+size fingerprint and
			-- skip this part if one with the same shape already exists.
			do
				local cf = part.CFrame
				local pos = cf.Position
				local sz = part.Size
				local qx, qy, qz, qw = cf:ToQuaternion()
				-- Normalise quaternion sign so q and -q hash identically.
				if qw < 0 then
					qx, qy, qz, qw = -qx, -qy, -qz, -qw
				end
				local f = math.floor
				local key = f(pos.X * 100 + 0.5)
					.. ","
					.. f(pos.Y * 100 + 0.5)
					.. ","
					.. f(pos.Z * 100 + 0.5)
					.. ","
					.. f(sz.X * 100 + 0.5)
					.. ","
					.. f(sz.Y * 100 + 0.5)
					.. ","
					.. f(sz.Z * 100 + 0.5)
					.. ","
					.. f(qx * 1000 + 0.5)
					.. ","
					.. f(qy * 1000 + 0.5)
					.. ","
					.. f(qz * 1000 + 0.5)
					.. ","
					.. f(qw * 1000 + 0.5)
				if seenTransforms[key] then
					rawset(part, "__workspaceDuplicate", true)
					continue
				end
				seenTransforms[key] = true
				rawset(part, "__workspaceDuplicate", false)
			end

			local isMeshPart = part:IsA("MeshPart")
			local shapeName = part.Shape and part.Shape.Value
			local materialName = part.Material and part.Material.Value

			local mesh = nil
			local meshKey = ""
			if isMeshPart then
				if part.MeshObject and part.MeshObject._meshgenHandle then
					mesh = part.MeshObject._meshgenHandle
					meshKey = "meshobj_" .. part.UniqueId
				end
			elseif shapeName then
				local meshData = preloadedMeshes and preloadedMeshes[shapeName]
				if meshData then
					mesh = meshData[2]
					meshKey = shapeName
				end
			end

			local matData = materialName and loadedMaterials[materialName]
				or loadMaterial(materialName)
				or fallbackMaterial

			if not mesh or not matData then
				continue
			end

			local materialShader = mtsh_sh[materialName]
			local hasPerObjectShader = materialShader and (materialShader.Apply3Dbj or materialShader.Apply3DObj)
			local canInstance = Workspace.UseGpuInstancing
				and renderer.MeshPool.DrawMeshInstanced ~= nil
				and not hasPerObjectShader

			if canInstance then
				local key = meshKey .. "|" .. materialName
				local batch = chunk.batches[key]
				if not batch then
					local instancedMaterial = getInstancedMaterial(materialName)
					if not instancedMaterial then
						rawset(part, "__cachedMaterial", nil)
						rawset(part, "__cachedMatrix", nil)
						table.insert(chunk.singleParts, part)
						continue
					end

					batch = {
						mesh = mesh,
						material = instancedMaterial,
						parts = {},
						count = 0,
						instanceBuffer = nil,
						capacity = 0,
						instancesDirty = true,
					}
					chunk.batches[key] = batch
					chunk.batchList[#chunk.batchList + 1] = batch
				end
				-- Track which batch owns this part so Changed can mark only that
				-- batch dirty instead of the entire chunk.
				rawset(part, "__workspaceBatch", batch)
				table.insert(batch.parts, part)
			else
				-- Clear caches when falling back to single draw (no instancing)
				rawset(part, "__cachedMaterial", nil)
				rawset(part, "__cachedMatrix", nil)
				rawset(part, "__workspaceBatch", nil)
				table.insert(chunk.singleParts, part)
			end
		end

		for i = 1, #chunk.batchList do
			local batch = chunk.batchList[i]
			if #batch.parts >= Workspace.MinInstancesPerBatch then
				local ok = uploadBatchInstances(batch)
				if not ok then
					for i = 1, #batch.parts do
						table.insert(chunk.singleParts, batch.parts[i])
					end
				end
			end
		end

		chunk.dirty = false
		chunk.instanceDataDirty = false
	end

	local function drawChunks()
		raylib.lib.rlSetClipPlanes(0.1, Workspace.MAX_VIEW_DISTANCE)

		local Kinemium_camera = Workspace.Camera
		if not Kinemium_camera then
			return
		end

		local forceDirty = false
		if
			Workspace.UseGpuInstancing ~= lastUseGpuInstancing
			or Workspace.MinInstancesPerBatch ~= lastMinInstancesPerBatch
		then
			lastUseGpuInstancing = Workspace.UseGpuInstancing
			lastMinInstancesPerBatch = Workspace.MinInstancesPerBatch
			forceDirty = true
		end

		local camPos = Kinemium_camera.CFrame.Position
		local camLook = Kinemium_camera.CFrame:GetLookVector()
		local refreshDistance = Workspace.VisibilityRefreshDistance or 0
		local refreshDistanceSq = refreshDistance * refreshDistance
		local refreshDotThreshold = Workspace.VisibilityRefreshDotThreshold or 0.9925
		local settingsKey = table.concat({
			tostring(Workspace.MAX_VIEW_DISTANCE),
			tostring(Workspace.EnableViewFrustumCulling),
			tostring(Workspace.ViewFrustumPadding),
		}, "|")

		local shouldRefreshVisibleChunks = forceDirty
			or visibleChunkCacheDirty
			or lastVisibleChunkSettingsKey ~= settingsKey
			or lastVisibilityMaxDistance ~= Workspace.MAX_VIEW_DISTANCE
			or lastVisibilityCameraPos == nil
			or lastVisibilityCameraLook == nil

		-- Track whether the camera POSITION changed (not just rotation). The
		-- sort is keyed on distance-from-camera, so it only needs to re-run
		-- when position changes, not every camera look-direction change.
		local cameraPositionChanged = lastVisibilityCameraPos == nil

		if not shouldRefreshVisibleChunks then
			local cameraDelta = camPos - lastVisibilityCameraPos
			local camDeltaSq = cameraDelta:MagnitudeSquared()
			if camDeltaSq >= refreshDistanceSq then
				shouldRefreshVisibleChunks = true
				cameraPositionChanged = true
			elseif camLook:Dot(lastVisibilityCameraLook) <= refreshDotThreshold then
				shouldRefreshVisibleChunks = true
				-- rotation-only refresh: visible set may change but distances don't
			end
		end

		if shouldRefreshVisibleChunks then
			table.clear(visibleChunks)
			for i = 1, #chunkList do
				local chunk = chunkList[i]
				if chunk and chunkVisible(chunk, Kinemium_camera, camPos, Workspace.MAX_VIEW_DISTANCE) then
					visibleChunks[#visibleChunks + 1] = chunk
				end
			end

			-- Sort closest-first for rebuild budget prioritization. Only re-sort
			-- when camera position changed -- rotation doesn't change distances.
			if cameraPositionChanged or visibleChunkCacheDirty or forceDirty then
				table.sort(visibleChunks, function(a, b)
					local da = (a.center.X - camPos.X) ^ 2 + (a.center.Y - camPos.Y) ^ 2 + (a.center.Z - camPos.Z) ^ 2
					local db = (b.center.X - camPos.X) ^ 2 + (b.center.Y - camPos.Y) ^ 2 + (b.center.Z - camPos.Z) ^ 2
					return da < db
				end)
			end

			visibleChunkCacheDirty = false
			lastVisibleChunkSettingsKey = settingsKey
			lastVisibilityCameraPos = camPos
			lastVisibilityCameraLook = camLook
			lastVisibilityMaxDistance = Workspace.MAX_VIEW_DISTANCE
		end

		-- Per-frame streaming budgets: limit how many chunks are fully rebuilt
		-- (structure + GPU buffers) or partially refreshed (instance data only)
		-- each frame. This prevents a single import from causing a multi-frame
		-- GPU stall by spreading the work over several frames, exactly like
		-- Roblox's streaming renderer.
		local structureRebuildsDone = 0
		local instanceUpdatesDone = 0
		local rebuildBudget = Workspace.ChunkRebuildBudget or 8
		local instanceBudget = Workspace.ChunkInstanceUpdateBudget or 20

		for i = 1, #visibleChunks do
			local chunk = visibleChunks[i]

			-- Rebuild chunk structure (batch grouping + GPU buffer allocation)
			-- only while within the per-frame budget. Chunks that miss the
			-- budget this frame will be rebuilt in a subsequent frame (they
			-- continue to draw with whatever stale data they already have).
			if forceDirty or chunk.dirty then
				if structureRebuildsDone < rebuildBudget then
					rebuildChunkBatches(chunk)
					structureRebuildsDone += 1
				end
			elseif chunk.instanceDataDirty then
				if instanceUpdatesDone < instanceBudget then
					refreshChunkInstanceBuffers(chunk)
					instanceUpdatesDone += 1
				end
			end

			-- Always draw whatever data is currently ready for this chunk,
			-- even if it hasn't been (re)built yet this frame.
			local r3dAABB = chunk.r3dAABB

			for singleIndex = 1, #chunk.singleParts do
				queueSinglePartDraw(chunk.singleParts[singleIndex], r3dAABB)
			end

			for batchIndex = 1, #chunk.batchList do
				local batch = chunk.batchList[batchIndex]
				if #batch.parts >= Workspace.MinInstancesPerBatch then
					if not batch.instanceBuffer then
						local ok = uploadBatchInstances(batch)
						if not ok then
							for partIndex = 1, #batch.parts do
								queueSinglePartDraw(batch.parts[partIndex], r3dAABB)
							end
							continue
						end
					end

					renderer.MeshPool.DrawMeshInstanced(
						batch.mesh,
						batch.material,
						batch.instanceBuffer,
						batch.count,
						function()
							rlib.R3D_BeginCluster(r3dAABB)
						end,
						function()
							rlib.R3D_EndCluster()
						end
					)
				else
					for partIndex = 1, #batch.parts do
						queueSinglePartDraw(batch.parts[partIndex], r3dAABB)
					end
				end
			end
		end
	end

	proptable.loadMaterial = function(name)
		loadMaterial(name, true)
		return loadedMaterials[name]
	end
	Workspace:SetProperties(proptable)

	local activeRaycasts = {}

	function Workspace:Raycast(origin, direction, raycastParams)
		raycastParams = raycastParams or {}
		local FilterType = Enum.RaycastFilterType
		local filterType = raycastParams.FilterType or FilterType.Exclude
		local filterInstances = type(raycastParams.FilterDescendantsInstances) == "table"
				and raycastParams.FilterDescendantsInstances
			or {}

		local maxDistance = direction:Magnitude()
		local unitDir = direction:Unit()

		local ray = structs.Ray:new({
			position = vector.create(origin.X, origin.Y, origin.Z),
			direction = vector.create(unitDir.X, unitDir.Y, unitDir.Z),
		})

		local bestPart = nil
		local bestPoint = nil
		local bestNormal = nil
		local bestDist = maxDistance + 0.001
		local bestMat = nil

		local preloadedMeshes = renderer.Mesh
			and renderer.Mesh.GetPreloadedMeshes
			and renderer.Mesh.GetPreloadedMeshes()

		for _, part in ipairs(renderablePool) do
			local isFiltered = false

			if #filterInstances > 0 then
				local current = part
				while current do
					if table.find(filterInstances, current) then
						isFiltered = true
						break
					end
					current = current.Parent
				end
			end

			if filterType == FilterType.Include then
				if not isFiltered then
					continue
				end
			else -- Exclude
				if isFiltered then
					continue
				end
			end

			local cpuMeshData = nil
			if part:IsA("MeshPart") and part.MeshObject then
				cpuMeshData = part.MeshObject._cpuMeshData
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

			local matrix = part.CFrame:ToRaylibMatrixScale(part.Size, structs)

			local ok, collision = pcall(rlib.R3D_RaycastMesh, ray, cpuMeshData, matrix)
			if not ok or not collision then
				continue
			end

			local hit = buffer.readu8(collision, structs.RayCollision:offset("hit"))
			local distance = buffer.readf32(collision, structs.RayCollision:offset("distance"))

			if hit == 1 and distance <= maxDistance and distance < bestDist then
				bestDist = distance
				bestPart = part
				bestPoint = Vector3.new(
					buffer.readf32(collision, structs.RayCollision:offset("point")),
					buffer.readf32(collision, structs.RayCollision:offset("point") + 4),
					buffer.readf32(collision, structs.RayCollision:offset("point") + 8)
				)
				bestNormal = Vector3.new(
					buffer.readf32(collision, structs.RayCollision:offset("normal")),
					buffer.readf32(collision, structs.RayCollision:offset("normal") + 4),
					buffer.readf32(collision, structs.RayCollision:offset("normal") + 8)
				)
				bestMat = part.Material
			end
		end

		if raycastParams.VisualizeRay == true then
			table.insert(activeRaycasts, {
				org = origin,
				direction = direction,
				point = bestPoint or (origin + direction),
			})
		end

		local terrain = Workspace:FindFirstChild("Terrain")
		if terrain and terrain._chunks then
			local terrainFiltered = false
			if #filterInstances > 0 then
				local current = terrain
				while current do
					if table.find(filterInstances, current) then
						terrainFiltered = true
						break
					end
					current = current.Parent
				end
			end

			local shouldTestTerrain = true
			if filterType == FilterType.Include then
				if not terrainFiltered then
					shouldTestTerrain = false
				end
			else
				if terrainFiltered then
					shouldTestTerrain = false
				end
			end

			if shouldTestTerrain then
				local identity = raylib.lib.MatrixIdentity()
				for _, chunk in pairs(terrain._chunks) do
					if chunk._cpuMeshData then
						local ok, collision = pcall(rlib.R3D_RaycastMesh, ray, chunk._cpuMeshData, identity)
						if ok and collision then
							local hitValue = buffer.readu8(collision, structs.RayCollision:offset("hit"))
							local distValue = buffer.readf32(collision, structs.RayCollision:offset("distance"))

							if hitValue == 1 and distValue <= maxDistance and distValue < bestDist then
								bestDist = distValue
								bestPart = terrain
								bestPoint = Vector3.new(
									buffer.readf32(collision, structs.RayCollision:offset("point")),
									buffer.readf32(collision, structs.RayCollision:offset("point") + 4),
									buffer.readf32(collision, structs.RayCollision:offset("point") + 8)
								)
								bestNormal = Vector3.new(
									buffer.readf32(collision, structs.RayCollision:offset("normal")),
									buffer.readf32(collision, structs.RayCollision:offset("normal") + 4),
									buffer.readf32(collision, structs.RayCollision:offset("normal") + 8)
								)
								local matName = chunk.dominantMaterial or "Grass"
								bestMat = Enum.Material[string.upper(string.sub(matName, 1, 1)) .. string.sub(
									matName,
									2
								)] or Enum.Material.Grass
							end
						end
					end
				end
			end
		end

		if bestPart then
			return RaycastResult.new(bestPart, bestPoint, bestNormal, bestMat, bestDist)
		end

		return nil
	end

	if not IsHeadless then
		repeat
			task.wait()
		until renderer

		renderer.Pool.new("gizmo", function()
			for i, active in pairs(activeRaycasts) do
				local origin = active.org
				local hitPoint = active.point or (origin + active.direction)

				raylib.lib.DrawCylinderEx(
					vector.create(origin.X, origin.Y, origin.Z),
					vector.create(hitPoint.X, hitPoint.Y, hitPoint.Z),
					0.1,
					0.1,
					8,
					raylib.structs.Color:new({ r = 0, g = 0, b = 255, a = 255 })
				)

				activeRaycasts[i] = nil
			end
		end)

		renderer.Pool.new("3d", drawChunks)
	end
end

return Workspace
