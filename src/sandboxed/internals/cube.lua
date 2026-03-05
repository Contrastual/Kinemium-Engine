local ORIGIN = CFrame.new(0, 10, 0)

local function makePart(size, cf, color)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = workspace
	return part
end

-- floor
makePart(Vector3.new(20, 1, 20), ORIGIN, Color3.fromRGB(120, 120, 120))

-- walls
makePart(Vector3.new(20, 10, 1), ORIGIN * CFrame.new(0, 5, -10), Color3.fromRGB(200, 200, 200))
makePart(Vector3.new(20, 10, 1), ORIGIN * CFrame.new(0, 5, 10), Color3.fromRGB(200, 200, 200))
makePart(Vector3.new(1, 10, 20), ORIGIN * CFrame.new(-10, 5, 0), Color3.fromRGB(200, 200, 200))
makePart(Vector3.new(1, 10, 20), ORIGIN * CFrame.new(10, 5, 0), Color3.fromRGB(200, 200, 200))

-- roof
makePart(Vector3.new(22, 1, 22), ORIGIN * CFrame.new(0, 10, 0), Color3.fromRGB(150, 50, 50))

-- door
makePart(Vector3.new(4, 6, 1), ORIGIN * CFrame.new(0, 3, -10), Color3.fromRGB(90, 60, 30))
