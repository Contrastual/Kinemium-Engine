-- buffer.lua
local buffer = {}
buffer.__index = buffer

function buffer.create()
	return setmetatable({
		lines = { "" },
		cursor = { line = 1, col = 1 },
		selection = { active = false, startLine = 1, startCol = 1, endLine = 1, endCol = 1 },
	}, buffer)
end

function buffer:insertChar(ch)
	local line = self.lines[self.cursor.line]
	local left = line:sub(1, self.cursor.col - 1)
	local right = line:sub(self.cursor.col)

	self.lines[self.cursor.line] = left .. ch .. right
	self.cursor.col += 1
end

function buffer:backspace()
	local c = self.cursor
	local line = self.lines[c.line]

	if c.col > 1 then
		self.lines[c.line] = line:sub(1, c.col - 2) .. line:sub(c.col)
		c.col -= 1
		return
	end

	if c.line == 1 then
		return
	end

	local prevLine = self.lines[c.line - 1]
	self.lines[c.line - 1] = prevLine .. line

	table.remove(self.lines, c.line)

	c.line -= 1
	c.col = #prevLine + 1
end

function buffer:newline()
	local c = self.cursor
	local line = self.lines[c.line]

	local left = line:sub(1, c.col - 1)
	local right = line:sub(c.col)

	self.lines[c.line] = left
	table.insert(self.lines, c.line + 1, right)

	c.line += 1
	c.col = 1
end

function buffer:moveLeft()
	local c = self.cursor
	if c.col > 1 then
		c.col -= 1
	elseif c.line > 1 then
		c.line -= 1
		c.col = #self.lines[c.line] + 1
	end
end

function buffer:moveRight()
	local c = self.cursor
	local line = self.lines[c.line]

	if c.col <= #line then
		c.col += 1
	elseif c.line < #self.lines then
		c.line += 1
		c.col = 1
	end
end

function buffer:moveUp()
	local c = self.cursor
	if c.line > 1 then
		c.line -= 1
		local len = self._lineLengths and self._lineLengths[c.line] or #self.lines[c.line]
		c.col = math.min(c.col, len + 1)
	end
end

function buffer:moveDown()
	local c = self.cursor
	if c.line < #self.lines then
		c.line += 1
		local len = self._lineLengths and self._lineLengths[c.line] or #self.lines[c.line]
		c.col = math.min(c.col, len + 1)
	end
end

function buffer:delete()
	local c = self.cursor
	local line = self.lines[c.line]

	if c.col <= #line then
		self.lines[c.line] = line:sub(1, c.col - 1) .. line:sub(c.col + 1)
		return
	end

	if c.line < #self.lines then
		self.lines[c.line] = self.lines[c.line] .. self.lines[c.line + 1]
		table.remove(self.lines, c.line + 1)
	end
end

function buffer:insertString(str)
	local lines = string.split(str, "\n")
	if #lines == 1 then
		local c = self.cursor
		local line = self.lines[c.line]
		self.lines[c.line] = line:sub(1, c.col - 1) .. lines[1] .. line:sub(c.col)
		c.col += #lines[1]
		return
	end

	local c = self.cursor
	local line = self.lines[c.line]
	local left = line:sub(1, c.col - 1)
	local right = line:sub(c.col)

	self.lines[c.line] = left .. lines[1]

	for i = 2, #lines - 1 do
		table.insert(self.lines, c.line + i - 1, lines[i])
	end

	table.insert(self.lines, c.line + #lines - 1, lines[#lines] .. right)

	c.line += #lines - 1
	c.col = #lines[#lines] + 1
end

function buffer:getText()
	return table.concat(self.lines, "\n")
end

function buffer:setCursor(line, col)
	line = math.clamp(line, 1, #self.lines)
	col = math.clamp(col, 1, #(self.lines[line] or "") + 1)

	self.cursor.line = line
	self.cursor.col = col
end

function buffer:getSelectionRange()
	if not self.selection.active then
		return nil
	end

	local sL, sC, eL, eC =
		self.selection.startLine, self.selection.startCol, self.selection.endLine, self.selection.endCol

	if sL > eL or (sL == eL and sC > eC) then
		sL, sC, eL, eC = eL, eC, sL, sC
	end

	-- Clamp lines
	sL = math.clamp(sL, 1, #self.lines)
	eL = math.clamp(eL, 1, #self.lines)

	-- Clamp cols if needed, but sub handles it. However, sub(0) is valid in Lua (returns whole string usually or acts weird? sub(1) is start).
	-- math.max(1, sC)
	sC = math.max(1, sC)
	eC = math.max(1, eC)

	return sL, sC, eL, eC
end

function buffer:deleteSelection()
	local sL, sC, eL, eC = self:getSelectionRange()
	if not sL then
		return
	end

	if sL == eL then
		local line = self.lines[sL]
		self.lines[sL] = line:sub(1, sC - 1) .. line:sub(eC)
	else
		local firstLine = self.lines[sL]:sub(1, sC - 1)
		local lastLine = (self.lines[eL] or ""):sub(eC)
		self.lines[sL] = firstLine .. lastLine

		local linesToRemove = eL - sL
		local len = #self.lines

		-- Optimization: Move lines instead of removing one by one
		if eL < len then
			table.move(self.lines, eL + 1, len, sL + 1)
		end

		-- Clear trailing lines
		for i = len, len - linesToRemove + 1, -1 do
			self.lines[i] = nil
		end
	end

	self:setCursor(sL, sC)
	self.selection.active = false
end

function buffer:getSelectedText()
	local sL, sC, eL, eC = self:getSelectionRange()
	if not sL then
		return ""
	end

	if sL == eL then
		return self.lines[sL]:sub(sC, eC - 1)
	end

	local result = { self.lines[sL]:sub(sC) }
	for i = sL + 1, eL - 1 do
		table.insert(result, self.lines[i])
	end
	table.insert(result, self.lines[eL]:sub(1, eC - 1))

	return table.concat(result, "\n")
end

function buffer:clear()
	self.lines = { "" }
	self.cursor.line = 1
	self.cursor.col = 1
	self.selection.active = false
end

function buffer:moveLineUp()
	local sL, _sC, eL, _eC = self:getSelectionRange()
	if sL then
		if sL > 1 then
			local prevLine = self.lines[sL - 1]
			table.remove(self.lines, sL - 1)
			table.insert(self.lines, eL, prevLine)
			self.selection.startLine -= 1
			self.selection.endLine -= 1
			self.cursor.line -= 1
		end
	else
		local c = self.cursor
		if c.line > 1 then
			local line = self.lines[c.line]
			table.remove(self.lines, c.line)
			table.insert(self.lines, c.line - 1, line)
			c.line -= 1
		end
	end
end

function buffer:moveLineDown()
	local sL, _sC, eL, _eC = self:getSelectionRange()
	if sL then
		if eL < #self.lines then
			local nextLine = self.lines[eL + 1]
			table.remove(self.lines, eL + 1)
			table.insert(self.lines, sL, nextLine)
			self.selection.startLine += 1
			self.selection.endLine += 1
			self.cursor.line += 1
		end
	else
		local c = self.cursor
		if c.line < #self.lines then
			local line = self.lines[c.line]
			table.remove(self.lines, c.line)
			table.insert(self.lines, c.line + 1, line)
			c.line += 1
		end
	end
end

function buffer:duplicateLine()
	local sL, sC, eL, eC = self:getSelectionRange()
	if sL then
		local text = self:getSelectedText()

		self:setCursor(eL, eC)
		self:insertString(text)

		-- Restore selection? Maybe not.
		self.selection.active = false
	else
		local c = self.cursor
		local line = self.lines[c.line]
		table.insert(self.lines, c.line + 1, line)
		-- Move down to the new line
		c.line += 1
	end
end

function buffer:deleteCurrentLine()
	local sL, sC, eL, eC = self:getSelectionRange()
	if sL then
		local count = eL - sL + 1
		for i = 1, count do
			table.remove(self.lines, sL)
		end
		if #self.lines == 0 then
			self.lines = { "" }
		end
		self.cursor.line = math.min(sL, #self.lines)
		self.selection.active = false
	else
		local c = self.cursor
		table.remove(self.lines, c.line)
		if #self.lines == 0 then
			self.lines = { "" }
		end
		c.line = math.min(c.line, #self.lines)
	end

	local len = #(self.lines[self.cursor.line] or "")
	self.cursor.col = math.min(self.cursor.col, len + 1)
end

function buffer:toggleLineComment(commentPrefix)
	commentPrefix = commentPrefix or "--"
	local sL, _sC, eL, _eC = self:getSelectionRange()
	local startL = sL or self.cursor.line
	local endL = eL or self.cursor.line

	-- Check if all lines are commented
	local allCommented = true
	-- Count non-empty lines
	local nonEmptyCount = 0

	for i = startL, endL do
		local line = self.lines[i]
		local _indent, content = line:match("^(%s*)(.*)")
		if #content > 0 then
			nonEmptyCount += 1
			if not content:find("^" .. commentPrefix) then
				allCommented = false
			end
		end
	end

	if nonEmptyCount == 0 then
		allCommented = false
	end -- If only empty lines, usually we comment them? Or toggle? Let's assume we comment.

	for i = startL, endL do
		local line = self.lines[i]
		local indent, content = line:match("^(%s*)(.*)")
		if #content > 0 or not allCommented then
			if allCommented then
				-- Uncomment
				if content:sub(1, #commentPrefix) == commentPrefix then
					local newContent = content:sub(#commentPrefix + 1)
					-- Remove optional space
					if newContent:sub(1, 1) == " " then
						newContent = newContent:sub(2)
					end
					self.lines[i] = indent .. newContent
				end
			else
				-- Comment
				-- Insert comment at indent
				self.lines[i] = indent .. commentPrefix .. " " .. content
			end
		end
	end
end

return buffer
