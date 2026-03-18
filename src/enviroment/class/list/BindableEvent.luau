local Vector3 = require("@datatypes/Vector3")
local Color3 = require("@datatypes/Color3")
local CFrame = require("@datatypes/CFrame")
local Enum = require("@EnumMap")
local Instance = require("@Instance")

local signal = require("@Kinemium.signal")

local propTable = {}

return {
	class = "BindableEvent",
	callback = function(object)
		local bindableSignal = signal.new()

		propTable = {
			Fire = bindableSignal.Fire,
			Event = bindableSignal.Connect,
			Name = "BindableEvent",
		}
		object.SetProperties(propTable)

		return object
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
