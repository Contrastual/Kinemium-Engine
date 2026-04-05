local signal = require("@Kinemium.signal")

local propTable = {}

return {
	class = "BindableEvent",
	callback = function(instance, renderer, game)
		instance:SetProperties(propTable)

		local bindableSignal = signal.new()

		instance.Event = bindableSignal
		instance.Name = "BindableEvent"

		function instance:Fire(...)
			bindableSignal:Fire(...)
		end

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
