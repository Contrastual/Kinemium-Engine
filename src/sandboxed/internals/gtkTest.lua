local GuiStackService = game:GetService("GuiStackService")

--[[
local gtk = GuiStackService.GTK
local app = gtk.App.new("com.devcell.gtkgl")

app.OnActivate(function(appPtr, _)
	print("App activated!")

	local window = app.CreateWindow("OpenGL Window", Vector2.new(800, 600))
	window.Show()

	window.CreateText("Hello Kinemium", "large")
	window.CreateTextButton("Click me", function()
		print("hello")
	end)
end)

app.RunAsync()
--]]
