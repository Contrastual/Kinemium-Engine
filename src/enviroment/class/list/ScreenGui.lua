local Color3 = require("@Color3")
local UDim2 = require("@UDim2")
local raylib = require("@raylib")
local lib = raylib.lib
local renderpool = {}
local Vector2 = require("@Vector2")

local proptble = {
	Name = "ScreenGui",
	Enabled = true,
	GravityY = -50,
	GravityX = 0,
	PhysicsEnabled = false,
	ZIndexBehavior = "Sibling",

	ResetOnSpawn = true,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 400, 0, 400),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	RenderOffset = Vector2.new(0, 0),
	OverrideScreenSize = false,

	BaseClass = "UIContainer",
}

return {
	class = "ScreenGui",

	callback = function(instance, renderer)
		proptble.render = function(lib, instance, dt, structs)
			if not instance.Enabled then
				return
			end
			local renderWidth, renderHeight

			if IsHeadless then
				renderWidth = 1024
				renderHeight = 1024
			else
				renderWidth = lib.GetRenderWidth()
				renderHeight = lib.GetRenderHeight()
			end

			if not instance.OverrideScreenSize then
				instance.Size = UDim2.new(0, renderWidth, 0, renderHeight)
			end

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
