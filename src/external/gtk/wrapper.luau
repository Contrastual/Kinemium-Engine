local wrapper = {}

local ffi = zune.ffi
local gtklib = require("./init")
local gobject = gtklib.gobject
local gio = gtklib.gio
local gtk = gtklib.lib

wrapper.lowlevel = {
	gio = gio,
	gtk = gtk,
	gobject = gobject,
}

-- events
wrapper.Event = function(object, eventName, handler)
	local cfunc = ffi.closure({ returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } }, handler)
	gobject.g_signal_connect_data(object, eventName, cfunc, ffi.null, ffi.null, 0)
end

-- CSS Provider
wrapper.CSSProvider = {
	new = function()
		local provider = gtk.gtk_css_provider_new()
		return {
			provider = provider,
			LoadCSS = function(css)
				gtk.gtk_css_provider_load_from_string(provider, css)
				local display = gtk.gdk_display_get_default()
				gtk.gtk_style_context_add_provider_for_display(
					display,
					provider,
					600 -- GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
				)
			end,
			LoadFromFile = function(path)
				local file = gio.g_file_new_for_path(path)
				gtk.gtk_css_provider_load_from_file(provider, file)
				local display = gtk.gdk_display_get_default()
				gtk.gtk_style_context_add_provider_for_display(display, provider, 600)
			end,
		}
	end,
}

-- Layout Containers
wrapper.Box = {
	new = function(orientation, spacing)
		local orient = orientation == "vertical" and 1 or 0 -- GTK_ORIENTATION_VERTICAL = 1, HORIZONTAL = 0
		local box = gtk.gtk_box_new(orient, spacing or 0)

		return {
			box = box,
			Append = function(widget)
				gtk.gtk_box_append(box, widget)
			end,
			Prepend = function(widget)
				gtk.gtk_box_prepend(box, widget)
			end,
			Remove = function(widget)
				gtk.gtk_box_remove(box, widget)
			end,
			SetSpacing = function(spacing)
				gtk.gtk_box_set_spacing(box, spacing)
			end,
			SetHomogeneous = function(homogeneous)
				gtk.gtk_box_set_homogeneous(box, homogeneous and 1 or 0)
			end,
		}
	end,
}

wrapper.Grid = {
	new = function()
		local grid = gtk.gtk_grid_new()

		return {
			grid = grid,
			Attach = function(widget, column, row, width, height)
				gtk.gtk_grid_attach(grid, widget, column, row, width or 1, height or 1)
			end,
			SetRowSpacing = function(spacing)
				gtk.gtk_grid_set_row_spacing(grid, spacing)
			end,
			SetColumnSpacing = function(spacing)
				gtk.gtk_grid_set_column_spacing(grid, spacing)
			end,
			SetRowHomogeneous = function(homogeneous)
				gtk.gtk_grid_set_row_homogeneous(grid, homogeneous and 1 or 0)
			end,
			SetColumnHomogeneous = function(homogeneous)
				gtk.gtk_grid_set_column_homogeneous(grid, homogeneous and 1 or 0)
			end,
		}
	end,
}

-- Widgets
wrapper.Entry = {
	new = function()
		local entry = gtk.gtk_entry_new()

		return {
			entry = entry,
			GetText = function()
				local buffer = gtk.gtk_entry_get_buffer(entry)
				return ffi.string(gtk.gtk_entry_buffer_get_text(buffer))
			end,
			SetText = function(text)
				local buffer = gtk.gtk_entry_get_buffer(entry)
				gtk.gtk_entry_buffer_set_text(buffer, text, -1)
			end,
			SetPlaceholder = function(text)
				gtk.gtk_entry_set_placeholder_text(entry, text)
			end,
			SetVisibility = function(visible)
				gtk.gtk_entry_set_visibility(entry, visible and 1 or 0)
			end,
			OnChanged = function(handler)
				wrapper.Event(entry, "changed", handler)
			end,
			OnActivate = function(handler)
				wrapper.Event(entry, "activate", handler)
			end,
		}
	end,
}

wrapper.CheckButton = {
	new = function(label)
		local button = gtk.gtk_check_button_new_with_label(label or "")

		return {
			button = button,
			GetActive = function()
				return gtk.gtk_check_button_get_active(button) == 1
			end,
			SetActive = function(active)
				gtk.gtk_check_button_set_active(button, active and 1 or 0)
			end,
			OnToggled = function(handler)
				wrapper.Event(button, "toggled", handler)
			end,
		}
	end,
}

wrapper.Switch = {
	new = function()
		local switch = gtk.gtk_switch_new()

		return {
			switch = switch,
			GetActive = function()
				return gtk.gtk_switch_get_active(switch) == 1
			end,
			SetActive = function(active)
				gtk.gtk_switch_set_active(switch, active and 1 or 0)
			end,
			OnStateSet = function(handler)
				wrapper.Event(switch, "state-set", handler)
			end,
		}
	end,
}

wrapper.Image = {
	new = function(path)
		local image
		if path then
			image = gtk.gtk_image_new_from_file(path)
		else
			image = gtk.gtk_image_new()
		end

		return {
			image = image,
			SetFromFile = function(path)
				gtk.gtk_image_set_from_file(image, path)
			end,
			SetFromIconName = function(iconName)
				gtk.gtk_image_set_from_icon_name(image, iconName)
			end,
			SetPixelSize = function(size)
				gtk.gtk_image_set_pixel_size(image, size)
			end,
		}
	end,
}

wrapper.ProgressBar = {
	new = function()
		local progressBar = gtk.gtk_progress_bar_new()

		return {
			progressBar = progressBar,
			SetFraction = function(fraction)
				gtk.gtk_progress_bar_set_fraction(progressBar, fraction)
			end,
			Pulse = function()
				gtk.gtk_progress_bar_pulse(progressBar)
			end,
			SetText = function(text)
				gtk.gtk_progress_bar_set_text(progressBar, text)
			end,
			SetShowText = function(show)
				gtk.gtk_progress_bar_set_show_text(progressBar, show and 1 or 0)
			end,
		}
	end,
}

wrapper.Separator = {
	new = function(orientation)
		local orient = orientation == "vertical" and 1 or 0
		local separator = gtk.gtk_separator_new(orient)

		return {
			separator = separator,
		}
	end,
}

-- App
wrapper.App = {
	new = function(id: string)
		local app = gtk.gtk_application_new(id, ffi.null)

		return {
			app = app,
			OnActivate = function(handler)
				wrapper.Event(app, "activate", handler)
			end,

			OnDestroy = function(handler)
				wrapper.Event(app, "destroy", handler)
			end,

			OnCloseRequest = function(handler)
				wrapper.Event(app, "close-request", handler)
			end,

			CreateWindow = function(title, size)
				local myWindow = gtk.gtk_application_window_new(app)
				gtk.gtk_window_set_title(myWindow, title)
				gtk.gtk_window_set_default_size(myWindow, size.X, size.Y)

				return {
					window = myWindow,
					Show = function()
						gtk.gtk_window_present(myWindow)
					end,

					Destroy = function()
						gtk.gtk_window_destroy(myWindow)
					end,

					Fullscreen = function()
						gtk.gtk_window_fullscreen(myWindow)
					end,

					Unfullscreen = function()
						gtk.gtk_window_unfullscreen(myWindow)
					end,

					IsFullscreen = function()
						return gtk.gtk_window_is_fullscreen(myWindow)
					end,

					Maximize = function()
						gtk.gtk_window_maximize(myWindow)
					end,

					Unmaximize = function()
						gtk.gtk_window_unmaximize(myWindow)
					end,

					IsMaximized = function()
						return gtk.gtk_window_is_maximized(myWindow)
					end,

					SetResizable = function(resizable)
						gtk.gtk_window_set_resizable(myWindow, resizable and 1 or 0)
					end,

					SetChild = function(widget)
						gtk.gtk_window_set_child(myWindow, widget)
					end,

					SetDefaultSize = function(width, height)
						gtk.gtk_window_set_default_size(myWindow, width, height)
					end,

					Close = function()
						gtk.gtk_window_close(myWindow)
					end,

					OnCloseRequest = function(handler)
						wrapper.Event(myWindow, "close-request", handler)
					end,

					CreateText = function(text, textSize)
						local label = gtk.gtk_label_new(text)

						gtk.gtk_window_set_child(myWindow, label)
						if textSize then
							gtk.gtk_label_set_markup(label, `<span size='{textSize}'>{text}</span>`)
						end

						return {
							label = label,
							SetText = function(str)
								gtk.gtk_label_set_text(label, str)
							end,
							SetMarkup = function(markup)
								gtk.gtk_label_set_markup(label, markup)
							end,
							SetSelectable = function(selectable)
								gtk.gtk_label_set_selectable(label, selectable and 1 or 0)
							end,
							SetWrap = function(wrap)
								gtk.gtk_label_set_wrap(label, wrap and 1 or 0)
							end,
						}
					end,

					CreateTextButton = function(text, handler)
						local button = gtk.gtk_button_new_with_label(text)
						gtk.gtk_window_set_child(myWindow, button)
						if handler then
							wrapper.Event(button, "clicked", handler)
						end

						return {
							button = button,
							SetLabel = function(label)
								gtk.gtk_button_set_label(button, label)
							end,
							OnClicked = function(handler)
								wrapper.Event(button, "clicked", handler)
							end,
						}
					end,
				}
			end,

			Run = function()
				gio.g_application_run(app, 0, ffi.null)
			end,

			RunAsync = function()
				zune.task.spawn(function()
					gio.g_application_run(app, 0, ffi.null)
				end)
			end,

			Quit = function()
				gio.g_application_quit(app)
			end,
		}
	end,
}

return wrapper
