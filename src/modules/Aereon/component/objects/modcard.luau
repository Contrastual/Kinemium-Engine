--[[
	Usage:
		local ModPage = require("@ModPage")
		local page = ModPage(objects, {
			x = 0, y = 0, width = 1280, height = 800,
			font        = myFont,
			boldFont    = myBoldFont,

			-- Header
			title       = "Fabric API",
			description = "Lightweight and modular API...",
			downloads   = "159.15M",
			likes       = "29.7K",
			category    = "Library",
			icon        = loadedTexture,

			-- Body content (array of sections)
			sections = {
				{ type = "heading", text = "Fabric API" },
				{ type = "text",    text = "Essential hooks for modding with Fabric." },
				{ type = "heading", text = "Using Fabric API" },
				{ type = "bullet",  items = { "Hook A", "Hook B", "Hook C" } },
				{ type = "text",    text = "More info here." },
			},

			-- Sidebar
			compatibility = {
				game    = "Minecraft: Java Edition",
				versions = { "1.21.x", "1.20.x", "1.19.x", "1.18.x", "1.17.x", "1.16.x" },
			},
			platforms    = { "Fabric", "Quilt" },
			environments = { "Client-side", "Server-side", "Client and server" },

			-- Callbacks
			onDownload  = function() end,
			onLike      = function() end,
			onTabChange = function(tab) end,
		})
]]

local raylib = require("@raylib")
local structs = raylib.structs
local rect = require("@arect")(raylib.lib)
local color3 = require("@Color3")

--  palette
local C = {
	pageBg = color3.new(0.08, 0.08, 0.10),
	headerBg = color3.new(0.10, 0.10, 0.12),
	panelBg = color3.new(0.11, 0.11, 0.14),
	sidebarBg = color3.new(0.11, 0.11, 0.14),
	tabBarBg = color3.new(0.09, 0.09, 0.11),
	tabActive = color3.new(0.13, 0.78, 0.37),
	tabActiveBg = color3.new(0.08, 0.22, 0.13),
	accent = color3.new(0.13, 0.78, 0.37),
	accentDim = color3.new(0.09, 0.55, 0.26),
	text = color3.new(0.92, 0.92, 0.94),
	muted = color3.new(0.55, 0.55, 0.60),
	dimText = color3.new(0.42, 0.42, 0.46),
	border = color3.new(0.18, 0.18, 0.22),
	tagBg = color3.new(0.16, 0.16, 0.20),
	tagText = color3.new(0.72, 0.72, 0.78),
	iconBg = color3.new(0.20, 0.20, 0.25),
	btnHover = color3.new(0.20, 0.20, 0.26),
	white = color3.new(1, 1, 1),
	bulletDot = color3.new(0.13, 0.78, 0.37),
	sectionHead = color3.new(0.95, 0.95, 0.97),
	versionTag = color3.new(0.22, 0.22, 0.28),
	versionText = color3.new(0.68, 0.68, 0.74),
	platformTag = color3.new(0.12, 0.32, 0.18),
	platformTxt = color3.new(0.35, 0.90, 0.50),
	envTag = color3.new(0.18, 0.18, 0.24),
	envText = color3.new(0.62, 0.62, 0.68),
	scrollBar = color3.new(0.25, 0.25, 0.30),
	headerHover = color3.new(1, 1, 1),
}

--  draw helpers
local function dt(fnt, text, x, y, size, col, spacing)
	raylib.lib.DrawTextEx(fnt, text, vector.create(x, y), size, spacing or 0.7, col)
end

local function mt(fnt, text, size, spacing)
	local v = raylib.lib.MeasureTextEx(fnt, text, size, spacing or 0.7)
	return v.x, v.y
end

local function rrect(rx, ry, rw, rh, round, col)
	raylib.lib.DrawRectangleRounded(structs.Rectangle:new({ x = rx, y = ry, width = rw, height = rh }), round, 8, col)
end

local function rrectL(rx, ry, rw, rh, round, thick, col) end

local function clip(rx, ry, rw, rh)
	raylib.lib.BeginScissorMode(rx, ry, rw, rh)
end
local function unclip()
	raylib.lib.EndScissorMode()
end

local function mouseIn(rx, ry, rw, rh)
	local mp = raylib.lib.GetMousePosition()
	return mp.x >= rx and mp.x <= rx + rw and mp.y >= ry and mp.y <= ry + rh
end

local function drawIcon(tex, rx, ry, rw, rh)
	if not tex then
		return
	end
	raylib.lib.DrawTexturePro(
		tex.texture,
		structs.Rectangle:new({ x = 0, y = 0, width = tex.x, height = tex.y }),
		structs.Rectangle:new({ x = rx, y = ry, width = rw, height = rh }),
		vector.create(0, 0),
		0,
		raylib.const.WHITE
	)
end

local function wrapText(fnt, text, maxW, size, spacing)
	spacing = spacing or 0.7
	local lines, words, cur = {}, {}, ""
	for w in text:gmatch("%S+") do
		table.insert(words, w)
	end
	for _, word in ipairs(words) do
		local test = cur == "" and word or (cur .. " " .. word)
		if mt(fnt, test, size, spacing) > maxW and cur ~= "" then
			table.insert(lines, cur)
			cur = word
		else
			cur = test
		end
	end
	if cur ~= "" then
		table.insert(lines, cur)
	end
	return lines
end

--  pill tag helper
local function drawPill(fnt, text, x, y, fs, bgCol, textCol, padH, padV)
	padH = padH or 8
	padV = padV or 4
	local tw = mt(fnt, text, fs, 0.6)
	local pw = tw + padH * 2
	local ph = fs + padV * 2
	rrect(x, y, pw, ph, 0.5, bgCol)
	dt(fnt, text, x + padH, y + padV, fs, textCol, 0.6)
	return pw + 6 -- advance width
end

--  component
return function(objects, data)
	local defFont = raylib.lib.GetFontDefault()

	local config = {
		obj_rect = rect.new(data.x or data[1], data.y or data[2], data.width or data[3], data.height or data[4]),
		modifiers = {},

		font = data.font or defFont,
		boldFont = data.boldFont or data.font or defFont,
		fontSize = data.fontSize or 14,

		-- header
		title = data.title or "Fabric API",
		description = data.description
			or "Lightweight and modular API providing common hooks and interoperability measures utilized by mods using the Fabric toolchain.",
		downloads = data.downloads or "159.15M",
		likes = data.likes or "29.7K",
		category = data.category or "Library",
		icon = data.icon,
		backgroundTransparency = data.backgroundTransparency or 0,

		-- body
		sections = data.sections
			or {
				{ type = "heading", text = "Fabric API" },
				{ type = "text", text = "Essential hooks for modding with Fabric." },
				{
					type = "text",
					text = "Fabric API is the library for essential hooks and interoperability mechanisms for Fabric mods.",
				},
				{ type = "heading", text = "Features" },
				{
					type = "bullet",
					items = {
						"Exposing functionality useful but difficult to access for many mods such as particles, biomes and dimensions.",
						"Adding events, hooks and APIs to improve interoperability between mods.",
						"Essential features such as registry synchronization and adding information to crash reports.",
						"An advanced rendering API designed for compatibility with optimization and graphics overhaul mods.",
					},
				},
				{
					type = "text",
					text = "Fabric API is a mod like any other Fabric mod which requires Fabric Loader to be installed.",
				},
			},

		-- sidebar
		compatibility = data.compatibility or {
			game = "Minecraft: Java Edition",
			versions = {
				"26.2-snapshot-3",
				"26.1.x",
				"1.21.x",
				"1.20.x",
				"1.19.x",
				"1.18.x",
				"1.17.x",
				"1.16.x",
				"1.15.x",
				"1.14.x",
			},
		},
		platforms = data.platforms or { "Fabric" },
		environments = data.environments or { "Client-side", "Server-side", "Client and server" },

		-- tabs
		tabs = data.tabs or { "Description", "Changelog", "Versions" },
		activeTab = data.activeTab or 1,

		-- callbacks
		onDownload = data.onDownload,
		onLike = data.onLike,
		onTabChange = data.onTabChange,

		-- scroll
		_scrollY = 0,
		_maxScroll = 0,
		_hovDl = false,
		_hovLike = false,
		_hovBookmark = false,
		_hovMenu = false,
	}

	C.accent = data.accent or C.accent
	C.tabBarBg = data.tabBarBg or C.tabBarBg
	C.pageBg = data.pageBg or C.pageBg
	C.headerBg = data.headerBg or C.headerBg
	C.iconBg = data.iconBg or C.iconBg
	C.text = data.text or C.text
	C.muted = data.muted or C.muted
	C.bg = data.bg or C.bg
	C.lightText = data.lightText or C.lightText
	C.sidebarBg = data.sidebarBg or C.sidebarBg
	C.buttonBg = data.buttonBg or C.buttonBg
	C.buttonBgHover = data.buttonBgHover or C.buttonBgHover

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.render = function(dt_time)
		local r = config.obj_rect
		local fnt = config.font
		local bfnt = config.boldFont
		local fs = config.fontSize

		local mp = raylib.lib.GetMousePosition()
		local mPress = raylib.lib.IsMouseButtonPressed(0) == 1
		local wheel = raylib.lib.GetMouseWheelMove()

		--  layout constants
		local outerPad = 24
		local headerH = 130
		local tabBarH = 44
		local bodyY = r.y + headerH + tabBarH + 10
		local bodyH = r.height - headerH - tabBarH - 10
		local sidebarW = 240
		local gutter = 14
		local mainW = r.width - outerPad * 2 - sidebarW - gutter
		local mainX = r.x + outerPad
		local sidebarX = mainX + mainW + gutter

		--  page background
		raylib.lib.DrawRectangle(r.x, r.y, r.width, r.height, C.pageBg:ToRaylib(config.backgroundTransparency))

		-- HEADER CARD
		local hx, hy = r.x + outerPad, r.y + outerPad
		local hw, hh = r.width - outerPad * 2, headerH - outerPad

		rrect(hx, hy, hw, hh, 0.05, C.headerBg:ToRaylib(config.backgroundTransparency))

		local hpad = 16
		local iconSz = 68
		local iconX = hx + hpad
		local iconY = hy + hh / 2 - iconSz / 2

		-- icon box
		rrect(iconX, iconY, iconSz, iconSz, 0.14, C.iconBg:ToRaylib(config.backgroundTransparency))
		if config.icon then
			drawIcon(config.icon, iconX, iconY, iconSz, iconSz)
		else
			local letter = config.title:sub(1, 1):upper()
			local lw = mt(fnt, letter, fs + 10, 1)
			dt(
				fnt,
				letter,
				iconX + iconSz / 2 - lw / 2,
				iconY + iconSz / 2 - (fs + 10) / 2,
				fs + 10,
				C.accent:ToRaylib(0),
				1
			)
		end

		-- title + desc text
		local txtX = iconX + iconSz + hpad
		local titleFS = fs + 5
		local descFS = fs - 1
		local smallFS = fs - 2

		-- button cluster (right side)
		local btnH = 34
		local btnW = 118
		local bClustW = btnW + 8 + btnH + 8 + btnH + 8 + btnH
		local bClustX = hx + hw - hpad - bClustW
		local bClustY = hy + hh / 2 - btnH / 2

		local txtMaxW = bClustX - txtX - hpad

		-- title
		local titleY = hy + hpad
		dt(bfnt, config.title, txtX, titleY, titleFS, C.text:ToRaylib(0), 0.8)

		-- description (2-line wrap)
		local descLines = wrapText(fnt, config.description, txtMaxW, descFS, 0.6)
		for i = 1, math.min(#descLines, 2) do
			local line = descLines[i]
			if i == 2 and #descLines > 2 then
				line = line:gsub("%s*%S+$", "") .. "…"
			end
			dt(fnt, line, txtX, titleY + titleFS + 6 + (i - 1) * (descFS + 5), descFS, C.muted:ToRaylib(0), 0.6)
		end

		-- stats row
		local statsY = hy + hh - hpad - smallFS - 2
		local sx = txtX

		local dlIcon = "↓"
		local diW = mt(fnt, dlIcon, smallFS, 0.5)
		dt(fnt, dlIcon, sx, statsY, smallFS, C.muted:ToRaylib(0), 0.5)
		dt(fnt, config.downloads, sx + diW + 3, statsY, smallFS, C.muted:ToRaylib(0), 0.6)
		sx = sx + diW + 3 + mt(fnt, config.downloads, smallFS, 0.6) + 14

		local hrtIcon = "♥"
		local hiW = mt(fnt, hrtIcon, smallFS, 0.5)
		dt(fnt, hrtIcon, sx, statsY, smallFS, C.muted:ToRaylib(0), 0.5)
		dt(fnt, config.likes, sx + hiW + 3, statsY, smallFS, C.muted:ToRaylib(0), 0.6)
		sx = sx + hiW + 3 + mt(fnt, config.likes, smallFS, 0.6) + 14

		drawPill(fnt, config.category, sx, statsY - 3, smallFS, C.tagBg:ToRaylib(0), C.tagText:ToRaylib(0), 7, 3)

		--  button cluster
		config._hovDl = mouseIn(bClustX, bClustY, btnW, btnH)
		config._hovLike = mouseIn(bClustX + btnW + 8, bClustY, btnH, btnH)
		config._hovBookmark = mouseIn(bClustX + btnW + 8 + btnH + 8, bClustY, btnH, btnH)
		config._hovMenu = mouseIn(bClustX + btnW + 8 + btnH + 8 + btnH + 8, bClustY, btnH, btnH)

		if mPress then
			if config._hovDl and config.onDownload then
				config.onDownload()
			end
			if config._hovLike and config.onLike then
				config.onLike()
			end
		end

		-- download btn
		local dlCol = config._hovDl and C.accent or C.accentDim
		rrect(bClustX, bClustY, btnW, btnH, 0.45, dlCol:ToRaylib(0))
		local dlLabel = "  Download"
		local dlLW = mt(fnt, dlLabel, fs, 0.8)
		dt(fnt, dlLabel, bClustX + btnW / 2 - dlLW / 2, bClustY + btnH / 2 - fs / 2, fs, C.white:ToRaylib(0), 0.8)

		-- like btn
		local lkX = bClustX + btnW + 8
		rrect(lkX, bClustY, btnH, btnH, 0.45, (config._hovLike and C.btnHover or C.iconBg):ToRaylib(0))
		rrectL(lkX, bClustY, btnH, btnH, 0.45, 1, C.border:ToRaylib(0))
		local hW = mt(fnt, "♥", fs, 1)
		dt(fnt, "♥", lkX + btnH / 2 - hW / 2, bClustY + btnH / 2 - fs / 2, fs, C.muted:ToRaylib(0), 1)

		-- bookmark btn
		local bmX = lkX + btnH + 8
		rrect(bmX, bClustY, btnH, btnH, 0.45, (config._hovBookmark and C.btnHover or C.iconBg):ToRaylib(0))
		rrectL(bmX, bClustY, btnH, btnH, 0.45, 1, C.border:ToRaylib(0))
		local bkW = mt(fnt, "⊕", fs, 1)
		dt(fnt, "⊕", bmX + btnH / 2 - bkW / 2, bClustY + btnH / 2 - fs / 2, fs, C.muted:ToRaylib(0), 1)

		-- menu btn
		local mnX = bmX + btnH + 8
		rrect(mnX, bClustY, btnH, btnH, 0.45, (config._hovMenu and C.btnHover or C.iconBg):ToRaylib(0))
		rrectL(mnX, bClustY, btnH, btnH, 0.45, 1, C.border:ToRaylib(0))
		local dotStr = "···"
		local dotW = mt(fnt, dotStr, fs + 2, 2)
		dt(
			fnt,
			dotStr,
			mnX + btnH / 2 - dotW / 2,
			bClustY + btnH / 2 - (fs + 2) / 2 - 2,
			fs + 2,
			C.muted:ToRaylib(0),
			2
		)

		--
		-- TAB BAR
		--
		local tabBarY = r.y + headerH
		raylib.lib.DrawRectangle(r.x, tabBarY, r.width, tabBarH, C.tabBarBg:ToRaylib(config.backgroundTransparency))
		raylib.lib.DrawLineEx(
			vector.create(r.x, tabBarY + tabBarH - 1),
			vector.create(r.x + r.width, tabBarY + tabBarH - 1),
			1,
			C.border:ToRaylib(0)
		)

		local tabX = r.x + outerPad
		local tabFS = fs
		for i, tabName in ipairs(config.tabs) do
			local tw = mt(bfnt, tabName, tabFS, 0.8)
			local tabW = tw + 28
			local tabY = tabBarY + tabBarH / 2 - tabFS / 2 - 2
			local isActive = config.activeTab == i
			local isHov = mouseIn(tabX, tabBarY, tabW, tabBarH)

			if isActive then
				-- green pill bg
				rrect(tabX, tabBarY + 7, tabW, tabBarH - 14, 0.5, C.tabActiveBg:ToRaylib(0))
				dt(bfnt, tabName, tabX + 14, tabY, tabFS, C.tabActive:ToRaylib(0), 0.8)
				-- green underline
				raylib.lib.DrawRectangle(tabX, tabBarY + tabBarH - 2, tabW, 2, C.tabActive:ToRaylib(0))
			elseif isHov then
				rrect(tabX, tabBarY + 7, tabW, tabBarH - 14, 0.5, C.tagBg:ToRaylib(0))
				dt(fnt, tabName, tabX + 14, tabY, tabFS, C.text:ToRaylib(0), 0.8)
			else
				dt(fnt, tabName, tabX + 14, tabY, tabFS, C.muted:ToRaylib(0), 0.8)
			end

			if mPress and isHov then
				config.activeTab = i
				if config.onTabChange then
					config.onTabChange(i, tabName)
				end
			end
			tabX = tabX + tabW + 4
		end

		--
		-- BODY — scroll on wheel when mouse over main panel
		--
		if mouseIn(mainX, bodyY, mainW, bodyH) and wheel ~= 0 then
			config._scrollY = config._scrollY - wheel * 28
			if config._scrollY < 0 then
				config._scrollY = 0
			end
			if config._scrollY > config._maxScroll then
				config._scrollY = config._maxScroll
			end
		end

		--  MAIN CONTENT PANEL
		rrect(mainX, bodyY, mainW, bodyH, 0.03, C.panelBg:ToRaylib(0))
		rrectL(mainX, bodyY, mainW, bodyH, 0.03, 1, C.border:ToRaylib(0))

		local cpad = 20
		local cw = mainW - cpad * 2
		local cx = mainX + cpad
		local contentFS = fs
		local headingFS = fs + 5
		local bulletFS = fs - 1
		local lineH = contentFS + 9
		local bulletIndent = 14

		-- render sections with scissor clip
		clip(mainX + 1, bodyY + 1, mainW - 2, bodyH - 2)

		local cy = bodyY + cpad - config._scrollY
		local totalContentH = 0

		for _, section in ipairs(config.sections) do
			if section.type == "heading" then
				-- bold-looking heading
				if cy + headingFS >= bodyY and cy <= bodyY + bodyH then
					-- accent left bar
					raylib.lib.DrawRectangle(cx - 8, cy, 3, headingFS + 4, C.accent:ToRaylib(0))
					dt(bfnt, section.text, cx, cy, headingFS, C.sectionHead:ToRaylib(0), 0.8)
				end
				cy = cy + headingFS + 16
				totalContentH = totalContentH + headingFS + 16
			elseif section.type == "text" then
				local wlines = wrapText(fnt, section.text, cw, contentFS, 0.7)
				for _, line in ipairs(wlines) do
					if cy + contentFS >= bodyY and cy <= bodyY + bodyH then
						dt(fnt, line, cx, cy, contentFS, C.muted:ToRaylib(0), 0.7)
					end
					cy = cy + lineH
					totalContentH = totalContentH + lineH
				end
				cy = cy + 6
				totalContentH = totalContentH + 6
			elseif section.type == "bullet" then
				for _, item in ipairs(section.items) do
					local blines = wrapText(fnt, item, cw - bulletIndent - 10, bulletFS, 0.65)
					if cy + bulletFS >= bodyY and cy <= bodyY + bodyH then
						-- dot
						raylib.lib.DrawCircleV(vector.create(cx + 4, cy + bulletFS / 2 + 1), 3, C.bulletDot:ToRaylib(0))
						dt(fnt, blines[1], cx + bulletIndent, cy, bulletFS, C.muted:ToRaylib(0), 0.65)
					end
					cy = cy + bulletFS + 7
					totalContentH = totalContentH + bulletFS + 7

					for li = 2, #blines do
						if cy + bulletFS >= bodyY and cy <= bodyY + bodyH then
							dt(fnt, blines[li], cx + bulletIndent, cy, bulletFS, C.muted:ToRaylib(0), 0.65)
						end
						cy = cy + bulletFS + 7
						totalContentH = totalContentH + bulletFS + 7
					end
				end
				cy = cy + 4
				totalContentH = totalContentH + 4
			elseif section.type == "divider" then
				if cy >= bodyY and cy <= bodyY + bodyH then
					raylib.lib.DrawLineEx(
						vector.create(cx, cy + 6),
						vector.create(cx + cw, cy + 6),
						1,
						C.border:ToRaylib(0)
					)
				end
				cy = cy + 18
				totalContentH = totalContentH + 18
			end
		end

		-- update max scroll
		config._maxScroll = math.max(0, totalContentH - bodyH + cpad * 2)

		unclip()

		-- scrollbar
		if config._maxScroll > 0 then
			local sbW = 4
			local sbX = mainX + mainW - sbW - 3
			local ratio = bodyH / (totalContentH + cpad * 2)
			local sbH = math.max(30, bodyH * ratio)
			local sbY = bodyY + (config._scrollY / config._maxScroll) * (bodyH - sbH)
			rrect(sbX, sbY, sbW, sbH, 0.5, C.scrollBar:ToRaylib(0))
		end

		--  SIDEBAR
		rrect(sidebarX, bodyY, sidebarW, bodyH, 0.04, C.sidebarBg:ToRaylib(0))
		rrectL(sidebarX, bodyY, sidebarW, bodyH, 0.04, 1, C.border:ToRaylib(0))

		local sp = 16
		local sfs = fs - 1
		local ssmall = fs - 2
		local sy = bodyY + sp

		--  Compatibility section
		dt(bfnt, "Compatibility", sidebarX + sp, sy, sfs + 1, C.text:ToRaylib(0), 0.8)
		sy = sy + sfs + 1 + 10

		if config.compatibility then
			dt(fnt, config.compatibility.game, sidebarX + sp, sy, ssmall, C.muted:ToRaylib(0), 0.7)
			sy = sy + ssmall + 10

			-- version pills (wrap rows)
			local rowX = sidebarX + sp
			local rowMaxX = sidebarX + sidebarW - sp
			for _, ver in ipairs(config.compatibility.versions or {}) do
				local vw = mt(fnt, ver, ssmall, 0.6) + 14
				if rowX + vw > rowMaxX then
					rowX = sidebarX + sp
					sy = sy + ssmall + 10
				end
				rrect(rowX, sy, vw, ssmall + 8, 0.5, C.versionTag:ToRaylib(0))
				dt(fnt, ver, rowX + 7, sy + 4, ssmall, C.versionText:ToRaylib(0), 0.6)
				rowX = rowX + vw + 5
			end
			sy = sy + ssmall + 8 + 16
		end

		-- separator
		raylib.lib.DrawLineEx(
			vector.create(sidebarX + sp, sy),
			vector.create(sidebarX + sidebarW - sp, sy),
			1,
			C.border:ToRaylib(0)
		)
		sy = sy + 12

		--  Platforms section
		dt(bfnt, "Platforms", sidebarX + sp, sy, sfs + 1, C.text:ToRaylib(0), 0.8)
		sy = sy + sfs + 1 + 10

		local rowX = sidebarX + sp
		for _, plat in ipairs(config.platforms or {}) do
			local pw = drawPill(fnt, plat, rowX, sy, ssmall, C.platformTag:ToRaylib(0), C.platformTxt:ToRaylib(0), 8, 4)
			rowX = rowX + pw
		end
		sy = sy + ssmall + 8 + 16

		-- separator
		raylib.lib.DrawLineEx(
			vector.create(sidebarX + sp, sy),
			vector.create(sidebarX + sidebarW - sp, sy),
			1,
			C.border:ToRaylib(0)
		)
		sy = sy + 12

		--  Supported environments
		dt(bfnt, "Supported environments", sidebarX + sp, sy, sfs + 1, C.text:ToRaylib(0), 0.8)
		sy = sy + sfs + 1 + 10

		rowX = sidebarX + sp
		local rowMaxX = sidebarX + sidebarW - sp
		for _, env in ipairs(config.environments or {}) do
			local ew = mt(fnt, env, ssmall, 0.6) + 18
			if rowX + ew > rowMaxX then
				rowX = sidebarX + sp
				sy = sy + ssmall + 12
			end
			rrect(rowX, sy, ew, ssmall + 8, 0.45, C.envTag:ToRaylib(0))
			rrectL(rowX, sy, ew, ssmall + 8, 0.45, 1, C.border:ToRaylib(0))
			dt(fnt, env, rowX + 9, sy + 4, ssmall, C.envText:ToRaylib(0), 0.6)
			rowX = rowX + ew + 5
		end

		--  modifiers
		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
