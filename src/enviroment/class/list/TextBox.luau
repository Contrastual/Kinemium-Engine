local Enum = require("@EnumMap")
local logic = require("@Kinemium.2dinput")

local GuiObject = require("@classes/GuiObject")
local TextLabel = require("@classes/TextLabel")

local propTable = {
	Name = "TextBox",
	AutoButtonColor = true,
	ChangeCursorOnHover = true,
	Visible = true,
	Focused = false,
	CaretPosition = 0,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
}
TextLabel.inherit(propTable)
GuiObject.inherit(propTable)

propTable.render = function(lib, object, dt, structs, renderer)
	local framePos, frameSize = TextLabel.render(lib, object, dt, structs, renderer)
	if not object.Visible or not framePos or not frameSize then
		return
	end

	return framePos, frameSize
end

return {
	class = "TextBox",
	callback = function(instance, renderer, game)
		logic:SetupSignals(propTable)

		instance:SetProperties(propTable)

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			if tble[prop] then
				continue
			end
			tble[prop] = val
		end
	end,
}
