local Instance = require("@Instance")

local GuiStackService = Instance.new("GuiStackService")
GuiStackService.ExplorerHidden = true

local raylib = require("@raylib")

GuiStackService.InitRenderer = function(renderer, renderer_signal)
	local props = {
		GUI = raylib,
		GTK = function()
			local gtkutil = require("@gtkutil")
			gtkutil.lowlevel.gtk.gtk_init()
			return gtkutil
		end,
	}

	GuiStackService:SetProperties(props)

	renderer_signal:Connect(function(route, dt) end)
end

return GuiStackService
