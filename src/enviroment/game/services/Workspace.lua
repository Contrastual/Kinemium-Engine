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

local groups = {}

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
		if isRenderable(v) then
			signal:Fire("UpdatePart", v)
			pool[v.UniqueId]._renderable = true
		end
		print(`Added {v.Name} to render pool!`)
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

	local function drawPart(part)
		local preloadedData = preloadedMeshes[part.Shape.Value]
		local mesh = preloadedData and preloadedData[2]
		local model = part._model

		if not mesh and not model then
			return
		end

		local cam = Workspace.CurrentCamera
		if cam then
			drawRaylib(part, model, mesh)
		end
	end

	for _, child in pairs(Workspace:GetDescendants()) do
		pool[child.UniqueId] = child
		if isRenderable(child) then
			pool[child.UniqueId]._renderable = true
		end
	end

	local function drawParts()
		for id, object in pairs(pool) do
			if object._renderable then
				drawPart(object)

				if object.Position.Y <= 300 then
					--object:Destroy()
				end
			else
				if object.render then
					object.render(object, renderer, game)
				end
			end
		end
	end

	local function draw()
		renderer.Signal:Fire("WorkspaceStart")

		drawParts()

		local KinemiumPhysicsService = game:GetService("PhysicsService")
		KinemiumPhysicsService.setGravity(Workspace.Gravity, Workspace.GlobalWind)
		renderer.Signal:Fire("WorkspaceFinish")
	end

	proptable.DrawParts = drawParts
	proptable.Draw = draw
	proptable.RenderPart = drawPart
	proptable.RenderShadows = renderShadows
	proptable.Add3DStack = renderer.Add3DStack
	proptable.Add2DStack = renderer.Add2DStack
	Workspace:SetProperties(proptable)

	if not IsHeadless then
		renderer.Add3DStack(draw)
	end
end

return Workspace
