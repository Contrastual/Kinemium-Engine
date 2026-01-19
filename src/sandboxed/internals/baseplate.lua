local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local baseplate = Instance.new("Part")
baseplate.CFrame = CFrame.new(0, 0, 0)
baseplate.Size = Vector3.new(1000, 4, 1000)
baseplate.Color = Color3.new(0.2, 0.2, 0.2)
baseplate.Name = "Baseplate"
baseplate.Anchored = true
baseplate.Parent = game.Workspace

task.wait(5)

local startX, startZ = 0, 0
local rows, cols = 20, 20
local spacing = 4

for x = 0, rows - 1 do
	for z = 0, cols - 1 do
		task.spawn(function()
			local part = Instance.new("Part")
			part.Size = Vector3.new(4, 4, 4)
			part.CFrame = CFrame.new(startX + x * spacing, 10, startZ + z * spacing)
			part.Color = Color3.new(math.random(), math.random(), math.random())
			part.Parent = workspace
			part.Anchored = false
		end)
		task.wait()
	end
end

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
