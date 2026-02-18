local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Vector3 = require("@Vector3")

local Win32 = Instance.new("Win32")
local ffi = zune.ffi
local raylib = require("@raylib")

Win32:SetProperties({})
Win32.ExplorerHidden = true

Win32.InitRenderer = function(renderer, signal, datamodel)
	-- win32 api later on
	local texture = raylib.lib.LoadTexture("./src/assets/icon/icon.png")
	local image = raylib.lib.LoadImageFromTexture(texture)
	raylib.lib.SetWindowIcon(image)
end

return Win32
