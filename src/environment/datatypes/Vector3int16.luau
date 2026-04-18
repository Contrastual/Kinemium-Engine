local Vector3int16 = {}
Vector3int16.__index = Vector3int16

local Vector3 = require("@Vector3")

local MIN_INT16 = -32768
local MAX_INT16 = 32767

local function clampInt16(value)
	value = math.floor(value)
	if value < MIN_INT16 then
		value = MIN_INT16 + (value - MIN_INT16) % 65536
	elseif value > MAX_INT16 then
		value = MIN_INT16 + (value - MIN_INT16) % 65536
	end
	return value
end

function Vector3int16.new(x, y, z)
	return setmetatable({
		X = clampInt16(x or 0),
		Y = clampInt16(y or 0),
		Z = clampInt16(z or 0),
	}, Vector3int16)
end

Vector3int16.x = Vector3int16.X
Vector3int16.y = Vector3int16.Y
Vector3int16.z = Vector3int16.Z

function Vector3int16.__add(a, b)
	return Vector3int16.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3int16.__sub(a, b)
	return Vector3int16.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3int16.__mul(a, b)
	if type(a) == "number" then
		return Vector3int16.new(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return Vector3int16.new(a.X * b, a.Y * b, a.Z * b)
	else
		return Vector3int16.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end
end

function Vector3int16.__div(a, b)
	if type(b) == "number" then
		return Vector3int16.new(a.X / b, a.Y / b, a.Z / b)
	else
		return Vector3int16.new(math.floor(a.X / b.X), math.floor(a.Y / b.Y), math.floor(a.Z / b.Z))
	end
end

function Vector3int16:__tostring()
	return string.format("Vector3int16(%d, %d, %d)", self.X, self.Y, self.Z)
end

function Vector3int16:ToVector3()
	return Vector3.new(self.X, self.Y, self.Z)
end

function Vector3int16:ToTable()
	return {
		type = "Vector3int16",
		X = self.X,
		Y = self.Y,
		Z = self.Z,
	}
end

function Vector3int16.FromTable(tbl)
	assert(tbl.type == "Vector3int16", "Table is not a Vector3int16")
	return Vector3int16.new(tbl.X, tbl.Y, tbl.Z)
end

return Vector3int16
