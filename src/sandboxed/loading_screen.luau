local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NetworkService = game:GetService("NetworkService")

local server_address = ""
local server_port = ""

local info, err = NetworkService:Ping(server_address, server_port)

if RunService:IsServer() or not RunService:IsClient() then
	return
end

local player = Players.LocalPlayer
if not player then
	return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ZIndex = 999
screenGui.Parent = player.PlayerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
background.Parent = screenGui

local textLabel = Instance.new("TextLabel")
textLabel.Name = "LoadingText"
textLabel.Text = "Loading World..."
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.Position = UDim2.new(0, 0, 0, 0)
textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
textLabel.TextSize = 36
textLabel.BackgroundTransparency = 1
textLabel.Parent = background

repeat
	task.wait()
until player.Character
screenGui:Destroy()
