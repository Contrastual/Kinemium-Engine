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

function OverlapParams:ToTable()
	return {
		type = "OverlapParams",
		FilterDescendantsInstances = self.FilterDescendantsInstances,
		FilterType = self.FilterType,
		MaxParts = self.MaxParts,
		CollisionGroup = self.CollisionGroup,
		RespectCanCollide = self.RespectCanCollide,
	}
end

function OverlapParams.FromTable(tbl)
	assert(tbl.type == "OverlapParams", "Table is not an OverlapParams")
	local op = OverlapParams.new()
	op.FilterDescendantsInstances = tbl.FilterDescendantsInstances or {}
	op.FilterType = tbl.FilterType or Enum.RaycastFilterType.Whitelist
	op.MaxParts = tbl.MaxParts or 0
	op.CollisionGroup = tbl.CollisionGroup or "Default"
	op.RespectCanCollide = tbl.RespectCanCollide or false
	return op
end

return OverlapParams
