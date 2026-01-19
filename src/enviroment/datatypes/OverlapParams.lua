local Enum = require("@EnumMap")

local OverlapParams = {}
OverlapParams.__index = OverlapParams

function OverlapParams.new()
	return setmetatable({
		FilterDescendantsInstances = {},
		FilterType = Enum.RaycastFilterType.Whitelist,
		MaxParts = 0,
		CollisionGroup = "Default",
		RespectCanCollide = false,
	}, OverlapParams)
end

function OverlapParams:AddToFilter(instances)
	if type(instances) == "table" then
		for _, inst in ipairs(instances) do
			table.insert(self.FilterDescendantsInstances, inst)
		end
	else
		table.insert(self.FilterDescendantsInstances, instances)
	end
end

return OverlapParams
