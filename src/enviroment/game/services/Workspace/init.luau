--!optimize 2
--!native
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

local material_shader_manager = require("./Workspace/materialShaders")

local CHUNK_SIZE = 32
local chunks = {}

local function worldToChunk(pos)
	if not pos then
		return 0, 0, 0
	end
	return math.floor(pos.X / CHUNK_SIZE), math.floor(pos.Y / CHUNK_SIZE), math.floor(pos.Z / CHUNK_SIZE)
end

local function ShouldDrawPart(part, camPos, camForward, camFovy, screenWidth, screenHeight)
	local pos = part._posVec
	if not pos then
		-- cache position vector to avoid allocations
		pos = Vector3.new(part.CFrame.Position.X, part.CFrame.Position.Y, part.CFrame.Position.Z)
		part._posVec = pos
	else
		pos.X = part.CFrame.Position.X
		pos.Y = part.CFrame.Position.Y
		pos.Z = part.CFrame.Position.Z
	end

	-- radius of part for rough bounding sphere
	local s = part.Size
	local radius = math.sqrt(s.X * s.X + s.Y * s.Y + s.Z * s.Z) * 0.5

	--  distance culling
	local dx = pos.X - camPos.X
	local dy = pos.Y - camPos.Y
	local dz = pos.Z - camPos.Z
	local distSq = dx * dx + dy * dy + dz * dz
	local maxDist = 2000 * radius
	if distSq > maxDist * maxDist then
		return false
	end

	-- behind-camera culling (dot product)
	local toPartX, toPartY, toPartZ = dx, dy, dz
	local dot = camForward.X * toPartX + camForward.Y * toPartY + camForward.Z * toPartZ
	if dot <= -radius then
		return false
	end

	-- projected size = radius / sqrt(distSq) * screenHeight / tan(fovy/2)
	local projSize = radius / math.sqrt(distSq) * (screenHeight / math.tan(math.rad(camFovy * 0.5)))
	if projSize < 1 then
		return false
	end

	return true
end

Workspace.InitRenderer = function(renderer, signal, game)
	local IdPool = {}

	local mtsh_sh = material_shader_manager:AddFilters(renderer, game, raylib)

	local ki3d = renderer.Ki3d
	local shader = renderer.Shader
	local const = raylib.const

	local lights = ki3d.filters.new("lighting", {
		disableauto = true,
		shader = {
			vertex = "./src/assets/shaders/default_lit.vs",
			fragment = "./src/assets/shaders/default_lit.fs",
		},

		setuniforms = function(self, runtime)
			local lighting = game and game:GetService("Lighting")
			local workspace = game and game:GetService("Workspace")
			local shaderobj = runtime.shaderobj
			local Kinemium_camera = workspace.Camera

			local ambient = lighting.Ambient
			local sunDir = lighting:GetSunDirection()
			local daylight = lighting.GetDaylight()

			shader.SetShaderValueRaw(
				shaderobj,
				"globalAmbient",
				{ ambient.R, ambient.G, ambient.B },
				const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
			)
			shader.SetShaderValueRaw(
				shaderobj,
				"dirLightDir",
				{ -sunDir.X, -sunDir.Y, -sunDir.Z },
				const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
			)

			shader.SetShaderValueRaw(
				shaderobj,
				"dirLightColor",
				{ 1.0, 0.95, 0.8 },
				const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
			)
			shader.SetShaderValueRaw(
				shaderobj,
				"brightness",
				lighting.Brightness * daylight,
				const.ShaderUniformDataType.SHADER_UNIFORM_FLOAT
			)
			local shadowsEnabled = lighting.GlobalShadows ~= false
			shader.SetShaderValueRaw(
				shaderobj,
				"shadowStrength",
				shadowsEnabled and 0.85 or 0.0,
				const.ShaderUniformDataType.SHADER_UNIFORM_FLOAT
			)
			shader.SetShaderValueRaw(shaderobj, "shadowBias", 0.0025, const.ShaderUniformDataType.SHADER_UNIFORM_FLOAT)

			local pointLights = lighting:GetPointLights()
			local lightCount = math.min(#pointLights, 64)

			shader.SetShaderValueRaw(
				shaderobj,
				"lightCount",
				lightCount,
				const.ShaderUniformDataType.SHADER_UNIFORM_INT
			)

			for i = 1, lightCount do
				local light = pointLights[i]
				if light.Enabled then
					local idx = i - 1 -- 0-indexed for shader arrays

					shader.SetShaderValueRaw(
						shaderobj,
						string.format("lightPosRange[%d]", idx),
						{ light.Position.X, light.Position.Y, light.Position.Z, light.Range },
						const.ShaderUniformDataType.SHADER_UNIFORM_VEC4
					)

					shader.SetShaderValueRaw(
						shaderobj,
						string.format("lightColorIntensity[%d]", idx),
						{ light.Color.R, light.Color.G, light.Color.B, light.Intensity },
						const.ShaderUniformDataType.SHADER_UNIFORM_VEC4
					)
				end
			end

			shader.SetShaderValueRaw(shaderobj, "viewPos", {
				Kinemium_camera.CFrame.Position.X,
				Kinemium_camera.CFrame.Position.Y,
				Kinemium_camera.CFrame.Position.Z,
			}, const.ShaderUniformDataType.SHADER_UNIFORM_VEC3)
		end,
	})

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

	-- Pre-allocate instance buffers (SSBO-like behavior)
	local instanceMatricesBuf = zune.ffi.alloc(MAX_INSTANCES * MATRIX_SIZE)
	local instanceColorsBuf = zune.ffi.alloc(MAX_INSTANCES * COLOR_SIZE)

	-- Batch storage: key = "shape|material", value = batch object
	local shapeMaterialBatches = {}

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
				shader = mtsh_sh[material_name] and mtsh_sh[material_name].shader or nil,
			}

			lib.SetTextureWrap(texture, raylib.const.TextureWrap.TEXTURE_WRAP_REPEAT)

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

	local function drawRaylib(part, model, mesh, matData)
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

		local axis, angle = bufferUtils.EulerToAxisAngle(part.Rotation)
		local position = vector.create(part.CFrame.Position.X, part.CFrame.Position.Y, part.CFrame.Position.Z)
		local scale
		local tint = part.Color:ToRaylib(part.Transparency)
		local matData = loadedMaterials[part.Material.Value]

		if part._model then
			bufferUtils.SetModelTex(model, matData.texture)

			scale =
				vector.create(part.Size.X * part.MeshScale, part.Size.Y * part.MeshScale, part.Size.Z * part.MeshScale)
			lib.DrawModelEx(part._model, position, axis, angle, scale, tint)
		else
			bufferUtils.SetModelTex(model, matData.texture)
			scale = vector.create(part.Size.X, part.Size.Y, part.Size.Z)
			lib.BeginShaderMode(matData.shader or lights.shader)
			lib.DrawModelEx(model, position, axis, angle, scale, tint)
			lib.EndShaderMode()
		end
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

					if
						isRenderable(part)
						and ShouldDrawPart(
							part,
							vector.create(camPos.X, camPos.Y, camPos.Z),
							vector.create(camTarget.X, camTarget.Y, camTarget.Z),
							camFovy,
							lib.GetRenderWidth(),
							lib.GetRenderHeight()
						)
					then
						local meshData = preloadedMeshes[part.Shape.Value]
						local matData = loadedMaterials[part.Material.Value]
						local matrix = part.CFrame:ToRaylibMatrixScale(part.Size, raylib.structs)
						local mesh = meshData[2]

						if zune.platform.os == "linux" then 
							drawRaylib(part, meshData[1], mesh, matData)
						else
							renderer.MeshPool.DrawMesh(
								mesh,
								matData.material,
								matData.shader or lights.shader,
								matrix,
								{ part.Color.R, part.Color.G, part.Color.B, part.Transparency }
							)
						end

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
