local CFrameint16 = require("../enviroment/datatypes/CFrameint16")
local CFrame = require("../enviroment/datatypes/CFrame")
local Vector3 = require("../enviroment/datatypes/Vector3")

local testing = zune.testing
local expect = testing.expect

local function near(a, b, epsilon)
	epsilon = epsilon or 1e-5
	return math.abs(a - b) <= epsilon
end

testing.describe("CFrameint16", function()
	testing.test("Creation with default identity rotation", function()
		local cf = CFrameint16.new(10, 20, 30)
		expect(cf.Position.X).toBe(10)
		expect(cf.Position.Y).toBe(20)
		expect(cf.Position.Z).toBe(30)
		expect(cf.R00).toBe(32767)
		expect(cf.R01).toBe(0)
		expect(cf.R02).toBe(0)
		expect(cf.R10).toBe(0)
		expect(cf.R11).toBe(32767)
		expect(cf.R12).toBe(0)
		expect(cf.R20).toBe(0)
		expect(cf.R21).toBe(0)
		expect(cf.R22).toBe(32767)
	end)

	testing.test("Creation clamps int16 values", function()
		local cf = CFrameint16.new(40000, -40000, 0)
		expect(cf.Position.X <= 32767 and cf.Position.X >= -32768).toBeTruthy()
		expect(cf.Position.Y <= 32767 and cf.Position.Y >= -32768).toBeTruthy()
	end)

	testing.test("Creation with custom rotation matrix", function()
		local cf = CFrameint16.new(0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0)
		expect(cf.R00).toBe(0)
		expect(cf.R01).toBe(0)
		expect(cf.R02).toBe(1)
	end)

	testing.test("fromCFrame captures position", function()
		local cf = CFrame.new(Vector3.new(5, 10, 15))
		local ci = CFrameint16.fromCFrame(cf)
		expect(ci.Position.X).toBe(5)
		expect(ci.Position.Y).toBe(10)
		expect(ci.Position.Z).toBe(15)
	end)

	testing.test("ToCFrame roundtrips identity", function()
		local cf = CFrameint16.new(0, 0, 0)
		local converted = cf:ToCFrame()
		expect(converted.Position.X).toBe(0)
		expect(converted.Position.Y).toBe(0)
		expect(converted.Position.Z).toBe(0)
	end)

	testing.test("ToTable and FromTable roundtrip", function()
		local a = CFrameint16.new(7, 8, 9, 0, 0, 1, 0, 1, 0, 1, 0, 0)
		local tbl = a:ToTable()
		local b = CFrameint16.FromTable(tbl)
		expect(b.Position.X).toBe(7)
		expect(b.Position.Y).toBe(8)
		expect(b.Position.Z).toBe(9)
		expect(b.R01).toBe(0)
		expect(b.R12).toBe(0)
	end)

	testing.test("__tostring contains CFrameint16", function()
		local cf = CFrameint16.new(0, 0, 0)
		expect(string.find(tostring(cf), "CFrameint16", 1, true) ~= nil).toBeTruthy()
	end)
end)
