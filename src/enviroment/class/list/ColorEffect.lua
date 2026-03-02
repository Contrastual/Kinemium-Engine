local r3d = require("@r3d")

local propTable = {
	Brightness = 0.0,
	Contrast = 1.0,
	Saturation = 1.0,
	Enabled = true,
	Name = "ColorEffect",
	BaseClass = "LightingPreprocess",
}

return {
	class = "ColorEffect",

	callback = function(instance)
		instance:SetProperties(propTable)

		local envcolor = r3d.structs.R3D_EnvColor:new({
			brightness = instance.Brightness,
			contrast = instance.Contrast,
			saturation = instance.Saturation,
		})
		instance._r3deffect = envcolor

		instance.Changed:Connect(function(property, value)
			envcolor = r3d.structs.R3D_EnvColor:new({
				brightness = instance.Brightness,
				contrast = instance.Contrast,
				saturation = instance.Saturation,
			})
			instance._r3deffect = envcolor
		end)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
