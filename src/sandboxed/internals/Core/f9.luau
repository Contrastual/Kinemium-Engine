local RunService = game:GetService("RunService")

if FlagExists("editor") then
	return
end

if FlagExists("cli") then
	return
end

if FlagExists("headless") then
	return
end

if not FlagExists("client") then
	return
end

local MainGui = Instance.new("ScreenGui")
MainGui.Parent = game.Players.LocalPlayer.PlayerGui

local KinemiumRaylib = game:GetService("KinemiumRaylib")
local renderer = KinemiumRaylib.renderer

local d, f = 0.64, 2.8

local spring = include(game.CoreGui:WaitForChild("spring"))
local NetworkService = game:GetService("NetworkService")
local KinemiumPhysicsService = game:GetService("PhysicsService")

local mainFps = 0

local logo = Instance.new("ImageLabel")
logo.Position = UDim2.new(0, 20, 0, 20)
logo.BackgroundColor3 = Color3.new(0, 0, 0)
logo.Size = UDim2.new(0, 200, 0, 200)
logo.Image = "./src/assets/images/icons/vanilla3/kinemium/KinemiumRaylib.png"
logo.BackgroundTransparency = 0.3
logo.Parent = MainGui

local Corner = Instance.new("UICorner")
Corner.Parent = logo

local main = Instance.new("Frame")
main.Position = UDim2.new(0, 20, 0, 230)
main.BackgroundColor3 = Color3.new(0, 0, 0)
main.Size = UDim2.new(0, 200, 0, 150)
main.BackgroundTransparency = 0.3
main.Parent = MainGui

local Corner = Instance.new("UICorner")
Corner.Parent = main

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 0
UIStroke.Color = Color3.new(1, 1, 1)
UIStroke.Parent = main

logo.MouseEnter:Connect(function(a0: number, a1: number)
	target(logo, d, f, {
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	target(UIStroke, d, f, {
		Thickness = 4,
	})
end)

logo.MouseLeave:Connect(function(a0: number, a1: number)
	target(logo, d, f, {
		BackgroundColor3 = Color3.new(0, 0, 0),
	})
	target(UIStroke, d, f, {
		Thickness = 0,
	})
end)

local UIDragDetector = Instance.new("UIDragDetector")
UIDragDetector.Parent = main

local UIDragDetector = Instance.new("UIDragDetector")
UIDragDetector.Parent = logo

local function label(y)
	local v = Instance.new("TextLabel")
	v.Size = UDim2.new(0, 130, 0, y)
	v.BackgroundTransparency = 1
	v.Position = UDim2.new(0, 5, 0, 0)
	v.TextSize = 18
	v.TextColor3 = Color3.new(1, 1, 1)
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.Parent = main
	return v
end

local fpsText = label(30)
local bodiesText = label(70)
local renderPoolText = label(110)
local renderPoolText3D = label(150)
local connectedToText = label(190)

local blur = Instance.new("BlurEffect")
blur.Parent = main
RunService.RenderStepped:Connect(function(dt: number)
	local addr, port = NetworkService.GetServerDataAsync()
	mainFps = 1 / dt
	fpsText.Text = `FPS: {math.round(mainFps)}`
	bodiesText.Text = `Bodies: {KinemiumPhysicsService.GetPhysicsBodyCount()}`
	renderPoolText.Text = `RenderPool2D: {renderer.get2DCount()}`
	renderPoolText3D.Text = `RenderPool3D: {workspace.GetPoolCount()}`
	connectedToText.Text = `Connected to: \n{addr}:{port}`
end)
