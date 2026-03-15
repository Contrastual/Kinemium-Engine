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

local d, f = 0.64, 2.8
local NetworkService = game:GetService("NetworkService")

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

local UIDragDetector = Instance.new("UIDragDetector")
UIDragDetector.Parent = logo
