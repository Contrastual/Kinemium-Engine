local Instance = require("@Instance")
local aereon = require("@Aereon")
local raylib = require("@raylib")
local Color3 = require("@datatypes/Color3")

local Plugin = Instance.new("Plugin")
local lib = raylib.lib
local structs = raylib.structs
local arect = require("@arect")(lib)

local NON_WIDGET_KEYS = {
	notify = true,
	SetFont = true,
	register = true,
	clear = true,
	step = true,
	stylesheet = true,
	immediate = true,
}

local function copyTable(source)
	local new = {}
	for k, v in pairs(source or {}) do
		new[k] = v
	end
	return new
end

local function removeArrayValue(list, value)
	for i = #list, 1, -1 do
		if list[i] == value then
			table.remove(list, i)
			return true
		end
	end
	return false
end

local function colorToRaylib(color, transparency)
	local source = color or Color3.new(1, 1, 1)
	local r, g, b = source:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - (transparency or 0))),
	})
end

local function getRectSize(component)
	if component and component.get_rect then
		local ok, value = pcall(component.get_rect)
		if ok and value then
			return value.width, value.height
		end
	end

	if component and component.get then
		local ok, value = pcall(component.get, "obj_rect")
		if ok and value then
			return value.width, value.height
		end
	end

	return nil, nil
end

local function getAvailableWidgetTypes(gui)
	local types = {}
	for name, factory in pairs(gui) do
		if type(factory) == "function" and not NON_WIDGET_KEYS[name] then
			table.insert(types, name)
		end
	end
	table.sort(types)
	return types
end

Plugin.InitRenderer = function(renderer, renderer_signal, game)
	task.spawn(function()
		Plugin:SetProperties({
			ResetOnSpawn = true,
		})

		repeat
			task.wait()
		until game.GetService

		local window = aereon.window(game)
		local gui = aereon.gui
		local availableWidgetTypes = getAvailableWidgetTypes(gui)

		local function createRawWidget(widgetType, config)
			local factory = gui[widgetType]
			if type(factory) ~= "function" or NON_WIDGET_KEYS[widgetType] then
				error(("Plugin: unknown widget type '%s'"):format(tostring(widgetType)))
			end

			return factory(copyTable(config or {}))
		end

		local function getWindowContentOrigin(windowData)
			local x = windowData.x + (windowData.ContentPaddingX or 0)
			local y = windowData.y + (windowData.ContentPaddingY or 0)

			if windowData.headerRender ~= false then
				y += 28
			end

			return x, y
		end

		local function makeMountedWidget(windowData, topRenderables, allWidgets, widgetType, config, options)
			options = options or {}
			config = copyTable(config or {})

			local component = createRawWidget(widgetType, config)
			local widget = {
				WidgetType = widgetType,
				component = component,
				x = config.x or config[1] or 0,
				y = config.y or config[2] or 0,
				width = config.width or config[3],
				height = config.height or config[4],
				absolute = options.absolute == true,
				enabled = options.enabled ~= false,
				order = options.order or options.zindex or config.zindex or 0,
				destroyed = false,
				_parentList = nil,
			}

			function widget:_mountTo(list)
				if self._parentList then
					removeArrayValue(self._parentList, self)
				end

				self._parentList = list
				table.insert(list, self)
			end

			function widget:_applyRect(baseX, baseY, yOffset)
				if self.absolute then
					baseX = 0
					baseY = 0
				end

				local width = self.width
				local height = self.height

				if width == nil or height == nil then
					local dynamicW, dynamicH = getRectSize(self.component)
					width = width or dynamicW or 0
					height = height or dynamicH or 0
				end

				if self.component and self.component.set then
					self.component.set(
						"obj_rect",
						arect.new(baseX + self.x, baseY + self.y + (yOffset or 0), width, height)
					)
				end
			end

			function widget:_render(dt, baseX, baseY, yOffset)
				if self.destroyed or not self.enabled then
					return
				end

				self:_applyRect(baseX, baseY, yOffset)

				if self.component and self.component.render then
					self.component.render(dt)
				end
			end

			function widget:render(dt, _windowData, baseX, baseY)
				self:_render(dt, baseX, baseY, 0)
			end

			function widget:GetComponent()
				return self.component
			end

			function widget:GetRect()
				local width = self.width
				local height = self.height
				if width == nil or height == nil then
					local dynamicW, dynamicH = getRectSize(self.component)
					width = width or dynamicW or 0
					height = height or dynamicH or 0
				end
				return {
					x = self.x,
					y = self.y,
					width = width,
					height = height,
				}
			end

			function widget:Get(prop)
				if prop == "x" or prop == "y" or prop == "width" or prop == "height" then
					return self[prop]
				end
				if prop == "enabled" then
					return self.enabled
				end
				if prop == "absolute" then
					return self.absolute
				end
				if prop == "order" or prop == "zindex" then
					return self.order
				end

				if self.component and self.component.get then
					return self.component.get(prop)
				end

				return nil
			end

			function widget:Set(prop, value)
				if prop == "x" or prop == "y" or prop == "width" or prop == "height" then
					self[prop] = value
					return self
				end
				if prop == "enabled" or prop == "visible" then
					self.enabled = not not value
					return self
				end
				if prop == "absolute" then
					self.absolute = not not value
					return self
				end
				if prop == "order" or prop == "zindex" then
					self.order = value or 0
					return self
				end

				if self.component and self.component.set then
					self.component.set(prop, value)
				end
				return self
			end

			function widget:Destroy()
				if self.destroyed then
					return
				end

				self.destroyed = true
				self.enabled = false

				if self._parentList then
					removeArrayValue(self._parentList, self)
					self._parentList = nil
				end

				removeArrayValue(allWidgets, self)
			end

			if options.mount ~= false then
				widget:_mountTo(topRenderables)
			end

			table.insert(allWidgets, widget)
			return widget
		end

		local function createWindowHandle(config)
			local windowConfig = copyTable(config or {})
			local userStep = windowConfig.step
			local topRenderables = {}
			local allWidgets = {}
			local scrollViews = {}

			local windowData
			local function renderPluginUI(dt)
				local baseX, baseY = getWindowContentOrigin(windowData)

				table.sort(topRenderables, function(a, b)
					return (a.order or 0) < (b.order or 0)
				end)

				for _, renderable in ipairs(topRenderables) do
					if renderable and renderable.render and not renderable.destroyed and renderable.enabled ~= false then
						renderable:render(dt, windowData, baseX, baseY)
					end
				end
			end

			windowConfig.step = function(currentWindow, dt)
				renderPluginUI(dt)
				if userStep then
					userStep(currentWindow, dt)
				end
			end

			windowData = window.create(windowConfig)
			windowData.ContentPaddingX = windowConfig.contentPaddingX or 0
			windowData.ContentPaddingY = windowConfig.contentPaddingY or 0

			function windowData:SetContentPadding(paddingX, paddingY)
				self.ContentPaddingX = paddingX or 0
				self.ContentPaddingY = paddingY or paddingX or 0
				return self
			end

			function windowData:GetContentOrigin()
				return getWindowContentOrigin(self)
			end

			function windowData:CreateWidget(widgetType, widgetConfig, options)
				options = copyTable(options or {})
				local container = options.container
				options.container = nil

				if container then
					options.mount = false
				end

				local widget = makeMountedWidget(
					self,
					topRenderables,
					allWidgets,
					widgetType,
					widgetConfig,
					options
				)

				if container and container.AddWidget then
					container:AddWidget(widget)
				end

				return widget
			end

			function windowData:MountWidget(widget)
				if type(widget) ~= "table" or not widget._mountTo then
					return nil
				end
				widget:_mountTo(topRenderables)
				return widget
			end

			function windowData:CreateWidgetTree(structure, options)
				local created = {}
				local renderList = {}

				for name, widgetConfig in pairs(structure or {}) do
					local typeName = widgetConfig.comp
					if typeName then
						local copied = copyTable(widgetConfig)
						created[name] = self:CreateWidget(typeName, copied, options)
						table.insert(renderList, name)
					end
				end

				table.sort(renderList, function(a, b)
					return (created[a].order or 0) < (created[b].order or 0)
				end)

				created.get = function(name)
					return created[name]
				end

				created.setprop = function(name, prop, value)
					local target = created[name]
					if target and target.Set then
						target:Set(prop, value)
					end
				end

				created.render = function(dt, excluded)
					local baseX, baseY = getWindowContentOrigin(self)

					for _, name in ipairs(renderList) do
						if excluded and table.find(excluded, name) then
							continue
						end
						local target = created[name]
						if target and target._render then
							target:_render(dt, baseX, baseY, 0)
						end
					end
				end

				created.destroy = function()
					for _, name in ipairs(renderList) do
						local target = created[name]
						if target and target.Destroy then
							target:Destroy()
						end
					end
				end

				return created
			end

			function windowData:CreateScrollView(configData)
				local scrollConfig = copyTable(configData or {})
				local scrollView = {
					x = scrollConfig.x or 0,
					y = scrollConfig.y or 0,
					width = scrollConfig.width or 220,
					height = scrollConfig.height or 220,
					padding = scrollConfig.padding or 0,
					scrollY = scrollConfig.scrollY or 0,
					contentHeight = scrollConfig.contentHeight,
					wheelStep = scrollConfig.wheelStep or 26,
					showScrollbar = scrollConfig.showScrollbar ~= false,
					scrollbarWidth = scrollConfig.scrollbarWidth or 5,
					scrollbarColor = scrollConfig.scrollbarColor or Color3.new(1, 1, 1),
					scrollbarTransparency = scrollConfig.scrollbarTransparency or 0.6,
					trackColor = scrollConfig.trackColor or Color3.new(0, 0, 0),
					trackTransparency = scrollConfig.trackTransparency or 0.75,
					backgroundColor = scrollConfig.backgroundColor,
					backgroundTransparency = scrollConfig.backgroundTransparency,
					order = scrollConfig.order or scrollConfig.zindex or 0,
					absolute = scrollConfig.absolute == true,
					clip = scrollConfig.clip ~= false,
					enabled = scrollConfig.enabled ~= false,
					children = {},
					destroyed = false,
				}

				local function getChildBottom(widget)
					local rect = widget:GetRect()
					return rect.y + rect.height
				end

				function scrollView:_getContentHeight()
					if self.contentHeight ~= nil then
						return self.contentHeight
					end

					local maxBottom = 0
					for _, child in ipairs(self.children) do
						if not child.destroyed and child.enabled ~= false then
							maxBottom = math.max(maxBottom, getChildBottom(child))
						end
					end
					return maxBottom
				end

				function scrollView:AddWidget(widget)
					if type(widget) ~= "table" or not widget._mountTo then
						error("Plugin ScrollView:AddWidget expects a widget returned by CreateWidget")
					end

					widget:_mountTo(self.children)
					return widget
				end

				function scrollView:CreateWidget(widgetType, widgetConfig, widgetOptions)
					local options = copyTable(widgetOptions or {})
					options.mount = false

					local widget = makeMountedWidget(
						windowData,
						topRenderables,
						allWidgets,
						widgetType,
						widgetConfig,
						options
					)

					return self:AddWidget(widget)
				end

				function scrollView:GetWidgets()
					return self.children
				end

				function scrollView:Set(prop, value)
					if prop == "x" or prop == "y" or prop == "width" or prop == "height" or prop == "padding" then
						self[prop] = value
					elseif prop == "scroll" or prop == "scrollY" then
						self.scrollY = math.max(0, value or 0)
					elseif prop == "enabled" or prop == "visible" then
						self.enabled = not not value
					elseif prop == "absolute" then
						self.absolute = not not value
					elseif prop == "order" or prop == "zindex" then
						self.order = value or 0
					else
						self[prop] = value
					end
					return self
				end

				function scrollView:Get(prop)
					if prop == "scroll" then
						return self.scrollY
					end
					return self[prop]
				end

				function scrollView:SetScroll(value)
					self.scrollY = math.max(0, value or 0)
					return self
				end

				function scrollView:ScrollTo(value)
					return self:SetScroll(value)
				end

				function scrollView:ClearWidgets(destroyChildren)
					for i = #self.children, 1, -1 do
						local child = self.children[i]
						if destroyChildren and child.Destroy then
							child:Destroy()
						else
							child._parentList = nil
							table.remove(self.children, i)
						end
					end
				end

				function scrollView:Destroy()
					if self.destroyed then
						return
					end

					self.destroyed = true
					self.enabled = false
					self:ClearWidgets(false)
					removeArrayValue(topRenderables, self)
					removeArrayValue(scrollViews, self)
				end

				function scrollView:render(dt, _windowState, baseX, baseY)
					if self.destroyed or not self.enabled then
						return
					end

					local viewX = self.absolute and self.x or (baseX + self.x)
					local viewY = self.absolute and self.y or (baseY + self.y)
					local viewWidth = self.width
					local viewHeight = self.height

					if self.backgroundColor and self.backgroundTransparency ~= nil and self.backgroundTransparency < 1 then
						lib.DrawRectangleRec(
							arect:translate(arect.new(viewX, viewY, viewWidth, viewHeight)),
							colorToRaylib(self.backgroundColor, self.backgroundTransparency)
						)
					end

					local padding = self.padding
					local innerX = viewX + padding
					local innerY = viewY + padding
					local innerWidth = math.max(1, viewWidth - padding * 2)
					local innerHeight = math.max(1, viewHeight - padding * 2)

					local contentHeight = math.max(0, self:_getContentHeight())
					local maxScroll = math.max(0, contentHeight - innerHeight)
					self.scrollY = math.clamp(self.scrollY, 0, maxScroll)

					local viewport = arect.new(viewX, viewY, viewWidth, viewHeight)

					if arect.MouseIsInRect(viewport) then
						local wheel = lib.GetMouseWheelMove()
						if wheel ~= 0 then
							self.scrollY = math.clamp(self.scrollY - wheel * self.wheelStep, 0, maxScroll)
						end
					end

					if self.clip then
						lib.BeginScissorMode(viewX, viewY, viewWidth, viewHeight)
					end

					table.sort(self.children, function(a, b)
						return (a.order or 0) < (b.order or 0)
					end)

					for _, child in ipairs(self.children) do
						if child and child._render then
							child:_render(dt, innerX, innerY, -self.scrollY)
						end
					end

					if self.clip then
						lib.EndScissorMode()
					end

					if self.showScrollbar and maxScroll > 0 then
						local trackX = viewX + viewWidth - self.scrollbarWidth - 2
						local trackY = viewY + 2
						local trackHeight = viewHeight - 4

						lib.DrawRectangleRec(
							arect:translate(arect.new(trackX, trackY, self.scrollbarWidth, trackHeight)),
							colorToRaylib(self.trackColor, self.trackTransparency)
						)

						local thumbHeight = math.max(20, (innerHeight / contentHeight) * trackHeight)
						local thumbTravel = trackHeight - thumbHeight
						local thumbY = trackY + (self.scrollY / maxScroll) * thumbTravel

						lib.DrawRectangleRec(
							arect:translate(arect.new(trackX, thumbY, self.scrollbarWidth, thumbHeight)),
							colorToRaylib(self.scrollbarColor, self.scrollbarTransparency)
						)
					end
				end

				table.insert(topRenderables, scrollView)
				table.insert(scrollViews, scrollView)
				return scrollView
			end

			function windowData:AddRenderCallback(callback, order)
				local renderable = {
					order = order or 0,
					enabled = true,
					destroyed = false,
				}

				function renderable:SetEnabled(value)
					self.enabled = not not value
				end

				function renderable:Destroy()
					if self.destroyed then
						return
					end
					self.destroyed = true
					self.enabled = false
					removeArrayValue(topRenderables, self)
				end

				function renderable:render(dt, currentWindow, baseX, baseY)
					callback(dt, currentWindow, baseX, baseY)
				end

				table.insert(topRenderables, renderable)
				return renderable
			end

			function windowData:GetWidgets()
				return allWidgets
			end

			function windowData:GetScrollViews()
				return scrollViews
			end

			function windowData:ClearWidgets(destroyWidgets)
				for i = #allWidgets, 1, -1 do
					local widget = allWidgets[i]
					if destroyWidgets == false then
						widget.destroyed = true
						widget.enabled = false
						if widget._parentList then
							removeArrayValue(widget._parentList, widget)
							widget._parentList = nil
						end
						table.remove(allWidgets, i)
					else
						widget:Destroy()
					end
				end

				for i = #scrollViews, 1, -1 do
					local scrollView = scrollViews[i]
					scrollView:Destroy()
				end

				for i = #topRenderables, 1, -1 do
					local item = topRenderables[i]
					if item.destroyed ~= false and item.destroyed ~= nil then
						table.remove(topRenderables, i)
					end
				end
			end

			function windowData:Destroy()
				self:ClearWidgets(true)
				self.Closed = true
				self.enabled = false
			end

			function windowData:GetAvailableWidgets()
				return availableWidgetTypes
			end

			return windowData
		end

		function Plugin:CreateWindow(config)
			return createWindowHandle(config or {})
		end

		function Plugin:CreateWidget(widgetType, config)
			return createRawWidget(widgetType, config)
		end

		function Plugin:CreateWidgetTree(structure)
			return aereon.create(structure)
		end

		function Plugin:GetAvailableWidgets()
			return availableWidgetTypes
		end

		Plugin.WidgetTypes = availableWidgetTypes
		Plugin.Ready = true

		renderer.Pool.new("2d", function()
			if not game.GetService then
				return
			end
			local StudioThemeService = game:GetService("StudioThemeService")
			if StudioThemeService then
				local dt = lib.GetFrameTime()
				window.update(dt, StudioThemeService.SelectedTheme.aereon)
				window.draw(dt, StudioThemeService.SelectedTheme.aereon)
			end
		end)
	end)

	return Plugin
end

return Plugin
