local Instance = require("@Instance")
local BlobLoader = Instance.new("BlobLoader")
BlobLoader.ExplorerHidden = true

BlobLoader.InitRenderer = function(renderer, renderer_signal, datamodel)
	local function attachChildren(sourceRoot, targetRoot)
		for _, child in ipairs(sourceRoot:GetChildren()) do
			child.Parent = targetRoot
		end
	end

	local function mergeServiceSnapshot(serviceSnapshot)
		local ok, liveService = pcall(function()
			return datamodel:GetService(serviceSnapshot.Name)
		end)
		if ok and liveService then
			attachChildren(serviceSnapshot, liveService)
			return liveService
		end
		return nil
	end

	BlobLoader:SetProperties({
		LoadFileAsGame = function(binary)
			print("Loading ", binary)
			local SerializationService = datamodel:GetService("SerializationService")
			print(1)
			local instances = SerializationService.Deserialize(binary, function(instance)
				print("Loaded " .. instance.Name)
			end)
			print(2)
			if not instances then
				return false
			end
			print(3)
			for _, root in ipairs(instances) do
				if root.ClassName == "DataModel" then
					for _, serviceSnapshot in ipairs(root:GetChildren()) do
						if not mergeServiceSnapshot(serviceSnapshot) then
							log("BlobLoader: no live service found for '" .. tostring(serviceSnapshot.Name) .. "'")
						end
					end
				else
					local liveService = mergeServiceSnapshot(root)
					if not liveService then
						root.Parent = datamodel:GetService("Workspace") or datamodel
					end
				end
			end

			return datamodel
		end,
		LoadFileAsGameFetch = function(link)
			local _1GB = 1024 * 1024 * 1024
			local ContentService = datamodel:GetService("ContentService")
			local binary = ContentService:GetBinary(link, _1GB)
			local new = BlobLoader.LoadFileAsGame(binary)
			return new
		end,
	})
end

return BlobLoader
