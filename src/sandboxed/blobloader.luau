local BlobLoader = game:GetService("BlobLoader")

local flagValue = GetFlagValue("blob")

if flagValue then
	local read = Filesystem.readFile(flagValue, true)
	local new = BlobLoader.LoadFileAsGame(read)
end
