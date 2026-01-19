local Vector3 = require("@Vector3")
local Enum = require("@Enum")

local RaycastResult = {}
RaycastResult.__index = RaycastResult

function RaycastResult.new(instance, position, normal, material, distance)
	local self = setmetatable({}, RaycastResult)

	self.Instance = instance
	self.Position = position or Vector3.new()
	self.Normal = normal or Vector3.new()
	self.Material = material or Enum.Material.Plastic
	self.Distance = distance or 0

	return self
end

return RaycastResult
