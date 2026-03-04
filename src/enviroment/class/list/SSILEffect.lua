local propTable = {
	SampleCount = 16,
	SliceCount = 6,
	Radius = 1.0,
	Thickness = 1.0,
	Intensity = 1.0,
	AOPower = 1.0,
	DenoiseSteps = 5,
	Enabled = true,
	Name = "SSILEffect",
	BaseClass = "LightingPreprocess",
}

return {
	class = "SSILEffect",

	callback = function(instance)
		local r3d = require("@r3d")

		instance:SetProperties(propTable)

		local envssil = r3d.structs.R3D_EnvSSIL:new({
			sampleCount = instance.SampleCount,
			sliceCount = instance.SliceCount,
			radius = instance.Radius,
			thickness = instance.Thickness,
			intensity = instance.Intensity,
			aoPower = instance.AOPower,
			denoiseSteps = instance.DenoiseSteps,
			enabled = instance.Enabled and 1 or 0,
		})
		instance._r3deffect = envssil

		instance.Changed:Connect(function(property, value)
			if property == "_r3deffect" then
				return
			end
			envssil = r3d.structs.R3D_EnvSSIL:new({
				sampleCount = instance.SampleCount,
				sliceCount = instance.SliceCount,
				radius = instance.Radius,
				thickness = instance.Thickness,
				intensity = instance.Intensity,
				aoPower = instance.AOPower,
				denoiseSteps = instance.DenoiseSteps,
				enabled = instance.Enabled and 1 or 0,
			})
			instance._r3deffect = envssil
		end)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
