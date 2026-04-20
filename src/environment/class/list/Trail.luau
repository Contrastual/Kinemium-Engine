local ColorSequence = require("@ColorSequence")
local Color3 = require("@Color3")
local NumberSequence = require("@NumberSequence")
local Enum = require("@EnumMap")

local propTable = {
	Attachment0 = nil,
	Attachment1 = nil,
	Color = ColorSequence.new(Color3.new(1, 1, 1)),
	Transparency = NumberSequence.new(0.5),
	Lifetime = 2,
	MinLength = 0.1,
	MaxLength = 0,
	Texture = "",
	TextureLength = 1,
	TextureMode = Enum.TextureMode.Stretch,
	LightEmission = 0,
	LightInfluence = 1,
	FaceCamera = false,
	Enabled = true,
}

return {
	class = "Trail",

	callback = function(instance)
		instance:SetProperties(propTable)

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
