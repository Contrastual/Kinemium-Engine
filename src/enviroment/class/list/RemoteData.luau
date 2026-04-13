local signal = require("@Kinemium.signal")

return {
	class = "RemoteData",
	callback = function(instance)
		local dataChanged = signal.new()

		instance:SetProperties({
			Data = nil,
			DataChanged = dataChanged,
		})

		instance:GetPropertyChangedSignal("Data"):Connect(function(value)
			dataChanged:Fire(value)
		end)

		return instance
	end,
}
