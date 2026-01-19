local raylib = require("@raylib")
local structs = raylib.structs
local objects = {}

local defaultFont = raylib.lib.GetFontDefault()

local comps = {
	badge = function(data)
		return require("./objects/badge")(objects, data)
	end,
	button = function(data)
		return require("./objects/button")(objects, data)
	end,
	card = function(data)
		return require("./objects/card")(objects, data)
	end,
	checkbox = function(data)
		return require("./objects/checkbox")(objects, data)
	end,
	colorPicker = function(data)
		return require("./objects/colorPicker")(objects, data)
	end,
	divider = function(data)
		return require("./objects/divider")(objects, data)
	end,
	githistory = function(data)
		return require("./objects/githistory")(objects, data)
	end,
	poll = function(data)
		return require("./objects/poll")(objects, data)
	end,
	dropdown = function(data)
		return require("./objects/dropdown")(objects, data)
	end,
	pie = function(data)
		return require("./objects/pie")(objects, data)
	end,
	frame = function(data)
		return require("./objects/frame")(objects, data)
	end,
	graph = function(data)
		return require("./objects/graph")(objects, data)
	end,
	iconButton = function(data)
		return require("./objects/iconButton")(objects, data)
	end,
	image = function(data)
		return require("./objects/image")(objects, data)
	end,
	label = function(data)
		return require("./objects/label")(objects, data)
	end,
	menu = function(data)
		return require("./objects/menu")(objects, data)
	end,
	itemcard = function(data)
		return require("./objects/itemcard")(objects, data)
	end,
	progressBar = function(data)
		return require("./objects/progressBar")(objects, data)
	end,
	prompt = function(data)
		return require("./objects/prompt")(objects, data)
	end,
	navigation = function(data)
		return require("./objects/navigation")(objects, data)
	end,
	radioButton = function(data)
		return require("./objects/radioButton")(objects, data)
	end,
	slider = function(data)
		return require("./objects/slider")(objects, data)
	end,
	spinner = function(data)
		return require("./objects/spinner")(objects, data)
	end,
	stepper = function(data)
		return require("./objects/stepper")(objects, data)
	end,
	switch = function(data)
		return require("./objects/switch")(objects, data)
	end,
	tabs = function(data)
		return require("./objects/tabs")(objects, data)
	end,
	textInput = function(data)
		return require("./objects/textInput")(objects, data)
	end,
	toggle = function(data)
		return require("./objects/toggle")(objects, data)
	end,
	tooltip = function(data)
		return require("./objects/tooltip")(objects, data)
	end,
	fileSearch = function(data)
		return require("./objects/filesearch")(objects, data)
	end,
}

function comps.SetFont(font)
	defaultFont = font
end

function comps.clear()
	table.clear(objects)
end

function comps:step(dt)
	for _, v in pairs(objects) do
		if v["render"] then
			v.render(dt)
		end
	end
end

return comps
