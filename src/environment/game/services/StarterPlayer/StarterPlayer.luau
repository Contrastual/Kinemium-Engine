local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local StarterPlayer = Instance.new("ScriptContext")

StarterPlayer.InitRenderer = function(renderer, signal, datamodel)
	StarterPlayer:SetProperties({})
end

return StarterPlayer
