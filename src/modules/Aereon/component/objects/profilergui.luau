local raylib = require("@raylib")
local structs = raylib.structs

local function c3tr(c, transparency)
	local r, g, b = c:ToRGB()
	return structs.Color:new({
		r = r,
		g = g,
		b = b,
		a = math.floor(255 * (1 - transparency)),
	})
end

local rect = require("@arect")(raylib.lib)
local color3 = require("@Color3")

return function(objects, data)
	local config = {
		profiler = data.profiler,

		-- Colors
		backgroundColor = color3.new(0.09, 0.09, 0.11),
		panelColor = color3.new(0.12, 0.12, 0.14),
		headerColor = color3.new(0.15, 0.15, 0.17),
		gridColor = color3.new(0.2, 0.2, 0.22),
		textColor = color3.new(0.86, 0.86, 0.86),
		dimTextColor = color3.new(0.5, 0.5, 0.5),

		-- Zone colors
		zoneColors = {
			color3.new(0.3, 0.6, 1.0),
			color3.new(1.0, 0.4, 0.3),
			color3.new(0.3, 1.0, 0.5),
			color3.new(1.0, 0.7, 0.2),
			color3.new(0.7, 0.3, 1.0),
			color3.new(0.2, 0.9, 0.9),
			color3.new(1.0, 0.5, 0.8),
			color3.new(0.5, 1.0, 0.3),
		},
		zoneColorMap = {},

		-- Timeline view
		timelineViewStart = 0, -- frame index
		timelineViewEnd = 120, -- frame index
		timelineZoom = 1.0,
		timelineScroll = 0,

		-- Interaction
		hoveredZone = nil,
		hoveredWorker = nil,
		selectedZone = nil,
		isDragging = false,
		dragStartX = 0,
		dragStartScroll = 0,

		-- Layout
		topBarHeight = 35,
		workerRowHeight = 40,
		timelineHeight = 0, -- calculated
		statsHeight = 200,
		sidebarWidth = 280,

		-- Settings
		targetFrameTime = 1 / 60,
		showGrid = true,
		showStats = true,
		showTooltip = true,

		modifiers = {},
	}

	local function getZoneColor(zoneName)
		if not config.zoneColorMap[zoneName] then
			local idx = (#config.zoneColorMap % #config.zoneColors) + 1
			config.zoneColorMap[zoneName] = config.zoneColors[idx]
		end
		return config.zoneColorMap[zoneName]
	end

	local function hash(str)
		local h = 0
		for i = 1, #str do
			h = (h * 31 + string.byte(str, i)) % 2147483647
		end
		return h
	end

	local function getConsistentZoneColor(zoneName)
		local h = hash(zoneName)
		local idx = (h % #config.zoneColors) + 1
		return config.zoneColors[idx]
	end

	local wrapper = {}

	wrapper.set = function(prop, value)
		if type(config[prop]) == "function" then
			return wrapper
		end
		config[prop] = value
		return wrapper
	end

	wrapper.render = function(dt)
		if not config.profiler then
			return
		end

		local screenWidth = raylib.lib.GetScreenWidth()
		local screenHeight = raylib.lib.GetScreenHeight()
		local mousePos = raylib.lib.GetMousePosition()
		local mouseDown = raylib.lib.IsMouseButtonDown(0) == 1
		local mousePressed = raylib.lib.IsMouseButtonPressed(0) == 1
		local mouseReleased = raylib.lib.IsMouseButtonReleased(0) == 1
		local mouseWheel = raylib.lib.GetMouseWheelMove()

		local frames = config.profiler:GetFrames()
		local latestFrame = config.profiler:GetLatestFrame()

		if not frames or #frames == 0 then
			return
		end

		-- Background
		raylib.lib.ClearBackground(c3tr(config.backgroundColor, 0))

		-- Calculate layout
		local padding = 8
		local topBarY = 0
		local timelineY = topBarY + config.topBarHeight

		-- Count workers
		local workers = {}
		if latestFrame and latestFrame.workerZones then
			for workerName, _ in pairs(latestFrame.workerZones) do
				table.insert(workers, workerName)
			end
		end
		table.sort(workers)
		table.insert(workers, 1, "Main Thread") -- main thread at top

		local numWorkers = #workers
		config.timelineHeight = numWorkers * config.workerRowHeight

		local statsY = timelineY + config.timelineHeight + padding
		local mainWidth = screenWidth - config.sidebarWidth - padding

		-- === TOP BAR ===
		raylib.lib.DrawRectangle(0, topBarY, screenWidth, config.topBarHeight, c3tr(config.headerColor, 0))

		-- FPS and frame time
		local fps = 0
		local frameTime = 0
		if latestFrame then
			local totalTime = 0
			if latestFrame.zones then
				for _, zone in ipairs(latestFrame.zones) do
					totalTime = totalTime + (zone.duration or 0)
				end
			end
			if latestFrame.workerZones then
				for _, workerZones in pairs(latestFrame.workerZones) do
					for _, zone in ipairs(workerZones) do
						totalTime = math.max(
							totalTime,
							(zone.start or 0)
								+ (zone.duration or 0)
								- (latestFrame.zones[1] and latestFrame.zones[1].start or 0)
						)
					end
				end
			end
			frameTime = totalTime
			fps = totalTime > 0 and (1 / totalTime) or 0
		end

		raylib.lib.DrawText("Tracy-Style Profiler", padding, topBarY + 10, 16, c3tr(config.textColor, 0))

		local fpsColor = fps >= 55 and color3.new(0.3, 0.9, 0.3)
			or (fps >= 30 and color3.new(0.9, 0.7, 0.2) or color3.new(0.9, 0.3, 0.3))
		raylib.lib.DrawText(string.format("%.1f FPS", fps), screenWidth - 200, topBarY + 10, 14, c3tr(fpsColor, 0))
		raylib.lib.DrawText(
			string.format("%.2fms", frameTime * 1000),
			screenWidth - 100,
			topBarY + 10,
			14,
			c3tr(config.textColor, 0)
		)

		-- === TIMELINE ===
		local timelineRect = rect.new(0, timelineY, mainWidth, config.timelineHeight)
		raylib.lib.DrawRectangle(
			timelineRect.x,
			timelineRect.y,
			timelineRect.width,
			timelineRect.height,
			c3tr(config.panelColor, 0)
		)

		-- Handle timeline interaction
		if rect.MouseIsInRect(timelineRect) then
			-- Zoom with mouse wheel
			if mouseWheel ~= 0 then
				local oldZoom = config.timelineZoom
				config.timelineZoom = math.max(0.5, math.min(10, config.timelineZoom + mouseWheel * 0.1))

				-- Adjust scroll to zoom toward mouse
				local mouseFramePos = (mousePos.x - timelineRect.x) / timelineRect.width
				config.timelineScroll = config.timelineScroll
					+ (#frames * mouseFramePos * (1 / oldZoom - 1 / config.timelineZoom))
			end

			-- Pan with drag
			if mousePressed then
				config.isDragging = true
				config.dragStartX = mousePos.x
				config.dragStartScroll = config.timelineScroll
			end
		end

		if mouseReleased then
			config.isDragging = false
		end

		if config.isDragging then
			local dragDelta = mousePos.x - config.dragStartX
			local framesPerPixel = (#frames / config.timelineZoom) / timelineRect.width
			config.timelineScroll = config.dragStartScroll - dragDelta * framesPerPixel
		end

		config.timelineScroll = math.max(0, math.min(#frames - #frames / config.timelineZoom, config.timelineScroll))

		-- Calculate visible frame range
		local visibleFrames = math.ceil(#frames / config.timelineZoom)
		local startFrame = math.floor(config.timelineScroll) + 1
		local endFrame = math.min(#frames, startFrame + visibleFrames - 1)

		-- Draw grid lines
		if config.showGrid then
			local msPerLine = 5
			local maxTime = 0
			for i = startFrame, endFrame do
				local frame = frames[i]
				if frame and frame.zones then
					for _, zone in ipairs(frame.zones) do
						maxTime = math.max(maxTime, (zone.duration or 0))
					end
				end
			end
			maxTime = math.max(maxTime, config.targetFrameTime * 2)

			for ms = msPerLine, math.ceil(maxTime * 1000), msPerLine do
				local x = timelineRect.x + (ms / 1000 / maxTime) * timelineRect.width
				raylib.lib.DrawLine(
					x,
					timelineRect.y,
					x,
					timelineRect.y + timelineRect.height,
					c3tr(config.gridColor, 0)
				)
				raylib.lib.DrawText(
					string.format("%dms", ms),
					x + 2,
					timelineRect.y + 2,
					9,
					c3tr(config.dimTextColor, 0)
				)
			end
		end

		-- Draw worker rows
		config.hoveredZone = nil
		config.hoveredWorker = nil

		for workerIdx, workerName in ipairs(workers) do
			local rowY = timelineRect.y + (workerIdx - 1) * config.workerRowHeight
			local rowHeight = config.workerRowHeight

			-- Alternating row background
			if workerIdx % 2 == 0 then
				raylib.lib.DrawRectangle(0, rowY, mainWidth, rowHeight, c3tr(color3.new(0.1, 0.1, 0.12), 0.3))
			end

			-- Worker label
			raylib.lib.DrawText(workerName, padding, rowY + 12, 11, c3tr(config.textColor, 0))

			-- Separator line
			raylib.lib.DrawLine(0, rowY + rowHeight, mainWidth, rowY + rowHeight, c3tr(config.gridColor, 0))

			-- Draw zones for visible frames
			for frameIdx = startFrame, endFrame do
				local frame = frames[frameIdx]
				if not frame then
					continue
				end

				local zones = nil
				if workerName == "Main Thread" then
					zones = frame.zones
				elseif frame.workerZones then
					zones = frame.workerZones[workerName]
				end

				if zones then
					-- Calculate frame time offset
					local frameStartTime = 0
					local frameWidth = timelineRect.width / visibleFrames
					local frameX = timelineRect.x + (frameIdx - startFrame) * frameWidth

					-- Find max time for this frame to scale zones
					local maxFrameTime = config.targetFrameTime * 2
					for _, zone in ipairs(zones) do
						maxFrameTime = math.max(maxFrameTime, (zone.start or 0) + (zone.duration or 0))
					end

					for _, zone in ipairs(zones) do
						local zoneStart = (zone.start or frameStartTime) - frameStartTime
						local zoneDuration = zone.duration or 0

						if zoneDuration > 0 then
							local zoneX = frameX + (zoneStart / maxFrameTime) * frameWidth
							local zoneWidth = math.max(1, (zoneDuration / maxFrameTime) * frameWidth)
							local zoneY = rowY + 4
							local zoneHeight = rowHeight - 8

							local zoneColor = getConsistentZoneColor(zone.name)

							-- Draw zone
							raylib.lib.DrawRectangle(zoneX, zoneY, zoneWidth, zoneHeight, c3tr(zoneColor, 0))

							-- Zone border
							raylib.lib.DrawRectangleLines(
								zoneX,
								zoneY,
								zoneWidth,
								zoneHeight,
								c3tr(color3.new(0, 0, 0), 0.5)
							)

							-- Draw zone name if wide enough
							if zoneWidth > 30 then
								raylib.lib.DrawText(zone.name, zoneX + 2, zoneY + 8, 9, c3tr(color3.new(1, 1, 1), 0))
							end

							-- Check hover
							if
								mousePos.x >= zoneX
								and mousePos.x <= zoneX + zoneWidth
								and mousePos.y >= zoneY
								and mousePos.y <= zoneY + zoneHeight
							then
								config.hoveredZone = zone
								config.hoveredWorker = workerName

								-- Highlight on hover
								raylib.lib.DrawRectangle(
									zoneX,
									zoneY,
									zoneWidth,
									zoneHeight,
									c3tr(color3.new(1, 1, 1), 0.7)
								)
							end
						end

						frameStartTime = frameStartTime + zoneDuration
					end
				end

				continue
			end
		end

		-- === STATISTICS PANEL ===
		if config.showStats then
			local statsRect = rect.new(0, statsY, mainWidth, config.statsHeight)
			raylib.lib.DrawRectangle(
				statsRect.x,
				statsRect.y,
				statsRect.width,
				statsRect.height,
				c3tr(config.headerColor, 0)
			)

			raylib.lib.DrawText(
				"Statistics",
				statsRect.x + padding,
				statsRect.y + padding,
				13,
				c3tr(config.textColor, 0)
			)

			if latestFrame then
				-- Aggregate all zones
				local zoneStats = {}

				-- Main thread zones
				if latestFrame.zones then
					for _, zone in ipairs(latestFrame.zones) do
						local name = zone.name
						if not zoneStats[name] then
							zoneStats[name] = { count = 0, totalTime = 0, minTime = math.huge, maxTime = 0 }
						end
						local stat = zoneStats[name]
						stat.count = stat.count + 1
						stat.totalTime = stat.totalTime + (zone.duration or 0)
						stat.minTime = math.min(stat.minTime, zone.duration or 0)
						stat.maxTime = math.max(stat.maxTime, zone.duration or 0)
					end
				end

				-- Worker zones
				if latestFrame.workerZones then
					for workerName, workerZones in pairs(latestFrame.workerZones) do
						for _, zone in ipairs(workerZones) do
							local name = workerName .. "::" .. zone.name
							if not zoneStats[name] then
								zoneStats[name] = { count = 0, totalTime = 0, minTime = math.huge, maxTime = 0 }
							end
							local stat = zoneStats[name]
							stat.count = stat.count + 1
							stat.totalTime = stat.totalTime + (zone.duration or 0)
							stat.minTime = math.min(stat.minTime, zone.duration or 0)
							stat.maxTime = math.max(stat.maxTime, zone.duration or 0)
						end
					end
				end

				-- Sort by total time
				local sortedStats = {}
				for name, stat in pairs(zoneStats) do
					table.insert(sortedStats, { name = name, stat = stat })
				end
				table.sort(sortedStats, function(a, b)
					return a.stat.totalTime > b.stat.totalTime
				end)

				-- Draw table
				local tableY = statsRect.y + padding + 25
				local colX = {
					statsRect.x + padding,
					statsRect.x + 200,
					statsRect.x + 300,
					statsRect.x + 380,
					statsRect.x + 460,
					statsRect.x + 560,
				}

				-- Headers
				raylib.lib.DrawText("Zone", colX[1], tableY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText("Total", colX[2], tableY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText("Avg", colX[3], tableY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText("Min", colX[4], tableY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText("Max", colX[5], tableY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText("Calls", colX[6], tableY, 10, c3tr(config.dimTextColor, 0))
				tableY = tableY + 18

				for i, entry in ipairs(sortedStats) do
					if tableY > statsRect.y + statsRect.height - 20 then
						break
					end

					local name = entry.name
					local stat = entry.stat
					local avg = stat.totalTime / stat.count

					local displayName = name
					if #displayName > 25 then
						displayName = string.sub(displayName, 1, 22) .. "..."
					end

					raylib.lib.DrawText(displayName, colX[1], tableY, 9, c3tr(config.textColor, 0))
					raylib.lib.DrawText(
						string.format("%.2fms", stat.totalTime * 1000),
						colX[2],
						tableY,
						9,
						c3tr(config.textColor, 0)
					)
					raylib.lib.DrawText(
						string.format("%.2fms", avg * 1000),
						colX[3],
						tableY,
						9,
						c3tr(config.textColor, 0)
					)
					raylib.lib.DrawText(
						string.format("%.2fms", stat.minTime * 1000),
						colX[4],
						tableY,
						9,
						c3tr(config.textColor, 0)
					)
					raylib.lib.DrawText(
						string.format("%.2fms", stat.maxTime * 1000),
						colX[5],
						tableY,
						9,
						c3tr(config.textColor, 0)
					)
					raylib.lib.DrawText(tostring(stat.count), colX[6], tableY, 9, c3tr(config.textColor, 0))

					tableY = tableY + 16
				end
			end
		end

		-- === SIDEBAR ===
		local sidebarX = mainWidth + padding
		raylib.lib.DrawRectangle(sidebarX, 0, config.sidebarWidth, screenHeight, c3tr(config.headerColor, 0))

		local sideY = padding + 10
		raylib.lib.DrawText("Counters", sidebarX + padding, sideY, 13, c3tr(config.textColor, 0))
		sideY = sideY + 25

		-- Draw counters
		local counters = config.profiler:GetCounters()
		if counters then
			for name, value in pairs(counters) do
				if sideY > screenHeight - 30 then
					break
				end

				raylib.lib.DrawText(name, sidebarX + padding, sideY, 10, c3tr(config.dimTextColor, 0))
				raylib.lib.DrawText(tostring(value), sidebarX + padding + 140, sideY, 10, c3tr(config.textColor, 0))
				sideY = sideY + 18
			end
		end

		-- === TOOLTIP ===
		if config.showTooltip and config.hoveredZone then
			local zone = config.hoveredZone
			local tooltipWidth = 200
			local tooltipHeight = 70
			local tooltipX = math.min(mousePos.x + 15, screenWidth - tooltipWidth - 10)
			local tooltipY = math.min(mousePos.y + 15, screenHeight - tooltipHeight - 10)

			-- Tooltip background
			raylib.lib.DrawRectangle(
				tooltipX,
				tooltipY,
				tooltipWidth,
				tooltipHeight,
				c3tr(color3.new(0.15, 0.15, 0.17), 0)
			)
			raylib.lib.DrawRectangleLines(
				tooltipX,
				tooltipY,
				tooltipWidth,
				tooltipHeight,
				c3tr(color3.new(0.4, 0.4, 0.4), 0)
			)

			-- Tooltip content
			local ty = tooltipY + 8
			raylib.lib.DrawText(zone.name, tooltipX + 8, ty, 11, c3tr(config.textColor, 0))
			ty = ty + 18

			if config.hoveredWorker then
				raylib.lib.DrawText(
					"Worker: " .. config.hoveredWorker,
					tooltipX + 8,
					ty,
					9,
					c3tr(config.dimTextColor, 0)
				)
				ty = ty + 14
			end

			raylib.lib.DrawText(
				string.format("Duration: %.3fms", (zone.duration or 0) * 1000),
				tooltipX + 8,
				ty,
				9,
				c3tr(config.textColor, 0)
			)
			ty = ty + 14

			raylib.lib.DrawText(
				string.format("%.1f%%", (zone.duration or 0) / frameTime * 100),
				tooltipX + 8,
				ty,
				9,
				c3tr(config.dimTextColor, 0)
			)
		end

		for _, m in pairs(config.modifiers) do
			m()
		end
	end

	table.insert(objects, wrapper)
	return wrapper
end
