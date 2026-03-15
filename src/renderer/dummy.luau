--!optimize 2
--!native

local task = zune.task
local KiRend = {}

local signal = require("@Kinemium.signal")

local mockMeshlib = {
	LoadMesh = function()
		return {}
	end,
	UnloadMesh = function() end,
	GetMesh = function()
		return nil
	end,
	GenerateMesh = function()
		return {}, {}
	end,
	PreloadStandardMeshes = function()
		return {}
	end,
	GetModelRegistry = function()
		return {}
	end,
	drawModel = function() end,
	loadMaterialOnModel = function() end,
}

local mockSkybox = {
	Load = function() end,
	Unload = function() end,
	Draw = function() end,
	FromCubemap = function()
		return {}
	end,
}

local mockShader = {
	LoadShader = function()
		return {}
	end,
	LoadShaderCode = function()
		return {}
	end,
	GetShaderUniformLocation = function()
		return 0
	end,
	SetShaderUniform = function() end,
	SetShaderValueRaw = function() end,
	SetShaderTextureRaw = function() end,
	SetShaderTexture = function() end,
	UnloadShader = function() end,
}

local mockFreecam = {
	Update = function() end,
	SetSpeed = function() end,
	SetSensitivity = function() end,
	GetPos = function()
		return { X = 0, Y = 0, Z = 0 }
	end,
	SetCFrame = function() end,
	GetCFrame = function()
		return { Position = { X = 0, Y = 0, Z = 0 } }
	end,
}

local mockTexture = function()
	return {
		LoadTextureFromFile = function()
			return zune.ffi.null
		end,
		LoadTextureFromFileAsync = function()
			return zune.ffi.null
		end,
		GetMaterials = function()
			return {}
		end,
	}
end

local mockBlur = {
	Init = function(width, height)
		return {
			enabled = true,
			SetBlurRadius = function() end,
			BeginCapture = function() end,
			EndCapture = function() end,
			ApplyBlur = function() end,
			DrawFullBlur = function() end,
			DrawMixed = function() end,
			DrawBlurredRegion = function() end,
			DrawUnblurred = function() end,
			Enable = function() end,
			Disable = function() end,
			Cleanup = function() end,
		}
	end,
}

local mockKi3d = {
	init = function() end,
	Begin3D = function() end,
	End3D = function() end,
	Draw = function() end,
	UpdateRenderTextures = function() end,
	filters = {
		new = function(name, config)
			return { name = name, shader = {} }
		end,
	},
}

local mockRaylib = {
	lib = setmetatable({}, {
		__index = function(_, key)
			return function()
				return 0
			end
		end,
	}),
	const = setmetatable({}, {
		__index = function(_, key)
			if key == "KeyboardKey" then
				return {}
			end
			return {}
		end,
	}),
	structs = setmetatable({}, {
		__index = function(_, key)
			return {
				new = function()
					return {}
				end,
				offset = function()
					return 0
				end,
				size = function()
					return 0
				end,
			}
		end,
	}),
}

export type KiRendConf = {
	width: number,
	height: number,
	maxFps: number,
	title: string?,
	iconPath: string?,
}

function KiRend.new(config: KiRendConf)
	local time = 0.0
	local frameCount = 0
	local simulatedFPS = config.maxFps or 120
	local frameTime = 1 / simulatedFPS
	local lastFrameTime = os.clock()
	local isRunning = false

	local activeCamera = {
		Name = "CurrentCamera",
		FieldOfView = 70,
		CFrame = { Position = { X = 0, Y = 0, Z = 0 } },
		_raylibcam = {},
	}

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
		sounds = {},
	}
	local ENGINE_PROFILER = nil

	local rendererObject = {
		Mesh = mockMeshlib,
		Skybox = mockSkybox,
		Freecam = mockFreecam,
		Shader = mockShader,
		Raylib = mockRaylib,
		Texture = mockTexture(),
		Ki3d = mockKi3d,
		Blur = mockBlur.Init(config.width, config.height),
		Camera = activeCamera,
		Draw = mockRaylib.lib,
		Enable3D = true,
		DrawFps = true,

		RuntimeLibrary = {
			lib = mockRaylib.lib,
			drawModel = mockMeshlib.drawModel,
			loadMaterialOnModel = mockMeshlib.loadMaterialOnModel,
			LoadShader = mockShader.LoadShader,
			structs = mockRaylib.structs,
			const = mockRaylib.const,
			dt = frameTime,
			time = 0,
			GetFont = function(name)
				return renderer_storage.fonts[name]
			end,
		},

		EventBus = renderer_eventbus,

		Hook = {
			new = function(hookListName, cb)
				if not renderer_hooks[hookListName] then
					return
				end
				table.insert(renderer_hooks[hookListName], cb)
			end,
		},

		Font = {
			new = function(name, fontPath, size)
				if renderer_storage.fonts[name] then
					return renderer_storage.fonts[name]
				end

				renderer_storage.fonts[name] = {
					name = name,
					path = fontPath,
					size = size or 24,
				}
				return renderer_storage.fonts[name]
			end,

			Get = function(name)
				return renderer_storage.fonts[name]
			end,

			getFontTexture = function(name)
				return renderer_storage.fonts[name]
			end,

			Remove = function(name)
				renderer_storage.fonts[name] = nil
			end,
		},

		Pool = {
			new = function(type, renderFn)
				local id = math.random(1, 99999)
				if type == "2d" then
					renderer_pool.gui[id] = {
						render = renderFn,
						object = nil,
					}
				elseif type == "3d" then
					renderer_pool.object[id] = renderFn
				elseif type == "gizmo" then
					renderer_pool.gizmos[id] = renderFn
				else
					return nil
				end
				return id
			end,

			Destroy = function(id)
				renderer_pool.gui[id] = nil
				renderer_pool.object[id] = nil
				renderer_pool.gizmos[id] = nil
			end,
		},

		Audio = {
			new = function(audioPath, volume, pitch)
				local soundId = math.random(1, 99999)
				renderer_storage.sounds[soundId] = {
					path = audioPath,
					volume = volume or 1.0,
					pitch = pitch or 1.0,
					playing = false,
				}

				return {
					Pause = function()
						renderer_storage.sounds[soundId].playing = false
					end,
					Play = function()
						renderer_storage.sounds[soundId].playing = true
					end,
					Destroy = function()
						renderer_storage.sounds[soundId] = nil
					end,
				}
			end,
		},
	}

	function rendererObject:SetProfiler(profilerObject)
		ENGINE_PROFILER = profilerObject
	end

	function rendererObject:MakeShader(name, ki3dConfig)
		return mockKi3d.filters.new(name, ki3dConfig)
	end

	function rendererObject:SetIcon(texturePath) end

	function rendererObject:SetResizable() end

	function rendererObject:UseRlCamera(raylibCam)
		activeCamera = raylibCam
	end

	function rendererObject:InitAudioDevice() end

	function rendererObject:Render3D()
		renderer_eventbus:Fire("Begin3D")

		for _, hook in pairs(renderer_hooks.Before3D) do
			pcall(hook, rendererObject.RuntimeLibrary)
		end

		for _, renderFn in pairs(renderer_pool.object) do
			pcall(renderFn, rendererObject.RuntimeLibrary)
		end

		for _, renderFn in pairs(renderer_pool.gizmos) do
			pcall(renderFn, rendererObject.RuntimeLibrary)
		end

		for _, hook in pairs(renderer_hooks.After3D) do
			pcall(hook, rendererObject.RuntimeLibrary)
		end

		renderer_eventbus:Fire("End3D")
	end

	function rendererObject:Render2D()
		for _, hook in pairs(renderer_hooks.Before2D) do
			pcall(hook, rendererObject.RuntimeLibrary)
		end

		for _, gui in pairs(renderer_pool.gui) do
			pcall(gui.render, mockRaylib.lib, gui.object, time, mockRaylib.structs, rendererObject.RuntimeLibrary)
		end

		for _, hook in pairs(renderer_hooks.After2D) do
			pcall(hook, rendererObject.RuntimeLibrary)
		end
	end

	function rendererObject:Step()
		local currentTime = os.clock()
		local actualDelta = currentTime - lastFrameTime

		time = time + frameTime
		frameCount = frameCount + 1
		rendererObject.RuntimeLibrary.dt = frameTime
		rendererObject.RuntimeLibrary.time = time

		if ENGINE_PROFILER then
			ENGINE_PROFILER:NextFrame()
			ENGINE_PROFILER:Begin("Update")
		end

		for _, hook in pairs(renderer_hooks.Renderstep) do
			pcall(hook, frameTime)
		end

		renderer_eventbus:Fire("PreRender", frameTime)
		renderer_eventbus:Fire("RenderStepped", frameTime)

		renderer_eventbus:Fire("MouseData", {
			position = { X = 0, Y = 0 },
			delta = { x = 0, y = 0 },
			Button1Down = false,
			Button1Pressed = false,
			Button1Released = false,
			Button2Down = false,
			Button2Pressed = false,
			Button2Released = false,
			Button3Down = false,
			Button3Pressed = false,
			Button3Released = false,
			is_cursor_hidden = false,
			is_cursor_inbounds = true,
		})

		if ENGINE_PROFILER then
			ENGINE_PROFILER:End()
			ENGINE_PROFILER:Begin("Render")
		end

		renderer_eventbus:Fire("PreGuiRender")
		renderer_eventbus:Fire("GuiRender")

		if rendererObject.Enable3D then
			rendererObject:Render3D()
		end

		rendererObject:Render2D()

		renderer_eventbus:Fire("Heartbeat", frameTime)

		if ENGINE_PROFILER then
			ENGINE_PROFILER:SetCounter("FPS", simulatedFPS)
			ENGINE_PROFILER:End()
		end

		for _, hook in pairs(renderer_hooks.Afterstep) do
			pcall(hook, frameTime)
		end

		local sleepTime = frameTime - (os.clock() - currentTime)
		if sleepTime > 0 then
			task.wait(sleepTime)
		else
			task.wait(0)
		end

		lastFrameTime = os.clock()
	end

	function rendererObject:Run(maxFrames)
		isRunning = true
		lastFrameTime = os.clock()

		while isRunning do
			rendererObject:Step()

			if maxFrames and frameCount >= maxFrames then
				break
			end
		end

		rendererObject:Shutdown()
	end

	function rendererObject:Stop()
		isRunning = false
	end

	function rendererObject:Shutdown()
		for _, hook in pairs(renderer_hooks.Shutdown) do
			pcall(hook)
		end

		table.clear(renderer_storage.fonts)
		table.clear(renderer_storage.sounds)
		table.clear(renderer_pool.gui)
		table.clear(renderer_pool.object)
		table.clear(renderer_pool.gizmos)
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
			fps = simulatedFPS,
			time = time,
			frameCount = frameCount,
			render3DCount = gui3DCount,
			render2DCount = gui2DCount,
			gizmoCount = gizmoCount,
			windowSize = {
				width = config.width,
				height = config.height,
			},
			isHeadless = true,
		}
	end

	return rendererObject
end

return KiRend
