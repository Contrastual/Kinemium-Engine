local Vector3int16 = require("./Vector3int16")

local Region3int16 = {}
Region3int16.__index = Region3int16

function Region3int16.new(min, max)
	return setmetatable({
		Min = min,
		Max = max,
	}, Region3int16)
end

return Region3int16
