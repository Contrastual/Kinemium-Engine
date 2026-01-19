local GPixel = {}
GPixel.__index = GPixel

local UDim2 = require("@UDim2")

function GPixel.new(x, y, width, height)
	return setmetatable({
		X = x or 0,
		Y = y or 0,
		Width = width or 100,
		Height = height or 100,
	}, GPixel)
end

function GPixel:SetPosition(x, y)
	self.X = x or self.X
	self.Y = y or self.Y
	return self
end

function GPixel:SetSize(width, height)
	self.Width = width or self.Width
	self.Height = height or self.Height
	return self
end

function GPixel:Move(dx, dy)
	self.X = self.X + (dx or 0)
	self.Y = self.Y + (dy or 0)
	return self
end

function GPixel:Resize(dw, dh)
	self.Width = self.Width + (dw or 0)
	self.Height = self.Height + (dh or 0)
	return self
end

function GPixel:CenterInside(other)
	self.X = other.X + (other.Width - self.Width) / 2
	self.Y = other.Y + (other.Height - self.Height) / 2
	return self
end

function GPixel:ToUDim2()
	return UDim2.fromOffset(self.X, self.Y) -- width/height handled separately
end

function GPixel:ToTable()
	return {
		type = "GPixel",
		X = self.X,
		Y = self.Y,
		Width = self.Width,
		Height = self.Height,
	}
end

function GPixel.FromTable(tbl)
	assert(tbl.type == "GPixel", "Table is not a GPixel")
	return GPixel.new(tbl.X, tbl.Y, tbl.Width, tbl.Height)
end

function GPixel:__tostring()
	return string.format("GPixel(%d, %d, %d, %d)", self.X, self.Y, self.Width, self.Height)
end

return GPixel
