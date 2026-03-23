local Vector2 = require("@datatypes/Vector2")
local Color3 = require("@datatypes/Color3")
local UDim2 = require("@datatypes/UDim2")
local Enum = require("@EnumMap")
local GuiObject = require("@classes/GuiObject")
local raylib = require("@raylib")
local lib = raylib.lib
local const = raylib.const

local zembed = require("@zembed")
local placeholder = string.gsub(zembed.AssetPath("images/placeholder.png"), "\\", "/")

local propTable = {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 100, 0, 100),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0,
	Image = placeholder,
	ImageColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 0.5,
	ResampleMode = Enum.ResampleMode.Default,

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

	local image = object:GetMetadata("_cachedImage")
	if image then
		local props = object:GetProperties()
		local size = vector.create(buffer.readi32(image, 4), buffer.readi32(image, 8))

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

		local imageTransparency = props.ImageTransparency
		if imageTransparency < 1 then
			lib.DrawTexturePro(
				image,
				rec,
				dest,
				vector.create(0, 0), -- origin top-left
				props.Rotation or 0,
				props.ImageColor3:ToRaylib(imageTransparency)
			)
		end
	end

	return framePos, frameSize, image
end

GuiObject.inherit(propTable)

local FILTER_MAP = {
	[Enum.ResampleMode.Pixelated] = const.TextureFilter.TEXTURE_FILTER_POINT,
	[Enum.ResampleMode.Default] = const.TextureFilter.TEXTURE_FILTER_BILINEAR,
	[Enum.ResampleMode.Trilinear] = const.TextureFilter.TEXTURE_FILTER_TRILINEAR,
	[Enum.ResampleMode.Anisotropic4x] = const.TextureFilter.TEXTURE_FILTER_ANISOTROPIC_4X,
	[Enum.ResampleMode.Anisotropic8x] = const.TextureFilter.TEXTURE_FILTER_ANISOTROPIC_8X,
	[Enum.ResampleMode.Anisotropic16x] = const.TextureFilter.TEXTURE_FILTER_ANISOTROPIC_16X,
}

return {
	class = "ImageLabel",
	render = propTable.render,
	callback = function(instance, renderer)
		local queuedRegenerate

		local function reload(image)
			queuedRegenerate = nil
			if not image then
				image = lib.LoadTexture(instance.Image)
				instance:SetMetadata("_cachedImage", image)
				lib.GenTextureMipmaps(image)
			end
			lib.SetTextureFilter(image, FILTER_MAP[instance.ResampleMode] or const.TextureFilter.TEXTURE_FILTER_BILINEAR)
			lib.SetTextureWrap(image, const.TextureWrap.TEXTURE_WRAP_CLAMP)
		end

		instance.Changed:Connect(function(property)
			if property == "Image" and instance.Image ~= instance:GetMetadata("_cachedImage") then
				local image = lib.LoadTexture(instance.Image)
				instance:SetMetadata("_cachedImage", image)
				lib.GenTextureMipmaps(image)
				if queuedRegenerate then return end
				queuedRegenerate = task.defer(reload, instance:GetMetadata("_cachedImage"))
			elseif property == "ResampleMode" then
				if queuedRegenerate then return end
				queuedRegenerate = task.defer(reload)
			end
		end)

		instance:SetProperties(propTable)
		reload()

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
