--!optimize 2
--!native

local raylib = require("./external/raylib")
local task = zune.task
local KiRend = {}
--local raygui = require("@raygui")

-- DEPENDENCIES
local skybox = require("./renderer/skybox")
local texture = require("./renderer/texture")
local signal = require("@Kinemium.signal")
local Vector2 = require("@Vector2")
local shader = require("./renderer/shader")
local freecam = require("./renderer/freecam")
local meshlib = require("./renderer/mesh")
local ki3d = require("@ki3d")
local ffi = zune.ffi
local utils = require("@bufferutils")

-- TYPES
export type KiRendConf = { width: number, height: number, maxFps: number, title: string }

-- RAYLIB INIT
local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs

function KiRend.new(config: KiRendConf)
	-- RAYLIB INIT
	lib.SetTraceLogLevel(const.TraceLogLevel.LOG_ERROR)
	lib.SetConfigFlags(const.ConfigFlags.FLAG_WINDOW_RESIZABLE)
	lib.SetConfigFlags(const.ConfigFlags.FLAG_MSAA_4X_HINT)

	lib.InitWindow(config.width, config.height, config.title)
	lib.SetTargetFPS(config.maxFps)
	ki3d.init()

	local function getSortedPool(pool)
		local sorted = {}
		for id, entry in pairs(pool) do
			table.insert(sorted, { id = id, entry = entry })
		end
		table.sort(sorted, function(a, b)
			return a.entry.priority < b.entry.priority
		end)
		return sorted
	end

	local blur = require("./renderer/guiblur")
	local activeCamera

	local normalShader = raylib.lib.LoadShader("./src/assets/shaders/normal.vs", "./src/assets/shaders/normal.fs")
	local depthShader = raylib.lib.LoadShader("./src/assets/shaders/depth.vs", "./src/assets/shaders/depth.fs")
	ki3d.SetPassShaders(normalShader, depthShader)

	local renderer_eventbus = signal.new()
	local renderer_hooks = {
		Before3D = {},
		After3D = {},
		After2D = {},
		Before2D = {},
		Renderstep = {},
		Afterstep = {},
		Shutdown = {},
	}
	local renderer_pool = {
		gui = {},
		object = {},
		gizmos = {},
	}
	local renderer_storage = {
		fonts = {},
	}
	local renderer_draw_calls = {}
	local renderer_meshes = {}
	local ENGINE_PROFILER = {}
	local globalShaderOverride = nil -- Shader to use instead of material's shader

	local newBlurInstance = blur.Init(config.width, config.height)
	local rendererObject

	local function allocateMeshColors(mesh: buffer, r: number, g: number, b: number, a: number)
		local vertexCount = buffer.readi32(mesh, structs.Mesh:offset("vertexCount"))
		local byteSize = vertexCount * 4 * ffi.types.u8:size() -- 4 bytes per vertex (RGBA)
		local colorsPtr = ffi.alloc(byteSize) -- allocate unsigned char array

		for i = 0, vertexCount - 1 do
			local base = i * 4
			colorsPtr:writeu8(base + 0, r) -- R
			colorsPtr:writeu8(base + 1, g) -- G
			colorsPtr:writeu8(base + 2, b) -- B
			colorsPtr:writeu8(base + 3, a) -- A
		end

		return colorsPtr
	end

	rendererObject = {
		Mesh = meshlib,
		Skybox = skybox,
		Freecam = freecam,
		Shader = shader,
		Raylib = raylib,
		Texture = texture(raylib.lib),
		Enable3D = true,
		Ki3d = ki3d,
		Blur = newBlurInstance,

		DrawFps = true,

		RuntimeLibrary = {
			lib = lib,
			drawModel = meshlib.drawModel,
			loadMaterialOnModel = meshlib.loadMaterialOnModel,
			LoadShader = shader.LoadShader,
			structs = structs,
			const = const,
			dt = lib.GetFrameTime(),
			time = lib.GetTime(),
		},

		EventBus = renderer_eventbus,

		Draw = raylib.lib,

		Hook = {
			new = function(
				hookListName: "Before3D" | "After3D" | "Before2D" | "After2D" | "Renderstep" | "Afterstep" | "Shutdown",
				cb
			)
				table.insert(renderer_hooks[hookListName], cb)
			end,
		},

		Font = {
			new = function(name, fontPath, size)
				local buf = utils.wrap(lib.LoadFontEx(fontPath, size, nil, 0), structs.Font)

				local texture = buf:getptr("texture", structs.Texture2D)
				raylib.lib.SetTextureFilter(texture:getraw(), raylib.const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
				raylib.lib.SetTextureWrap(texture:getraw(), raylib.const.TextureWrap.TEXTURE_WRAP_CLAMP)
				raylib.lib.GenTextureMipmaps(texture:getraw())

				renderer_storage.fonts[name] = buf:getraw()
				return buf:getraw()
			end,

			Get = function(name)
				return renderer_storage.fonts[name]
			end,

			getFontTexture = function(name)
				local buf = renderer_storage.fonts[name]
				local texture = zune.mem.slice(buf, structs.Font:offset("texture"), structs.Texture2D:size())
				return texture
			end,

			Remove = function(name)
				renderer_storage.fonts[name] = nil
			end,
		},

		MeshPool = {
			DrawMesh = function(mesh, material, object_shader, matrix, color)
				if object_shader then
					local wrapper = utils.wrap(material, structs.Material)
					wrapper.shader = utils.typepointer(object_shader)
				end

				table.insert(renderer_draw_calls, {
					mesh = mesh,
					material = material,
					matrix = matrix,
				})
			end,

			CreateMaterial = function(texture, shader)
				local default = lib.LoadMaterialDefault()
				lib.SetMaterialTexture(default, 0, texture)

				local wrapper = utils.wrap(default, structs.Material)
				wrapper.shader = utils.typepointer(shader)

				return wrapper
			end,

			AddMesh = function(mesh: buffer, mat_texture, mat_shader: buffer?)
				local default = lib.LoadMaterialDefault()
				lib.SetMaterialTexture(default, 0, texture)

				local wrapper = utils.wrap(default, structs.Material)
				wrapper.shader = utils.typepointer(mat_shader)

				local data = {
					id = math.random(0, 1000),
					mat = default,
				}

				table.insert(renderer_meshes, data)

				return data
			end,

			GetMesh = function(MeshId)
				for i, v in pairs(renderer_meshes) do
					if v.id == MeshId then
						return v
					end
				end
				return
			end,

			SetConfigMesh = function(meshId, prop, Value)
				for i, v in pairs(renderer_meshes) do
					if v.id == meshId then
						renderer_meshes[i][prop] = Value
						break
					end
				end
			end,

			RemoveMesh = function(id)
				for i, v in pairs(renderer_meshes) do
					if v.id == id then
						table.remove(renderer_meshes, i)
						break
					end
				end
			end,
		},

		Pool = {
			new = function(type: "2d" | "3d" | "gizmo", renderFn: () -> (), priority: number?)
				local id = math.random(1, 99999)
				local poolEntry = {
					render = renderFn,
					object = nil,
					priority = priority or 0,
				}

				if type == "2d" then
					renderer_pool.gui[id] = poolEntry
				elseif type == "3d" then
					renderer_pool.object[id] = poolEntry
				elseif type == "gizmo" then
					renderer_pool.gizmos[id] = poolEntry
				end

				return id
			end,

			SetPriority = function(id, newPriority: number)
				if renderer_pool.gui[id] then
					renderer_pool.gui[id].priority = newPriority
				elseif renderer_pool.object[id] then
					renderer_pool.object[id].priority = newPriority
				elseif renderer_pool.gizmos[id] then
					renderer_pool.gizmos[id].priority = newPriority
				end
			end,

			Destroy = function(id)
				renderer_pool.gui[id] = nil
				renderer_pool.object[id] = nil
				renderer_pool.gizmos[id] = nil
			end,
		},

		Audio = {
			new = function(audioPath, volume, pitch)
				local sound = lib.LoadSound(audioPath)
				if volume then
					lib.SetSoundVolume(sound, volume)
				end
				if pitch then
					lib.SetSoundPitch(sound, pitch)
				end

				return {
					IsPlaying = function()
						return lib.IsSoundPlaying(sound) == 1
					end,

					Pause = function()
						lib.PauseSound(sound)
					end,

					Play = function()
						raylib.lib.PlaySound(sound)
					end,

					Destroy = function()
						raylib.lib.UnloadSound(sound)
					end,
				}
			end,
		},
	}

	function rendererObject.GetViewMatrix()
		if activeCamera then
			return raylib.lib.GetCameraMatrix(activeCamera)
		end
		return
	end

	function rendererObject:GetProjectionMatrix()
		if activeCamera then
			return raylib.lib.rlGetMatrixProjection()
		end
		return
	end

	function rendererObject:GetInverseProjectionMatrix()
		local proj = self:GetProjectionMatrix()
		if not proj then
			return nil
		end
		if raylib.lib.MatrixInvert then
			return raylib.lib.MatrixInvert(proj)
		end
		return
	end

	function rendererObject:MakeKernelTex(kernelSize: number?)
		local ksize = kernelSize or 32

		local kernel = {}
		for i = 1, ksize do
			local sample = {
				x = math.random() * 2 - 1,
				y = math.random() * 2 - 1,
				z = math.random(),
			}

			local scale = i / ksize
			scale = 0.1 + 0.9 * scale * scale
			kernel[i] = { sample.x * scale, sample.y * scale, sample.z * scale }
		end

		local data = buffer.create(ksize * 3 * 4) -- 3 floats * 4 bytes each
		for i = 1, ksize do
			local v = kernel[i]
			buffer.writef32(data, (i - 1) * 12 + 0, v.x) -- offset in bytes
			buffer.writef32(data, (i - 1) * 12 + 4, v.y)
			buffer.writef32(data, (i - 1) * 12 + 8, v.z)
		end

		local img = lib.ImageFromBuffer(data, ksize, 1, 1, raylib.const.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R32G32B32)
		local tex = lib.LoadTextureFromImage(img)
		lib.UnloadImage(img) -- free CPU-side image
		return tex
	end

	function rendererObject:MakeNoiseTex(size: number?)
		local w = size or 4
		local h = w
		local pixelCount = w * h
		local data = buffer.create(pixelCount * 3)
		for i = 0, pixelCount - 1 do
			local r = math.random(0, 255)
			local g = math.random(0, 255)
			local b = math.random(0, 255)
			buffer.writeu8(data, i * 3, r)
			buffer.writeu8(data, i * 3 + 1, g)
			buffer.writeu8(data, i * 3 + 2, b)
		end

		local img = lib.ImageFromBuffer(data, w, h, 1, raylib.const.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8)
		local tex = lib.LoadTextureFromImage(img)
		lib.UnloadImage(img)
		return tex
	end

	function rendererObject:MakeDepthBuffer()
		local const = raylib.const
		local width, height = raylib.lib.GetRenderWidth(), raylib.lib.GetRenderHeight()

		local fbo = raylib.lib.rlLoadFramebuffer(width, height)
		raylib.lib.rlEnableFramebuffer(fbo)

		local depthTex = raylib.lib.rlLoadTextureDepth(width, height, true)
		raylib.lib.rlFramebufferAttach(fbo, depthTex, const.RL_ATTACHMENT_DEPTH, const.RL_ATTACHMENT_TEXTURE2D, 0)

		local normalTex =
			raylib.lib.rlLoadTexture(nil, width, height, const.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8, 1)

		raylib.lib.rlFramebufferAttach(
			fbo,
			normalTex,
			const.RL_ATTACHMENT_COLOR_CHANNEL0,
			const.RL_ATTACHMENT_TEXTURE2D,
			0
		)

		if not raylib.lib.rlFramebufferComplete(fbo) then
			error("Framebuffer not complete")
		end

		raylib.lib.rlDisableFramebuffer()

		self.FBO = fbo
		self.Depth = depthTex
		self.Normal = normalTex
	end

	function rendererObject:SetProfiler(profilerObject)
		ENGINE_PROFILER = profilerObject
	end

	function rendererObject:SetGlobalShader(shader)
		globalShaderOverride = shader
	end

	function rendererObject:MakeShader(name, ki3dConfig)
		return ki3d.filters.new(name, ki3dConfig)
	end

	function rendererObject:SetIcon(Texture)
		local engineIcon = lib.LoadImage(Texture)
		lib.SetWindowIcon(engineIcon)
	end

	function rendererObject:SetResizable()
		lib.SetConfigFlags(const.ConfigFlags.FLAG_WINDOW_RESIZABLE)
	end

	function rendererObject:Include()
		local caller = getfenv(2)
		for k, v in pairs(rendererObject) do
			caller[k] = v
		end
	end

	function rendererObject:UseRlCamera(raylibCam)
		activeCamera = raylibCam
	end

	function rendererObject:InitAudioDevice()
		lib.InitAudioDevice()
	end

	function rendererObject:Render3D()
		lib.BeginMode3D(activeCamera)
		lib.rlEnableBackfaceCulling()
		renderer_eventbus:Fire("Begin3D")

		for _, v in pairs(renderer_hooks.Before3D) do
			v(rendererObject.RuntimeLibrary)
		end

		for _, item in ipairs(getSortedPool(renderer_pool.object)) do
			local entry = item.entry
			if entry.render then
				entry.render(rendererObject.RuntimeLibrary)
			end
		end

		for i, drawCall in pairs(renderer_draw_calls) do
			local material = drawCall.material
			local shaderOverride = _G._globalShaderOverride or globalShaderOverride
			if shaderOverride then
				local wrapper = utils.wrap(material, structs.Material)
				wrapper.shader = utils.typepointer(shaderOverride)
			end
			raylib.lib.DrawMesh(drawCall.mesh, drawCall.material, drawCall.matrix)
			renderer_draw_calls[i] = nil
		end
		table.clear(renderer_draw_calls)

		for _, item in ipairs(getSortedPool(renderer_pool.gizmos)) do
			local entry = item.entry
			if entry.render then
				entry.render(rendererObject.RuntimeLibrary)
			end
		end

		for _, v in pairs(renderer_hooks.After3D) do
			v(rendererObject.RuntimeLibrary)
		end

		lib.rlDisableBackfaceCulling()
		lib.EndMode3D()
		renderer_eventbus:Fire("End3D")
	end

	function rendererObject:Render2D()
		for _, v in pairs(renderer_hooks.Before2D) do
			v(rendererObject.RuntimeLibrary)
		end

		for _, item in ipairs(getSortedPool(renderer_pool.gui)) do
			local gui = item.entry
			gui.render(lib, gui.object and gui.object() or nil, time, structs, rendererObject.RuntimeLibrary)
		end

		for _, v in pairs(renderer_hooks.After2D) do
			v(rendererObject.RuntimeLibrary)
		end

		if rendererObject.DrawFps then
			lib.DrawFPS(10, 10)
		end
	end

	function rendererObject:step(time)
		rendererObject.RuntimeLibrary.dt = lib.GetFrameTime()
		rendererObject.RuntimeLibrary.time = lib.GetTime()

		if ENGINE_PROFILER then
			ENGINE_PROFILER:NextFrame()
			ENGINE_PROFILER:Begin("Update")
		end

		--lib.SetWindowState(const.ConfigFlags.FLAG_BORDERLESS_WINDOWED_MODE)
		local delta = lib.GetFrameTime()

		for _, v in pairs(renderer_hooks.Renderstep) do
			v(delta)
		end

		renderer_eventbus:Fire("PreRender", delta)
		renderer_eventbus:Fire("RenderStepped", delta)

		time += delta

		if raylib.lib.IsWindowResized() == 1 then
			ki3d.UpdateRenderTextures(lib.GetRenderWidth(), lib.GetRenderHeight())
		end

		for name, keycode in pairs(const.KeyboardKey) do
			if lib.IsKeyPressed(keycode) == 1 then
				renderer_eventbus:Fire("Pressed", keycode)
			end
			if lib.IsKeyDown(keycode) == 1 then
				renderer_eventbus:Fire("IsKeyDown", keycode)
			end
			if lib.IsKeyReleased(keycode) == 1 then
				renderer_eventbus:Fire("IsKeyReleased", keycode)
			end
			if lib.IsKeyUp(keycode) == 1 then
				renderer_eventbus:Fire("IsKeyUp", keycode)
			end

			local mouseDelta = lib.GetMouseDelta()
			if mouseDelta.x ~= 0 or mouseDelta.y ~= 0 then
				renderer_eventbus:Fire("MouseMoved", mouseDelta)
			end

			local wheel = lib.GetMouseWheelMove()
			if wheel ~= 0 then
				renderer_eventbus:Fire("MouseWheel", wheel)
			end
		end

		if ENGINE_PROFILER then
			ENGINE_PROFILER:End()
			ENGINE_PROFILER:Begin("Render")
		end

		--lib.BeginTextureMode(viewport)
		lib.BeginDrawing()

		if rendererObject.Enable3D then
			ki3d.enabled = true
			-- New pipeline: KI3D owns depth, normal, and scene passes.
			-- drawFn is called up to 3 times (depth, normal, main) with shader overrides.
			ki3d:Frame(activeCamera, function()
				rendererObject:Render3D()
			end)
		end

		ki3d:Draw(activeCamera)

		--guiBlur:ApplyBlur()
		--guiBlur:DrawUnblurred(const.WHITE)
		renderer_eventbus:Fire("PreGuiRender")

		renderer_eventbus:Fire("GuiRender")

		rendererObject:Render2D()

		lib.EndDrawing()
		renderer_eventbus:Fire("Heartbeat", delta)

		if ENGINE_PROFILER then
			ENGINE_PROFILER:SetCounter("FPS", lib.GetFPS())
			ENGINE_PROFILER:End()
		end

		for _, v in pairs(renderer_hooks.Afterstep) do
			v(delta)
		end

		task.wait(0)
	end

	function rendererObject:Run()
		local time = 0.0

		while lib.WindowShouldClose() == 0 do
			rendererObject:step(time)
		end

		for _, callback in pairs(renderer_hooks.Shutdown) do
			local success, result = pcall(function()
				callback()
			end)
			if not success then
				warn(result)
			end
		end
	end

	function rendererObject:GetStats()
		local gui3DCount = 0
		local gui2DCount = 0
		local gizmoCount = 0

		for _ in pairs(renderer_pool.object) do
			gui3DCount = gui3DCount + 1
		end
		for _ in pairs(renderer_pool.gui) do
			gui2DCount = gui2DCount + 1
		end
		for _ in pairs(renderer_pool.gizmos) do
			gizmoCount = gizmoCount + 1
		end

		return {
			fps = lib.GetFPS(),
			time = lib.GetTime(),
			render3DCount = gui3DCount,
			render2DCount = gui2DCount,
			gizmoCount = gizmoCount,
			windowSize = {
				width = lib.GetRenderWidth(),
				height = lib.GetRenderHeight(),
			},
		}
	end

	return rendererObject
end

return KiRend
