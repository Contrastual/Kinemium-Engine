local Players = game:GetService("Players")

local gui = Instance.new("World2D")
gui.Name = "ScreenGuiPhysics"
gui.Parent = Players.LocalPlayer.PlayerGui

--[[
local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Parent = gui

local Camera = Instance.new("Camera")
Camera.Parent = workspace

local Part = Instance.new("Part")
Part.Size = Vector3.new(1, 1, 1)
Part.Position = Vector3.new(0, 0, 0)
Part.Anchored = true
Part.Parent = viewportFrame

viewportFrame.Camera = Camera

local frame = Instance.new("Frame")
frame.Parent = gui

--]]
