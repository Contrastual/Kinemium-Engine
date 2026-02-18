local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local Enum = require("@EnumMap")
local CFrame = require("@CFrame")

local propTable = {
	Color = Color3.new(1, 1, 1),
	Brightness = 200, -- intensity of the light
	Range = 400, -- how far the light reaches
	Shadows = true, -- casts shadows or not
	Enabled = true, -- whether the light is active
	Name = "PointLight",
	BaseClass = "Kinemium.light",
}

return {
	class = "PointLight",
	callback = function(instance, renderer, datamodel)
		local Lighting = datamodel:GetService("Lighting")

		local function Update()
			if instance.Parent then
				local parent = instance.Parent
				if parent.BaseClass == "BasePart" then
					local pos = parent.CFrame.Position
					if instance.Enabled then
						Lighting:AddPointLight(
							parent.UniqueId,
							pos,
							instance.Color,
							instance.Brightness,
							instance.Range
						)
					end
				end
			end
		end

		renderer.Pool.new("3d", function()
			Update()
		end)

		instance:SetProperties(propTable)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
