return {
	class = "RemoteFunction",
	callback = function(instance)
		instance:SetProperties({
			OnClientInvoke = nil,
			OnServerInvoke = nil,
			InvokeTimeout = 10,
			-- InvokeServer and InvokeClient are injected by the networking bridge
		})

		return instance
	end,
}
