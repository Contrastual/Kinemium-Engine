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
local const = r3d.constants
local rlib = r3d.lib

local material_shader_manager = require("./materialShaders/_main")

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
		MAX_VIEW_DISTANCE = 4000,
		UseGpuInstancing = true,
		MinInstancesPerBatch = 2,
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
		local pos = part.CFrame and part.CFrame.Position or part.Position
		local cx, cy, cz = worldToChunk(pos)
		local key = cx .. "," .. cy .. "," .. cz

		local chunk = chunks[key]
		if not chunk then
			chunk = {
				parts = {},
				aabbMin = Vector3.new(cx * CHUNK_SIZE, cy * CHUNK_SIZE, cz * CHUNK_SIZE),
				aabbMax = Vector3.new((cx + 1) * CHUNK_SIZE, (cy + 1) * CHUNK_SIZE, (cz + 1) * CHUNK_SIZE),
				dirty = true,
				batches = {},
				singleParts = {},
			}
			chunks[key] = chunk
		end

		chunk.parts[#chunk.parts + 1] = part
		chunk.dirty = true
		rawset(part, "__workspaceChunk", chunk)
		rawset(part, "__workspaceChunkKey", key)
	end

	local function markChunkDirty(chunk)
		if chunk then
			chunk.dirty = true
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
		if not chunk then
			return
		end

		local idx = table.find(chunk.parts, part)
		if idx then
			table.remove(chunk.parts, idx)
		end
		chunk.dirty = true

		rawset(part, "__workspaceChunk", nil)
		rawset(part, "__workspaceChunkKey", nil)

		if #chunk.parts <= 0 and key then
			unloadChunkBatches(chunk)
			chunks[key] = nil
		end
	end

	local function updatePartChunk(part)
		local oldChunk = rawget(part, "__workspaceChunk")
		local oldKey = rawget(part, "__workspaceChunkKey")
		local pos = part.CFrame and part.CFrame.Position or part.Position
		local cx, cy, cz = worldToChunk(pos)
		local newKey = cx .. "," .. cy .. "," .. cz

		if oldKey == newKey then
			markChunkDirty(oldChunk)
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
				return
			end

			if
				prop == "Size"
				or prop == "Color"
				or prop == "Transparency"
				or prop == "Material"
				or prop == "Shape"
				or prop == "Destroyed"
			then
				markChunkDirty(rawget(part, "__workspaceChunk"))
			end
		end)

		rawset(part, "__workspaceRenderConn", conn)
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
		if isRenderable(v) then
			addPart(v)
			watchRenderablePart(v)
			signal:Fire("UpdatePart", v)
			pool[v.UniqueId]._renderable = true
			table.insert(renderablePool, v)
		end
		IdPool = proptable.Pool.GetAllUniqueIds()
	end)

	Workspace.DescendantRemoving:Connect(function(v)
		if isRenderable(v) then
			local conn = rawget(v, "__workspaceRenderConn")
			if conn and conn.Disconnect then
				conn:Disconnect()
			end
			rawset(v, "__workspaceRenderConn", nil)
			removePart(v)
		end
		pool[v.UniqueId] = nil
		IdPool = proptable.Pool.GetAllUniqueIds()
		local idx = table.find(renderablePool, v)
		if idx then
			table.remove(renderablePool, idx)
		end
	end)

	for _, child in pairs(Workspace:GetDescendants()) do
		pool[child.UniqueId] = child
		if isRenderable(child) then
			addPart(child)
			watchRenderablePart(child)
			pool[child.UniqueId]._renderable = true
			table.insert(renderablePool, child)
		end
		IdPool = proptable.Pool.GetAllUniqueIds()
	end

	local function getInstancedMaterial(materialName)
		local cached = instancedMaterialCache[materialName]
		if cached then
			return cached
		end

		local matData = loadedMaterials[materialName]
		if not matData then
			return nil
		end

		local material = buffer.create(r3d.structs.R3D_Material:size())
		buffer.copy(material, 0, matData.material, 0, r3d.structs.R3D_Material:size())
		buffer.writei32(material, r3d.structs.R3D_Material:offset("transparencyMode"), 1)
		buffer.writei32(material, r3d.structs.R3D_Material:offset("cullMode"), 1)

		instancedMaterialCache[materialName] = material
		return material
	end

	local function queueSinglePartDraw(part, r3dAABB)
		local shapeName = part.Shape and part.Shape.Value
		local materialName = part.Material and part.Material.Value
		if not shapeName or not materialName then
			return
		end

		local meshData = preloadedMeshes and preloadedMeshes[shapeName]
		local matData = loadedMaterials[materialName]
		if not meshData or not matData then
			return
		end

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
		buffer.copy(tmpAlbedo, r3d.structs.R3D_AlbedoMap:offset("color"), part.Color:ToRaylib(part.Transparency or 0))

		local tmpMaterial = buffer.create(r3d.structs.R3D_Material:size())
		buffer.copy(tmpMaterial, 0, matData.material, 0, r3d.structs.R3D_Material:size())
		buffer.copy(tmpMaterial, r3d.structs.R3D_Material:offset("albedo"), tmpAlbedo)
		buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("transparencyMode"), 1)
		buffer.writei32(tmpMaterial, r3d.structs.R3D_Material:offset("cullMode"), 1)

		local materialShader = mtsh_sh[materialName]
		local applyPerObject = materialShader and (materialShader.Apply3Dbj or materialShader.Apply3DObj)
		if applyPerObject then
			applyPerObject(part, tmpAlbedo, tmpMaterial)
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
				for i = 1, count do
					local part = batch.parts[i]
					local position = part.CFrame and part.CFrame.Position or part.Position
					local size = part.Size
					local qx, qy, qz, qw = part.CFrame:ToQuaternion()
					local r, g, b = part.Color:ToRGB()
					local alpha = math.clamp(math.floor(255 * (1 - (part.Transparency or 0))), 0, 255)

					local pOffset = (i - 1) * INSTANCE_POSITION_STRIDE
					mappedPosition:writef32(pOffset, position.X)
					mappedPosition:writef32(pOffset + 4, position.Y)
					mappedPosition:writef32(pOffset + 8, position.Z)

					local rOffset = (i - 1) * INSTANCE_ROTATION_STRIDE
					mappedRotation:writef32(rOffset, qx)
					mappedRotation:writef32(rOffset + 4, qy)
					mappedRotation:writef32(rOffset + 8, qz)
					mappedRotation:writef32(rOffset + 12, qw)

					local sOffset = (i - 1) * INSTANCE_SCALE_STRIDE
					mappedScale:writef32(sOffset, size.X)
					mappedScale:writef32(sOffset + 4, size.Y)
					mappedScale:writef32(sOffset + 8, size.Z)

					local cOffset = (i - 1) * INSTANCE_COLOR_STRIDE
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

			for i = 1, count do
				local part = batch.parts[i]
				local position = part.CFrame and part.CFrame.Position or part.Position
				local size = part.Size
				local qx, qy, qz, qw = part.CFrame:ToQuaternion()
				local r, g, b = part.Color:ToRGB()
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

	local function rebuildChunkBatches(chunk)
		unloadChunkBatches(chunk)
		chunk.batches = {}
		chunk.singleParts = {}

		for i = 1, #chunk.parts do
			local part = chunk.parts[i]
			if not isRenderable(part) or part.Destroyed then
				continue
			end

			local shapeName = part.Shape and part.Shape.Value
			local materialName = part.Material and part.Material.Value
			local meshData = shapeName and preloadedMeshes[shapeName]
			local matData = materialName and loadedMaterials[materialName]

			if not meshData or not matData then
				continue
			end

			local materialShader = mtsh_sh[materialName]
			local hasPerObjectShader = materialShader and (materialShader.Apply3Dbj or materialShader.Apply3DObj)
			local canInstance = Workspace.UseGpuInstancing
				and renderer.MeshPool.DrawMeshInstanced ~= nil
				and not hasPerObjectShader

			if canInstance then
				local key = shapeName .. "|" .. materialName
				local batch = chunk.batches[key]
				if not batch then
					local instancedMaterial = getInstancedMaterial(materialName)
					if not instancedMaterial then
						table.insert(chunk.singleParts, part)
						continue
					end

					batch = {
						mesh = meshData[2],
						material = instancedMaterial,
						parts = {},
						count = 0,
						instanceBuffer = nil,
						capacity = 0,
					}
					chunk.batches[key] = batch
				end
				table.insert(batch.parts, part)
			else
				table.insert(chunk.singleParts, part)
			end
		end

		for _, batch in pairs(chunk.batches) do
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
	end

	local function drawChunks()
		local Kinemium_camera = Workspace.Camera
		if not Kinemium_camera then
			return
		end

		if
			Workspace.UseGpuInstancing ~= lastUseGpuInstancing
			or Workspace.MinInstancesPerBatch ~= lastMinInstancesPerBatch
		then
			lastUseGpuInstancing = Workspace.UseGpuInstancing
			lastMinInstancesPerBatch = Workspace.MinInstancesPerBatch
			for _, chunk in pairs(chunks) do
				chunk.dirty = true
			end
		end

		local camPos = Kinemium_camera.CFrame.Position

		for _, chunk in pairs(chunks) do
			if chunkVisible(chunk, camPos, Workspace.MAX_VIEW_DISTANCE) then
				if chunk.dirty then
					rebuildChunkBatches(chunk)
				end

				local r3dAABB = structs.BoundingBox:new({
					min = vector.create(chunk.aabbMin.X, chunk.aabbMin.Y, chunk.aabbMin.Z),
					max = vector.create(chunk.aabbMax.X, chunk.aabbMax.Y, chunk.aabbMax.Z),
				})

				for i = 1, #chunk.singleParts do
					queueSinglePartDraw(chunk.singleParts[i], r3dAABB)
				end

				for _, batch in pairs(chunk.batches) do
					if #batch.parts >= Workspace.MinInstancesPerBatch then
						if not batch.instanceBuffer then
							local ok = uploadBatchInstances(batch)
							if not ok then
								for i = 1, #batch.parts do
									queueSinglePartDraw(batch.parts[i], r3dAABB)
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
						for i = 1, #batch.parts do
							queueSinglePartDraw(batch.parts[i], r3dAABB)
						end
					end
				end
			end
		end
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
