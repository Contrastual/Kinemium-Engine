local GuiObject = require("@classes/GuiObject")
local raylib = require("@Raylib")
local structs = raylib.structs

local aereon = require("@Aereon")
local gui = aereon.gui
local signal = require("@Kinemium.signal")
local Color4 = require("@datatypes/Color4")
local arect = aereon.rect()
local UDim2 = require("@datatypes/UDim2")

local propTable = {
	Name = "ColorPicker",
	BaseClass = "GuiObject",
	AbsoluteSize = nil,
	AbsolutePosition = nil,
	Size = UDim2.new(0, 250, 0, 400),
	SelectedColor = nil,
	OnColorSelect = signal.new(),
	Visible = true,
}

local function c3tr(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

GuiObject.inherit(propTable)

return {
	class = "ColorPicker",

	callback = function(instance, renderer, game)
		local picker = gui.colorPicker({
			x = 0,
			y = 0,
			width = 200,
			height = 250,
			onChanged = function(color, alpha)
				local selected = Color4.new(color.R, color.G, color.B, alpha)
				instance.SelectedColor = selected
				instance.OnColorSelect:Fire(selected)
			end,
		})

		propTable.render = function(lib, object, dt, structs, renderer)
			if object.Visible == false then
				return
			end
			local pos, size = GuiObject.calculatePositions(lib, object, dt, structs, renderer)

			picker.set("obj_rect", arect.new(pos.X, pos.Y, size.X, size.Y))
			picker.set("backgroundColor", object.BackgroundColor3)
			picker.set("backgroundTransparency", object.BackgroundTransparency)

			picker.render(dt)

			for _, child in pairs(object:GetChildren()) do
				if child.render then
					lib.BeginScissorMode(pos.X, pos.Y, size.X, size.Y)
					child.render(lib, child, dt, structs, renderer)
					lib.EndScissorMode()
				end
			end
		end

		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		GuiObject.inherit(tble)
	end,
}
