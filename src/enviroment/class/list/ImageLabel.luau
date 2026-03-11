local Vector2 = require("@Vector2")
local Color3 = require("@Color3")
local UDim2 = require("@UDim2")
local Enum = require("@EnumMap")
local GuiObject = require("@GuiObject")
local raylib = require("@raylib")
local lib = raylib.lib

local propTable = {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 100, 0, 100),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0,
	Image = "./src/assets/images/placeholder.png",
	ImageColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 0.5,
	--ScaleType = Enum.ScaleType.Stretch,
	--SliceCenter = Rect.new(0, 0, 0, 0),
	--SliceScale = 1,
	Name = "ImageLabel",
	Visible = true,
	ZIndex = 1,

	_cached = nil,
}

propTable.render = function(lib, object, dt, structs, renderer)
	local framePos, frameSize = GuiObject.render(lib, object, dt, structs, renderer)

	if object._cached then
		local size = vector.create(buffer.readi32(object._cached, 4), buffer.readi32(object._cached, 8))

		local rec = structs.Rectangle:new({
			x = 0,
			y = 0,
			width = size.x,
			height = size.y,
		})

		local dest = structs.Rectangle:new({
			x = framePos.X,
			y = framePos.Y,
			width = frameSize.X,
			height = frameSize.Y,
		})

		if object.ImageTransparency ~= 1 then
			lib.DrawTexturePro(
				object._cached,
				rec,
				dest,
				vector.create(0, 0), -- origin top-left
				object.Rotation or 0,
				object.ImageColor3:ToRaylib(object.ImageTransparency)
			)
		end
	end

	return framePos, frameSize, object._cached
end

GuiObject.inherit(propTable)

return {
	class = "ImageLabel",
	render = propTable.render,
	callback = function(instance, renderer)
		instance._cached = lib.LoadTexture(instance.Image)
		lib.SetTextureFilter(instance._cached, raylib.const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
		lib.SetTextureWrap(instance._cached, raylib.const.TextureWrap.TEXTURE_WRAP_CLAMP)
		lib.GenTextureMipmaps(instance._cached)

		instance.Changed:Connect(function(property)
			if property == "Image" then
				instance._cached = lib.LoadTexture(instance.Image)
				lib.SetTextureFilter(instance._cached, raylib.const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
				lib.SetTextureWrap(instance._cached, raylib.const.TextureWrap.TEXTURE_WRAP_CLAMP)
				lib.GenTextureMipmaps(instance._cached)
			end
		end)

		instance:SetProperties(propTable)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
