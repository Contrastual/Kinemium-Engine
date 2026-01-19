local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local GuiObject = require("@GuiObject")
local Enum = require("@EnumMap")
local raylib = require("@raylib")
local lib = raylib.lib

local propTable = {
	Name = "Frame",
	AbsoluteSize = nil,
	AbsolutePosition = nil,
}

GuiObject.inherit(propTable)

propTable.render = function(lib, object, dt, structs, renderer)
	local pos, size = GuiObject.render(lib, object, dt, structs, renderer)
	object.AbsolutePosition = pos
	object.AbsoluteSize = size

	GuiObject.renderChildren(lib, object, dt, structs, renderer)

	return pos, size
end

return {
	class = "Frame",
	render = propTable.render,
	callback = function(instance, renderer)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		GuiObject.inherit(tble)
	end,
}
