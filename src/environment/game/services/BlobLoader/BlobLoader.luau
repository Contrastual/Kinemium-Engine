local Instance = require("@Instance")
local BlobLoader = Instance.new("BlobLoader")
BlobLoader.ExplorerHidden = true

BlobLoader.InitRenderer = function(renderer, renderer_signal, datamodel)
	local function attachChildren(sourceRoot, targetRoot)
		for _, child in ipairs(sourceRoot:GetChildren()) do
			child.Parent = targetRoot
			print("Attached ", child.Name)
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
			task.spawn(function()
				local SerializationService = datamodel:GetService("SerializationService")
				local instances = SerializationService.Deserialize(binary, nil, true)
				print("[DEBUG] Deserialized instances. Root count:", instances and #instances or "nil")
				if not instances then
					return false
				end
				for _, root in ipairs(instances) do
					if root.ClassName == "DataModel" then
						for _, serviceSnapshot in ipairs(root:GetChildren()) do
							if not mergeServiceSnapshot(serviceSnapshot) then
								log("BlobLoader: no live service found for '" .. tostring(serviceSnapshot.Name) .. "'")
							end
						end
					else
						print("[DEBUG] Merging root:", root.Name)
						local liveService = mergeServiceSnapshot(root)
						if not liveService then
							print("[DEBUG] Parenting root to Workspace:", root.Name)
							root.Parent = datamodel:GetService("Workspace") or datamodel
							print("[DEBUG] Parented root to Workspace:", root.Name)
						end
					end
				end
				print("[DEBUG] Finished parenting all roots")
			end)

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
