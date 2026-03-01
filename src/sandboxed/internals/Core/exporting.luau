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
-]]
