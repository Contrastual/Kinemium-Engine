local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local WebviewService = Instance.new("WebviewService")
WebviewService.ExplorerHidden = true

WebviewService.InitRenderer = function(renderer, renderer_signal)
	if IsHeadless then
		return
	end

	WebviewService:SetProperties({
		CreateWindow = function(title, x, y)
			local webview = require("@webview")
			local lib = webview.lib
			if zune.platform.os == "windows" then
				local ole32 = require("@ole32")

				ole32.lib.CoInitializeEx(nil, 2)
			end

			local wv = lib.webview_create(0, nil)
			lib.webview_set_title(wv, title or "Kinemium Webview")
			lib.webview_set_size(wv, x or 800, y or 600, nil)

			return {
				Navigate = function(site)
					lib.webview_navigate(wv, site or "https://github.com/Qquaded/Kinemium-Engine")
				end,

				SetTitle = function(title)
					lib.webview_set_title(wv, title or "Kinemium Webview")
				end,

				SetSize = function(x, y)
					lib.webview_set_size(wv, x or 800, y or 600, 0)
				end,

				Run = function()
					lib.webview_run(wv)
				end,
			}
		end,
	})
end

return WebviewService
