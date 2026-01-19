local Vector2 = require("@Vector2")

local Rect = {}
Rect.__index = Rect

function Rect.new(min, max)
	local self = setmetatable({}, Rect)

	self.Min = min or Vector2.new()
	self.Max = max or Vector2.new()

	self.Width = math.abs(self.Max.X - self.Min.X)
	self.Height = math.abs(self.Max.Y - self.Min.Y)

	return self
end

function Rect.fromCoords(minX, minY, maxX, maxY)
	return Rect.new(Vector2.new(minX, minY), Vector2.new(maxX, maxY))
end

return Rect
