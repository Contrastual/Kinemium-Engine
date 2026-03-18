local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local RunService = Instance.new("RunService")

local RenderStepped = signal.new()
local Heartbeat = signal.new()
local Stepped = signal.new()
local PreRender = signal.new()
local PreGuiRender = signal.new()
local GuiRender = signal.new()

local raylib = require("@raylib")
local lib = raylib.lib

local renderStepBindings = {}

function RunService:BindToRenderStep(name, priority, callback)
	renderBindings[name] = { priority = priority, callback = callback }
end

function RunService:UnbindFromRenderStep(name)
	renderBindings[name] = nil
end

local function runRenderBindings(dt)
	local sorted = {}
	for name, data in pairs(renderStepBindings) do
		table.insert(sorted, data)
	end
	table.sort(sorted, function(a, b)
		return a.priority < b.priority
	end)
	for _, binding in ipairs(sorted) do
		binding.callback(dt)
	end
end

local status = {
	IsClient = true,
	IsServer = false,
	IsStudio = true,
	IsRunMode = false,
	IsRunning = false,
	IsEdit = true,
	IsPaused = false,
}

local scheduled = {}

RunService.InitRenderer = function(renderer, renderer_signal)
	RunService:SetProperties({
		RenderStepped = RenderStepped,
		Heartbeat = Heartbeat,
		Stepped = Stepped,
		GuiRender = GuiRender,
		PreRender = PreRender,
		PreGuiRender = PreGuiRender,

		IsClient = function()
			return status.IsClient
		end,
		IsServer = function()
			return status.IsServer
		end,
		IsStudio = function()
			return status.IsStudio
		end,
		IsRunMode = function()
			return status.IsRunMode
		end,
		IsRunning = function()
			return status.IsRunning
		end,
		IsEdit = function()
			return status.IsEdit
		end,

		GetFPS = function()
			return lib.GetFPS()
		end,
	})

	renderer_signal:Connect(function(route, dt)
		if route == "BoundRenderStep" then
			runRenderBindings(dt)
		elseif route == "RenderStepped" then
			RenderStepped:Fire(dt)
		elseif route == "PreRender" then
			PreRender:Fire(dt)
		elseif route == "Heartbeat" then
			if not status.IsPaused then
				Heartbeat:Fire(dt)
			end
		elseif route == "Stepped" then
			if not status.IsPaused then
				Stepped:Fire(dt)
			end
		elseif route == "GuiRender" then
			GuiRender:Fire(dt)
		elseif route == "PreGuiRender" then
			PreGuiRender:Fire(dt)
		end
	end)
end

function RunService:Pause()
	status.IsPaused = true
end

function RunService:Resume()
	status.IsPaused = false
end

function RunService:IsPaused()
	return status.IsPaused
end

function RunService:SetSchedulerFPS(fps)
	local dt = 1 / fps
	local last = os.clock()
	return function()
		local now = os.clock()
		local elapsed = now - last
		if elapsed < dt then
			return false
		end
		last = now
		return true
	end
end

return RunService
