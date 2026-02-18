-- PATH: game.StarterPlayer.StarterPlayerScripts

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local character = Instance.new("Part")
character.Name = "Character"
character.Size = Vector3.new(2, 5, 2)
character.CFrame = CFrame.new(0, 10, 0)
character.Anchored = false

character.Parent = game.Workspace

local attachment = Instance.new("Attachment")
attachment.Parent = character

local VectorForce = Instance.new("VectorForce")
VectorForce.Attachment0 = attachment
VectorForce.Parent = attachment

RunService.RenderStepped:Connect(function(a0: number)
	camera.CFrame = CFrame.new(character.CFrame.Position * Vector3.new(0, 5, 5))
end)

UserInputService.InputBegan:Connect(function(key: InputObject, a1: boolean)
	if key.KeyCode == Enum.KeyCode.W then
		VectorForce.Force = CFrame.lookAt(character.CFrame.Position, camera.CFrame.Position).Position
	end
end)
