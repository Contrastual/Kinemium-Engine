local propTable = {
	Name = "ForceField",
	BaseClass = "Kinemium.instance",

	Visible = true,
}

return {
	class = "ForceField",
	callback = function(instance)
		instance:SetProperties(propTable)

		-- TODO: Implement functionality, use already existing Particle Emitter
		-- Detect forcefield from humanoid

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
