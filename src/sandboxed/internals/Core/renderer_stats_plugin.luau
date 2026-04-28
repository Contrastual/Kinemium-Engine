local RunService = game:GetService("RunService")
local Plugin = game:GetService("Plugin") :: Plugin

local kinemium_raylib = game:GetService("KinemiumRaylib") :: KinemiumRaylib
local renderer = kinemium_raylib.GetRenderer()

local window = Plugin:CreateWindow({
	title = "My Plugin",
	x = 100,
	y = 100,
	width = 400,
	height = 300,
})

local label = window:CreateLabel({
	text = "Hello from plugin",
	x = 20,
	y = 20,
})

RunService.RenderStepped:Connect(function()
	local perf = renderer.PerfStats

	local text = ""
	for prop, val in pairs(perf) do
		text = text .. prop .. ": " .. val .. "\n"
	end
	label:SetText(text)
end)
