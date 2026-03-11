local Enum = {
	RaycastFilterType = {
		Whitelist = 0,
		Blacklist = 1,
	},
}

local RaycastParams = {}
RaycastParams.__index = RaycastParams

function RaycastParams.new()
	return setmetatable({
		FilterDescendantsInstances = {},
		FilterType = Enum.RaycastFilterType.Whitelist,
		IgnoreWater = false,
		CollisionGroup = "Default",
		RespectCanCollide = false,
		BruteForceAllSlow = false,
	}, RaycastParams)
end

function RaycastParams:AddToFilter(instances)
	if typeof(instances) == "table" then
		for _, inst in ipairs(instances) do
			table.insert(self.FilterDescendantsInstances, inst)
		end
	else
		table.insert(self.FilterDescendantsInstances, instances)
	end
end

function RaycastParams:ToTable()
	return {
		type = "RaycastParams",
		FilterDescendantsInstances = self.FilterDescendantsInstances,
		FilterType = self.FilterType,
		IgnoreWater = self.IgnoreWater,
		CollisionGroup = self.CollisionGroup,
		RespectCanCollide = self.RespectCanCollide,
		BruteForceAllSlow = self.BruteForceAllSlow,
	}
end

function RaycastParams.FromTable(tbl)
	assert(tbl.type == "RaycastParams", "Table is not a RaycastParams")
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = tbl.FilterDescendantsInstances or {}
	rp.FilterType = tbl.FilterType or Enum.RaycastFilterType.Whitelist
	rp.IgnoreWater = tbl.IgnoreWater or false
	rp.CollisionGroup = tbl.CollisionGroup or "Default"
	rp.RespectCanCollide = tbl.RespectCanCollide or false
	rp.BruteForceAllSlow = tbl.BruteForceAllSlow or false
	return rp
end

return RaycastParams
