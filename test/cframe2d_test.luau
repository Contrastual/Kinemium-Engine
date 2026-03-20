local CFrame2D = require("@datatypes/CFrame2D")
local Vector2 = require("@datatypes/Vector2")

local testing = zune.testing
local expect = testing.expect

local function near(a, b, epsilon)
	epsilon = epsilon or 1e-5
	return math.abs(a - b) <= epsilon
end

local function expectVecNear(v, x, y, epsilon)
	expect(near(v.X, x, epsilon)).toBeTruthy()
	expect(near(v.Y, y, epsilon)).toBeTruthy()
end

testing.describe("CFrame2D", function()
	testing.test("Constructors", function()
		local a = CFrame2D.new(Vector2.new(3, 4))
		local b = CFrame2D.new(3, 4)
		expectVecNear(a.Position, 3, 4)
		expectVecNear(b.Position, 3, 4)
	end)

	testing.test("fromAngle and GetAngle", function()
		local angle = math.pi / 3
		local cf = CFrame2D.fromAngle(Vector2.new(0, 0), angle)
		expect(near(cf:GetAngle(), angle, 1e-5)).toBeTruthy()
	end)

	testing.test("Multiplication with inverse gives identity", function()
		local cf = CFrame2D.fromAngle(Vector2.new(10, -3), math.pi / 4)
		local identity = cf * cf:Inverse()
		expectVecNear(identity.Position, 0, 0, 1e-4)
		expect(near(identity:GetAngle(), 0, 1e-4)).toBeTruthy()
	end)

	testing.test("PointToWorldSpace and PointToObjectSpace roundtrip", function()
		local cf = CFrame2D.fromAngle(Vector2.new(5, 6), math.pi / 2)
		local point = Vector2.new(2, 1)
		local world = cf:PointToWorldSpace(point)
		local back = cf:PointToObjectSpace(world)
		expectVecNear(back, point.X, point.Y, 1e-4)
	end)

	testing.test("Lerp endpoints", function()
		local a = CFrame2D.fromAngle(Vector2.new(1, 2), 0.1)
		local b = CFrame2D.fromAngle(Vector2.new(9, -2), 1.2)
		local l0 = a:Lerp(b, 0)
		local l1 = a:Lerp(b, 1)
		expect(l0 == a).toBeTruthy()
		expect(l1 == b).toBeTruthy()
	end)

	testing.test("Right and up vectors", function()
		local cf = CFrame2D.fromAngle(Vector2.new(0, 0), math.pi / 2)
		local right = cf:GetRightVector()
		local up = cf:GetUpVector()
		expectVecNear(right, 0, 1, 1e-5)
		expectVecNear(up, -1, 0, 1e-5)
	end)

	testing.test("IsFinite", function()
		local finite = CFrame2D.new(0, 0)
		local notFinite = CFrame2D.new(Vector2.new(math.huge, 0))
		expect(finite:IsFinite()).toBeTruthy()
		expect(notFinite:IsFinite()).toBeFalsy()
	end)

	testing.test("__eq epsilon behavior", function()
		local a = CFrame2D.new(1, 1)
		local b = CFrame2D.new(1 + 5e-7, 1 - 5e-7)
		expect(a == b).toBeTruthy()
	end)

	testing.test("ToRelative and FromRelative", function()
		local parent = CFrame2D.fromAngle(Vector2.new(4, 2), 0.2)
		local world = CFrame2D.fromAngle(Vector2.new(8, -1), -0.4)
		local relative = world:ToRelative(parent)
		local back = CFrame2D.FromRelative(parent, relative)
		expect(back == world).toBeTruthy()
	end)

	testing.test("ToTable and FromTable roundtrip", function()
		local a = CFrame2D.fromAngle(Vector2.new(-2, 7), 0.3)
		local tbl = a:ToTable()
		local b = CFrame2D.FromTable(tbl)
		expect(b == a).toBeTruthy()
	end)

	testing.test("__tostring has constructor style", function()
		expect(string.find(tostring(CFrame2D.new(1, 2)), "CFrame2D.new", 1, true) ~= nil).toBeTruthy()
	end)
end)
