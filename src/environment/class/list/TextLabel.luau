local Vector2 = require("@Vector2")
local UDim2 = require("@UDim2")
local Frame = require("@Frame")
local Color3 = require("@Color3")
local Enum = require("@EnumMap")
local raylib = require("@raylib")
local lib = raylib.lib
local GuiObject = require("@GuiObject")
local RichText = require("@Kinemium.richtext")

local function resolveBlendMode(value)
	if type(value) == "number" then
		return value
	end
	if type(value) ~= "string" then
		return raylib.const.BlendMode.BLEND_ALPHA
	end

	local normalized = string.lower(value)
	if normalized == "additive" or normalized == "add" then
		return raylib.const.BlendMode.BLEND_ADDITIVE
	elseif normalized == "multiply" or normalized == "multiplied" then
		return raylib.const.BlendMode.BLEND_MULTIPLIED
	elseif normalized == "premultiply" or normalized == "premultipliedalpha" or normalized == "premultiplied" then
		return raylib.const.BlendMode.BLEND_ALPHA_PREMULTIPLY
	elseif normalized == "addcolors" then
		return raylib.const.BlendMode.BLEND_ADD_COLORS
	elseif normalized == "subtract" or normalized == "subtractcolors" then
		return raylib.const.BlendMode.BLEND_SUBTRACT_COLORS
	end

	return raylib.const.BlendMode.BLEND_ALPHA
end

local propTable = {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 200, 0, 50),
	Text = "Hello World!",
	TextColor3 = Color3.new(0, 0, 0),
	TextSize = 24,
	Font = Enum.Font.DefaultEngineFont,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextSpacing = 1,
	TextTransparency = 0,
	TextStrokeColor = Color3.new(0, 0, 0),
	TextStrokeTransparency = 1,
	TextWrapped = false,
	TextTruncate = Enum.TextTruncate.None,
	TextScaled = false,
	RichText = false,
	MaxVisibleGraphemes = -1,
	LineHeight = 1,
	BackgroundTransparency = 0,
	BackgroundColor = Color3.new(1, 1, 1),
	BorderSize = 0,
	BorderColor = Color3.new(0, 0, 0),
	BorderTransparency = 0,
	AnchorPoint = Vector2.new(0, 0),
	Rotation = 0,
	Name = "TextLabel",
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = true,
}

Frame.inherit(propTable)

local defaultFont = lib.GetFontDefault()

propTable.render = function(lib, object, dt, structs, renderer)
	local framePos, frameSize = GuiObject.render(lib, object, dt, structs, renderer)
	if not object.Visible or not framePos or not frameSize then
		return
	end
	local layout, spacing = RichText.GetLayout(object, frameSize, renderer, defaultFont)
	if not layout then
		return framePos, frameSize
	end

	local blend = object:FindFirstChildOfClass("UIBlend")
	local didBlend = false
	if blend and blend.Enabled ~= false and blend.AffectSelf ~= false then
		lib.BeginBlendMode(resolveBlendMode(blend.Mode))
		didBlend = true
	end

	RichText.DrawLayout(lib, object, framePos, frameSize, layout, spacing)

	if didBlend then
		lib.EndBlendMode()
	end

	GuiObject.renderChildren(lib, object, dt, structs, renderer)

	return framePos, frameSize
end

return {
	class = "TextLabel",
	render = propTable.render,
	callback = function(instance)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
