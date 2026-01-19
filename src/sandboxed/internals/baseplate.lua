local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local baseplate = Instance.new("Part")
baseplate.CFrame = CFrame.new(0, 0, 0)
baseplate.Size = Vector3.new(1000, 4, 1000)
baseplate.Color = Color3.new(0.2, 0.2, 0.2)
baseplate.Name = "Baseplate"
baseplate.Anchored = true
baseplate.Parent = game.Workspace

local fileService = game:GetService("KineFileService")

--[[
local success, result = pcall(function()
	local savedGame = fileService.Save("MyAwesomeGame.kine")
	if savedGame then
		print("Game saved successfully!")

		savedGame:ToExe()
		print("Executable built as KinemiumRuntime.exe")
	end
end)

if not success then
	print(result)
end
--]]
