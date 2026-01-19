local Color3 = require("@Color3")
local UDim2 = require("@UDim2")
local raylib = require("@raylib")
local lib = raylib.lib
local renderpool = {}

local proptble = {
	Name = "ScreenGui",
	Enabled = true,
	GravityY = -50,
	GravityX = 0,
	PhysicsEnabled = false,
	ZIndexBehavior = "Sibling",

	ResetOnSpawn = true,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, lib.GetRenderWidth(), 0, lib.GetRenderHeight()),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,

	BaseClass = "UIContainer",
}

return {
	class = "ScreenGui",

	callback = function(instance, renderer)
		proptble.render = function(lib, instance, dt, structs)
			local renderWidth, renderHeight

			if IsHeadless then
				renderWidth = 1024
				renderHeight = 1024
			else
				renderWidth = lib.GetRenderWidth()
				renderHeight = lib.GetRenderHeight()
			end

			instance.Size = UDim2.new(0, renderWidth, 0, renderHeight)

			for _, child in pairs(instance:GetChildren()) do
				if child["render"] then
					child.render(lib, child, dt, structs, renderer)
				end
			end
		end

		instance:SetProperties(proptble)

		return instance
	end,
}
