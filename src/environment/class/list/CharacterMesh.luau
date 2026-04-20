local propTable = {
	Name = "CharacterMesh",
	BaseClass = "Kinemium.instance",

	BaseTextureId = 0,
	BodyPart = 1, -- Enum
	MeshId = 0,
	OverlayTextureId = 0,
}

return {
	class = "CharacterMesh",
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
