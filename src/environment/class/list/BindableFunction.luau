local propTable = {
	OnInvoke = nil,
}

return {
	class = "BindableFunction",
	callback = function(instance, renderer, game)
		instance:SetProperties(propTable)

		instance.Name = "BindableFunction"

		function instance:Invoke(...)
			if type(instance.OnInvoke) == "function" then
				return instance.OnInvoke(...)
			else
				error("OnInvoke is not a function")
			end
		end

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
