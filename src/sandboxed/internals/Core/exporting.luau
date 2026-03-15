local fileService = game:GetService("KineFileService")

--[[
local success, result = pcall(function()
	local savedGame = fileService.BuildRuntime()
	if savedGame then
		print("Engine saved successfully!")
	end
end)

if not success then
	print(result)
end
--]]
