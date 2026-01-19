local raylib = require("@raylib")
local lib = raylib.lib
local const = raylib.const
local aereon = require("@Kinemium.Aereon")
local color3 = require("@Color3")

local gui = aereon.gui

local module = {}
local dragging = false
local dragStartMouse
local dragStartWindow

local progressBar = gui.progressBar({
	x = 330,
	y = 250,
	width = 300,
	height = 20,
	progress = 0,
	fillColor = color3.new(1, 1, 1),
})

local tip = gui.label({
	x = 330,
	y = 220,
	text = "Tip: Did you know Kinemium is supposed to be a luau runtime?",
	fontSize = 15,
	color = color3.new(0.5, 0.5, 0.5),
})

local label = gui.label({
	x = 330,
	y = 280,
	text = "loadng",
	fontSize = 15,
	color = color3.new(1, 1, 1),
})

local CurrentStep = "hi"
local Percentage = 0
local active

function module.set(step, percentage)
	CurrentStep = step
	Percentage = percentage
end

function module:Disconnect()
	if active then
		task.cancel(active)
	end
end

function module.Run()
	active = task.spawn(function()
		lib.InitWindow(800, 335, "Kinemium Loader")

		local texture = lib.LoadTexture("./src/assets/images/loader.png")

		lib.SetTraceLogLevel(const.TraceLogLevel.LOG_ERROR)
		lib.SetConfigFlags(const.ConfigFlags.FLAG_MSAA_4X_HINT)
		lib.SetConfigFlags(const.ConfigFlags.FLAG_VSYNC_HINT)
		lib.SetWindowState(const.ConfigFlags.FLAG_WINDOW_TOPMOST)
		lib.SetWindowState(const.ConfigFlags.FLAG_WINDOW_UNDECORATED)
		lib.SetTargetFPS(0)

		while lib.WindowShouldClose() == 0 do
			lib.BeginDrawing()

			lib.DrawTextureEx(texture, vector.create(0, 0), 0, 1, const.WHITE)

			progressBar.setProgress(Percentage)
			progressBar.render(lib.GetFrameTime())

			label.setText("Loading " .. CurrentStep)

			label.render(lib.GetFrameTime())
			tip.render(lib.GetFrameTime())

			lib.EndDrawing()
			task.wait(0)
		end

		lib.UnloadTexture(texture)
		lib.CloseWindow()
	end)
	return active
end

return module
