local CFrameint16 = {}
CFrameint16.__index = CFrameint16

local Vector3int16 = require("@Vector3int16")

local MIN_INT16 = -32768
local MAX_INT16 = 32767
local SCALE = 32767

local function clampInt16(value)
	value = math.floor(value)
	if value < MIN_INT16 then
		value = MIN_INT16 + (value - MIN_INT16) % 65536
	elseif value > MAX_INT16 then
		value = MIN_INT16 + (value - MIN_INT16) % 65536
	end
	return value
end

local function floatToInt16(v)
	return clampInt16(v * SCALE)
end

local function int16ToFloat(v)
	return v / SCALE
end

function CFrameint16.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
	return setmetatable({
		Position = Vector3int16.new(x, y, z),

		R00 = floatToInt16(r00 or 1),
		R01 = floatToInt16(r01 or 0),
		R02 = floatToInt16(r02 or 0),

		R10 = floatToInt16(r10 or 0),
		R11 = floatToInt16(r11 or 1),
		R12 = floatToInt16(r12 or 0),

		R20 = floatToInt16(r20 or 0),
		R21 = floatToInt16(r21 or 0),
		R22 = floatToInt16(r22 or 1),
	}, CFrameint16)
end

function CFrameint16.fromCFrame(cf)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()

	return CFrameint16.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

function CFrameint16:ToCFrame()
	return CFrame.new(self.Position.X, self.Position.Y, self.Position.Z, int16ToFloat(self.R00), int16ToFloat(self.R01), int16ToFloat(self.R02), int16ToFloat(self.R10), int16ToFloat(self.R11), int16ToFloat(self.R12), int16ToFloat(self.R20), int16ToFloat(self.R21), int16ToFloat(self.R22))
end

function CFrameint16:__tostring()
	return string.format("CFrameint16(Pos=%s)", tostring(self.Position))
end

return CFrameint16
