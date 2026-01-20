--!optimize 2
--!native

local raylib = require("./external/raylib")
local task = zune.task
--local raygui = require("@raygui")

-- DEPENDENCIES
local skybox = require("./renderer/skybox")
local texture = require("./renderer/texture")
local signal = require("@Kinemium.signal")
local Vector2 = require("@Vector2")
local shader = require("./renderer/shader")
local freecam = require("./renderer/freecam")
local Enum = require("@EnumMap")
local CFrame = require("@CFrame")
local meshlib = require("./renderer/mesh")
local ki3d = require("@ki3d")
local blurmod = require("./renderer/guiblur")
local Instance = require("@Instance")
local bufferUtils = require("@bufferutils")
local Camera = require("@Camera")

-- CONF
local mainSignal = signal.new()
local game

-- INIT
local Kinemium_camera = Instance.new("Camera")
Camera.callback(Kinemium_camera)
Kinemium_camera.Name = "CurrentCamera"

-- TABLES
local fontRegistry = {}
local renderPool3d = {}
local renderPool2d = {}
local callbackStep = {}
local global_registry = {}
local mouseProperties = {}
local activeShaders = {}
local partRegistry = {}
local guiRegistry = {}

-- RAYLIB INIT
local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs

-- W&H
local screenWidth = raylib.lib.GetMonitorWidth(0)
local screenHeight = raylib.lib.GetMonitorHeight(0)

-- MATERIALS
local txtureMethods = texture(lib)
local materialList = txtureMethods.GetMaterials()

-- CAMERA SETTINGS
local FOV = 70
Kinemium_camera.FieldOfView = FOV
local cameraPos = vector.create(0.0, 5.0, 10.0)

-- RAYLIB INIT
lib.SetTraceLogLevel(const.TraceLogLevel.LOG_ERROR)
lib.SetConfigFlags(const.ConfigFlags.FLAG_MSAA_4X_HINT)
lib.SetConfigFlags(const.ConfigFlags.FLAG_VSYNC_HINT)
lib.SetConfigFlags(const.ConfigFlags.FLAG_WINDOW_RESIZABLE)

lib.InitWindow(1000, 800, "Kinemium Engine")
--lib.SetWindowState(const.ConfigFlags.FLAG_BORDERLESS_WINDOWED_MODE)

lib.SetTargetFPS(1000)
--raylib.r3d.lib.R3D_Init(raylib.lib.GetRenderWidth(, raylib.lib.GetRenderHeight(), 0)
-- R3D CMAKE
--cmake .. -DCMAKE_CXX_COMPILER=cl -DCMAKE_C_COMPILER=cl -DCMAKE_BUILD_TYPE=Release -DR3D_RAYLIB_VENDORED=ON -DR3D_ASSIMP_VENDORED=ON -DR3D_BUILD_EXAMPLES=ON -DR3D_BUILD_DOCS=OFF

ki3d.init()

local engineIcon = lib.LoadImage("./src/assets/icon/icon.png")
lib.SetWindowIcon(engineIcon)
lib.InitAudioDevice()
local guiBlur = blurmod.Init(lib.GetRenderWidth(), lib.GetRenderHeight())

-- TEXTURES
local UI_TEXTURE = raylib.lib.LoadRenderTexture(lib.GetRenderWidth(), lib.GetRenderHeight())

-- SHADERS
local normal = ki3d.shaders.new("normals", {
	vertex = "./src/assets/shaders/normal.vs",
	fragment = "./src/assets/shaders/normal.fs",
})

-- LOAD CAMERA
local camera = structs.Camera3D:new({
	position = cameraPos,
	target = vector.create(0.0, 0.0, 0.0),
	up = vector.create(0.0, 1.0, 0.0),
	fovy = 70.0,
	projection = const.CameraProjection.CAMERA_PERSPECTIVE,
})

local activeCamera = camera
local viewport = lib.LoadRenderTexture(screenWidth, screenHeight)
local runtimelib
local before3DRender = {}
local after3DRender = {}

runtimelib = {
	lib = lib,
	drawModel = meshlib.drawModel,
	loadMaterialOnModel = meshlib.loadMaterialOnModel,
	LoadShader = shader.LoadShader,
	structs = structs,
	const = const,
	blur = guiBlur,
	time = time,
	GetFont = function(name)
		if fontRegistry[name] then
			return fontRegistry[name]
		end
	end,
	SetMouseProperties = function(data)
		mouseProperties = data
	end,
	gbSet = function(property, value)
		global_registry[property] = value
	end,

	gbGet = function(property)
		return global_registry[property]
	end,
}

local function render3D()
	lib.BeginMode3D(activeCamera)
	lib.ClearBackground(const.BLUE)
	lib.rlEnableBackfaceCulling()
	mainSignal:Fire("Begin3D")

	for _, v in pairs(before3DRender) do
		v(runtimelib)
	end

	for _, v in pairs(renderPool3d) do
		v(runtimelib)
	end

	for _, v in pairs(after3DRender) do
		v(runtimelib)
	end

	lib.rlDisableBackfaceCulling()
	lib.EndMode3D()
	mainSignal:Fire("End3D")
end

local function step(time)
	--lib.SetWindowState(const.ConfigFlags.FLAG_BORDERLESS_WINDOWED_MODE)
	local activeLights = {}
	local delta = lib.GetFrameTime()
	mainSignal:Fire("PreRender", delta)
	mainSignal:Fire("RenderStepped", delta)

	local runtimeMouse = {
		position = Vector2.new(lib.GetMouseX(), lib.GetMouseY()),
		delta = lib.GetMouseDelta(),
		mouse_wheel_move = lib.GetMouseWheelMove(),
		mouse_wheel_delta = lib.GetMouseWheelMoveV(),
		Button1Down = lib.IsMouseButtonDown(0) == 1,
		Button1Pressed = lib.IsMouseButtonPressed(0) == 1,
		Button1Released = lib.IsMouseButtonReleased(0) == 1,
		Button2Down = lib.IsMouseButtonDown(1) == 1,
		Button2Pressed = lib.IsMouseButtonPressed(1) == 1,
		Button2Released = lib.IsMouseButtonReleased(1) == 1,
		Button3Down = lib.IsMouseButtonDown(2) == 1,
		Button3Pressed = lib.IsMouseButtonPressed(2) == 1,
		Button3Released = lib.IsMouseButtonReleased(2) == 1,

		-- cursor states
		is_cursor_hidden = lib.IsCursorHidden(),
		is_cursor_inbounds = lib.IsCursorOnScreen(),
	}
	for prop, value in pairs(mouseProperties) do
		runtimeMouse[prop] = value
	end
	mainSignal:Fire("MouseData", runtimeMouse)

	time += delta

	if raylib.lib.IsWindowResized() == 1 then
		UI_TEXTURE = raylib.lib.LoadRenderTexture(lib.GetRenderWidth(), lib.GetRenderHeight())
		ki3d.UpdateRenderTextures(lib.GetRenderWidth(), lib.GetRenderHeight())
	end

	if game and not game.Stop3DInput then
		freecam.Update(camera, delta, Kinemium_camera)
	end

	for name, keycode in pairs(const.KeyboardKey) do
		if lib.IsKeyPressed(keycode) == 1 then
			mainSignal:Fire("Pressed", keycode)
		end
		if lib.IsKeyDown(keycode) == 1 then
			mainSignal:Fire("IsKeyDown", keycode)
		end
		if lib.IsKeyReleased(keycode) == 1 then
			mainSignal:Fire("IsKeyReleased", keycode)
		end
		if lib.IsKeyUp(keycode) == 1 then
			mainSignal:Fire("IsKeyUp", keycode)
		end

		local mouseDelta = lib.GetMouseDelta()
		if mouseDelta.x ~= 0 or mouseDelta.y ~= 0 then
			mainSignal:Fire("MouseMoved", mouseDelta)
		end

		local wheel = lib.GetMouseWheelMove()
		if wheel ~= 0 then
			mainSignal:Fire("MouseWheel", wheel)
		end
	end

	--lib.BeginTextureMode(viewport)
	lib.BeginDrawing()

	for _, callback in pairs(callbackStep) do
		callback(lib, delta)
	end

	if game and game.Dimension == Enum.Dimension["3D"] then
		guiBlur:BeginCapture()
		ki3d:Begin3D()
		render3D()
		ki3d:End3D()
		guiBlur:EndCapture()
	end
	--lib.EndTextureMode()

	lib.ClearBackground(const.BLACK)

	guiBlur:ApplyBlur()
	guiBlur:DrawUnblurred(const.WHITE)
	mainSignal:Fire("PreGuiRender")

	mainSignal:Fire("GuiRender")

	table.clear(activeLights)

	ki3d:Draw(activeCamera)

	for _, gui in pairs(guiRegistry) do
		-- {render = function(), object = function()}
		gui.render(lib, gui.object and gui.object() or nil, time, structs, runtimelib)
	end

	for _, v in pairs(renderPool2d) do
		--lib.BeginTextureMode(UI_TEXTURE)
		--lib.ClearBackground(const.BLANK)
		v(runtimelib)
		--lib.EndTextureMode()
	end

	lib.DrawFPS(10, 10)
	lib.EndDrawing()
	mainSignal:Fire("Heartbeat", delta)

	task.wait(0)
end

local function run()
	local time = 0.0

	while lib.WindowShouldClose() == 0 do
		step(time)
	end

	for shaderName, _ in pairs(activeShaders) do
		shader.UnloadShader(shaderName)
	end

	for _, callback in pairs(game.ShutdownCallbacks) do
		print("Running finishing callback")
		local success, result = pcall(function()
			callback()
		end)
		if not success then
			warn(result)
		end
	end
end

return {
	Signal = mainSignal,
	AddToRegistry = function(data)
		table.insert(partRegistry, data)
		mainSignal:Fire("AddedPartToRenderPool", data())
	end,
	GetPool3D = function()
		local results = {}

		for _, part in pairs(partRegistry) do
			local data = part()
			table.insert(results, data)
		end

		return results
	end,
	DatamodelObject = function(object)
		game = object
	end,
	Step = step,
	get2DCount = function()
		return #guiRegistry
	end,
	AddGuiStack = function(renderFn)
		table.insert(guiRegistry, {
			render = renderFn,
		})
	end,
	AddToGuiRenderingPool = function(object, renderFn)
		table.insert(guiRegistry, {
			render = renderFn,
			object = object,
		})
		mainSignal:Fire("AddedGuiToRenderPool", object())
	end,
	RemoveFromGuiRenderingPool = function(object)
		for i, gui in pairs(guiRegistry) do
			if gui.object() == object then
				table.remove(guiRegistry, i)
				mainSignal:Fire("RemovedGuiFromRenderPool", object())
				return
			end
		end
	end,
	Run = run,
	lib = lib,
	camera = camera,
	const = const,
	structs = structs,

	-- camera Instance
	Kinemium_camera = Kinemium_camera,

	-- Mesh API
	mesh = meshlib,
	runtimelib = runtimelib,

	-- 3DHook
	Add3DStack = function(v)
		table.insert(renderPool3d, v)
	end,

	Add2DStack = function(v)
		table.insert(renderPool2d, v)
	end,

	add = function(self, v)
		table.insert(callbackStep, v)
	end,

	shader = shader,
	materialList = materialList,

	-- graphics
	blur = guiBlur,

	-- Font
	LoadFont = function(name, fontPath)
		local buf = lib.LoadFontEx(fontPath, 96, nil, 0)

		local texture = zune.mem.slice(buf, 16, structs.Texture2D:size())
		raylib.lib.SetTextureFilter(texture, raylib.const.TextureFilter.TEXTURE_FILTER_POINT)

		fontRegistry[name] = buf
		return buf
	end,

	GetFont = function(name)
		if fontRegistry[name] then
			return fontRegistry[name]
		end
	end,

	UnloadFont = function(name)
		if fontRegistry[name] then
			lib.UnloadFont(fontRegistry[name])
		end
	end,

	-- Global Registry
	gbSet = function(property, value)
		global_registry[property] = value
	end,

	gbGet = function(property)
		return global_registry[property]
	end,

	ChangeActiveCamera = function(camera)
		activeCamera = camera
	end,

	Before3DRender = function(v)
		table.insert(before3DRender, v)
	end,

	After3DRender = function(v)
		table.insert(after3DRender, v)
	end,

	Viewport = viewport,
	meshlib = meshlib,
	skybox = skybox,
}
