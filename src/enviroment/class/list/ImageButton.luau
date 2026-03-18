local Vector2 = require("@datatypes/Vector2")
local Color3 = require("@datatypes/Color3")
local UDim2 = require("@datatypes/UDim2")
local Enum = require("@EnumMap")
local Frame = require("@classes/Frame")
local ImageLabel = require("@classes/ImageLabel")
local logic = require("@Kinemium.2dbutton")

local propTable = {
	AutoButtonColor = true,
	ChangeCursorOnHover = true,
	Visible = true,
	Name = "ImageButton",
}

ImageLabel.inherit(propTable)

propTable.render = function(lib, object, dt, structs, renderer)
	local framePos, frameSize, texture = ImageLabel.render(lib, object, dt, structs, renderer)

	logic:Step(object, lib)
end

return {
	class = "ImageButton",
	callback = function(instance, renderer)
		-- includes lib
		logic:SetupSignals(propTable)
		instance:SetProperties(propTable)

		instance.Changed:Connect(function(property)
			if property == "Image" then
				renderer.gbSet(instance.Image, renderer.lib.LoadTexture(instance.Image))
			end
		end)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
