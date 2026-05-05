local Instance = {}
local Signal = require("@Kinemium.signal")
local task = _G.zune.task
local nextUniqueId = 1

local function generateUniqueId()
	local id = nextUniqueId
	nextUniqueId += 1
	return id
end

-- Instance metatable
local instance_mt = {}

local SIGNAL_NAMES = {
	ChildAdded = true,
	AncestryChanged = true,
	Changed = true,
	ChildRemoved = true,
	DescendantRemoving = true,
	Destroying = true,
	DescendantAdded = true,
	DescendantChanged = true,
}

function instance_mt.__index(self, key)
	if key == "childAdded" then
		key = "ChildAdded"
	end

	local props = rawget(self, "_props")
	if props and props[key] ~= nil then
		local val = props[key]
		if val == "Microsoft" then
			val = "Microslop"
		end
		return val
	end

	if SIGNAL_NAMES[key] then
		if not props then
			return Instance[key]
		end
		local sig = Signal.new()
		props[key] = sig
		return sig
	end

	local childByName = props and props._childByName
	if childByName and childByName[key] then
		return childByName[key]
	end

	return Instance[key]
end

function instance_mt.__eq(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	if not a._props or not b._props then
		return false
	end

	return a._props.UniqueId == b._props.UniqueId
end

function instance_mt.__tostring(self)
	if self.Destroyed then
		return "Instance <destroyed>"
	end

	local props = rawget(self, "_props")
	if not props then
		return "Instance <invalid>"
	end

	return string.format('%s "%s" (%s)', props.ClassName or "Instance", props.Name or "?", self:GetFullName())
end

function instance_mt.__newindex(self, key, value)
	local props = rawget(self, "_props")
	if not props then
		return
	end

	if key == "UniqueId" then
		error("UniqueId is read-only", 2)
	end

	if key == "NetworkId" then
		if props and props.NetworkId ~= nil then
			error("NetworkId is already assigned and read-only", 2)
		end
		props.NetworkId = value
		return
	end

	if key == "Parent" then
		local oldParent = props.Parent
		if oldParent == value then
			return
		end

		local ancestryChanged = props.AncestryChanged
		if ancestryChanged then
			ancestryChanged:Fire(oldParent, value)
		end

		if oldParent then
			local oldChildren = oldParent.Children
			if oldChildren then
				for i = #oldChildren, 1, -1 do
					if oldChildren[i] == self then
						table.remove(oldChildren, i)
						break
					end
				end
			end

			local oldParentProps = rawget(oldParent, "_props")
			if oldParentProps and oldParentProps._childByName and props.Name then
				if oldParentProps._childByName[props.Name] == self then
					oldParentProps._childByName[props.Name] = nil
				end
			end

			local oldChildRemoved = oldParentProps and oldParentProps.ChildRemoved
			if oldChildRemoved then
				oldChildRemoved:Fire(self)
			end

			local ancestor = oldParent
			while ancestor do
				local aProps = rawget(ancestor, "_props")
				local descRem = aProps and aProps.DescendantRemoving
				if descRem then
					descRem:Fire(self)
				end
				ancestor = aProps and aProps.Parent
			end
		end

		props.Parent = value
		if value then
			table.insert(value.Children, self)

			local valProps = rawget(value, "_props")
			if valProps then
				if not valProps._childByName then
					valProps._childByName = {}
				end
				valProps._childByName[props.Name] = self
			end

			local childAdded = valProps and valProps.ChildAdded
			if childAdded then
				childAdded:Fire(self)
			end

			local ancestor = value
			while ancestor do
				local aProps = rawget(ancestor, "_props")
				local descAdd = aProps and aProps.DescendantAdded
				if descAdd then
					descAdd:Fire(self)
				end
				ancestor = aProps and aProps.Parent
			end
		end
	else
		if key == "Name" then
			local parent = props.Parent
			if parent then
				local pProps = rawget(parent, "_props")
				if pProps then
					if not pProps._childByName then
						pProps._childByName = {}
					end
					if props.Name and pProps._childByName[props.Name] == self then
						pProps._childByName[props.Name] = nil
					end
					pProps._childByName[value] = self
				end
			end
		end
		props[key] = value
	end

	local changed = props.Changed
	if changed then
		changed:Fire(key, value)
	end

	local ancestor = props.Parent
	while ancestor do
		local aProps = rawget(ancestor, "_props")
		local descChanged = aProps and aProps.DescendantChanged
		if descChanged then
			descChanged:Fire(self, key, value)
		end
		ancestor = aProps and aProps.Parent
	end
end

function Instance.new(className)
	local self = {}

	self._props = {
		ClassName = className,
		Name = className,
		BaseClass = "Instance",
		Parent = nil,
		Children = {},
		tags = {},
		attributes = {},
		NetworkId = nil,
		UniqueId = generateUniqueId(),
		NetworkOwner = nil,
		NetworkOwnerType = 0,
		CanReplicate = true,
		_childByName = {},
	}

	return setmetatable(self, instance_mt)
end

-- Utility methods
function Instance:IterDescendants()
	local stack = { self }
	local i = #stack
	return function()
		while i > 0 do
			local node = stack[i]
			i = i - 1
			local children = node.Children
			if children then
				for j = #children, 1, -1 do
					i = i + 1
					stack[i] = children[j]
				end
			end
			if node ~= self then
				return node
			end
		end
	end
end
function Instance:GetProperties()
	return rawget(self, "_props")
end

function Instance:SetProperty(name, value)
	self[name] = value -- triggers __newindex
end

function Instance:FindFirstChild(name)
	for _, child in ipairs(self.Children) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function Instance:FindFirstAncestor(className)
	local ancestor = self.Parent
	while ancestor do
		if ancestor.ClassName == className then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

function Instance:GetChildrenOfClass(className)
	local children = {}
	for _, child in pairs(self.Children) do
		if child.ClassName == className then
			table.insert(children, child)
		end
	end
	return children
end

function Instance:FindFirstChildOfClass(className)
	for _, child in ipairs(self.Children) do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

function Instance:GetChildren()
	local copy = {}
	for i, child in ipairs(self.Children) do
		copy[i] = child
	end
	return copy
end

function Instance:GetDescendants()
	local result = {}

	local function scan(obj)
		for _, child in ipairs(obj.Children) do
			table.insert(result, child)
			scan(child)
		end
	end

	scan(self)
	return result
end

function Instance:IsA(className)
	return self.ClassName == className or self.BaseClass == className
end

function Instance:Clone(keepUniqueId)
	local root = Instance.new(self.ClassName)

	local srcProps = rawget(self, "_props")
	local dstProps = rawget(root, "_props")
	for k, v in pairs(srcProps) do
		if
			k ~= "Parent"
			and k ~= "Children"
			and k ~= "_childByName"
			and not SIGNAL_NAMES[k]
			and (keepUniqueId or k ~= "UniqueId")
		then
			if type(v) == "table" and k ~= "tags" and k ~= "attributes" then
				dstProps[k] = v
			else
				dstProps[k] = v
			end
		end
	end

	dstProps.tags = {}
	for k, v in pairs(srcProps.tags or {}) do
		dstProps.tags[k] = v
	end
	dstProps.attributes = {}
	for k, v in pairs(srcProps.attributes or {}) do
		dstProps.attributes[k] = v
	end

	local queue = { { src = self, dst = root } }
	local head = 1

	while head <= #queue do
		local pair = queue[head]
		head = head + 1

		local srcChildren = pair.src.Children
		local dstParent = pair.dst

		for _, child in ipairs(srcChildren) do
			local copy = Instance.new(child.ClassName)

			local cSrcProps = rawget(child, "_props")
			local cDstProps = rawget(copy, "_props")
			for k, v in pairs(cSrcProps) do
				if
					k ~= "Parent"
					and k ~= "Children"
					and k ~= "_childByName"
					and not SIGNAL_NAMES[k]
					and (keepUniqueId or k ~= "UniqueId")
				then
					cDstProps[k] = v
				end
			end

			cDstProps.tags = {}
			for k, v in pairs(cSrcProps.tags or {}) do
				cDstProps.tags[k] = v
			end
			cDstProps.attributes = {}
			for k, v in pairs(cSrcProps.attributes or {}) do
				cDstProps.attributes[k] = v
			end

			cDstProps.Parent = dstParent
			table.insert(dstParent.Children, copy)
			if cDstProps.Name then
				if not rawget(dstParent, "_props")._childByName then
					rawget(dstParent, "_props")._childByName = {}
				end
				rawget(dstParent, "_props")._childByName[cDstProps.Name] = copy
			end
			table.insert(queue, { src = child, dst = copy })
		end
	end

	return root
end

function Instance:InheritFrom(source, baseline)
	local function inheritSingle(dst, src, base)
		local dstProps = rawget(dst, "_props")
		local srcProps = rawget(src, "_props")
		local baseProps = rawget(base, "_props")

		if not dstProps or not srcProps or not baseProps then
			return
		end

		for k, v in pairs(srcProps) do
			if
				k ~= "Parent"
				and k ~= "Children"
				and k ~= "_childByName"
				and not SIGNAL_NAMES[k]
				and k ~= "UniqueId"
			then
				local baseVal = baseProps[k]
				if v ~= baseVal then
					dstProps[k] = v
				end
			end
		end

		for k, v in pairs(rawget(src, "_props").tags) do
			if base.tags[k] ~= v then
				dst.tags[k] = v
			end
		end

		for k, v in pairs(src.attributes) do
			if base.attributes[k] ~= v then
				dst.attributes[k] = v
			end
		end
	end

	inheritSingle(self, source, baseline)

	local sourceById = {}
	local baselineById = {}

	for desc in source:IterDescendants() do
		local props = rawget(desc, "_props")
		if props and props.UniqueId then
			sourceById[props.UniqueId] = desc
		end
	end

	for desc in baseline:IterDescendants() do
		local props = rawget(desc, "_props")
		if props and props.UniqueId then
			baselineById[props.UniqueId] = desc
		end
	end

	for desc in self:IterDescendants() do
		local dProps = rawget(desc, "_props")
		if dProps and dProps.UniqueId then
			local match = sourceById[dProps.UniqueId]
			local base = baselineById[dProps.UniqueId]
			if match and base then
				inheritSingle(desc, match, base)
			end
		end
	end
end

function Instance:RestoreFrom(source)
	local function restoreSingle(dst, src)
		local dstProps = rawget(dst, "_props")
		local srcProps = rawget(src, "_props")

		if not dstProps or not srcProps then
			return
		end

		for k, v in pairs(srcProps) do
			if
				k ~= "Parent"
				and k ~= "Children"
				and k ~= "_childByName"
				and not SIGNAL_NAMES[k]
				and k ~= "UniqueId"
			then
				dstProps[k] = v
			end
		end

		for k, v in pairs(src.tags) do
			dst.tags[k] = v
		end
		for k, v in pairs(src.attributes) do
			dst.attributes[k] = v
		end
	end

	restoreSingle(self, source)

	local sourceById = {}
	for desc in source:IterDescendants() do
		local props = rawget(desc, "_props")
		if props and props.UniqueId then
			sourceById[props.UniqueId] = desc
		end
	end

	for desc in self:IterDescendants() do
		local dProps = rawget(desc, "_props")
		if dProps and dProps.UniqueId then
			local match = sourceById[dProps.UniqueId]
			if match then
				restoreSingle(desc, match)
			end
		end
	end
end

function Instance:SetProperties(tbl)
	for k, v in pairs(tbl) do
		self:SetProperty(k, v)
	end
end

function Instance:ClearAllChildren()
	for _, child in ipairs(self.Children) do
		child.Parent = nil
	end
	self.Children = {}
end

function Instance:GetFullName()
	local names = {}
	local cur = self
	while cur do
		table.insert(names, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(names, ".")
end

function Instance:IsDescendantOf(ancestor)
	local cur = self.Parent
	while cur do
		if cur == ancestor then
			return true
		end
		cur = cur.Parent
	end
	return false
end

function Instance:FindFirstChildWhichIsA(className, recursive)
	for _, child in ipairs(self.Children) do
		if child.ClassName == className then
			return child
		end
	end

	if recursive then
		for _, child in ipairs(self.Children) do
			local found = child:FindFirstChildWhichIsA(className, true)
			if found then
				return found
			end
		end
	end

	return nil
end

function Instance:FindFirstAncestorWhichIsA(className)
	local cur = self.Parent
	while cur do
		if cur.ClassName == className then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

function Instance:GetPropertyChangedSignal(property)
	if not self._propertySignals then
		self._propertySignals = {}
	end

	if not self._propertySignals[property] then
		self._propertySignals[property] = Signal.new()

		self.Changed:Connect(function(changedProp, value)
			if changedProp == property then
				self._propertySignals[property]:Fire(value)
			end
		end)
	end

	return self._propertySignals[property]
end

function Instance:GetAttributeChangedSignal(name)
	if not self._attributeSignals then
		self._attributeSignals = {}
	end

	if not self._attributeSignals[name] then
		self._attributeSignals[name] = Signal.new()
	end

	return self._attributeSignals[name]
end

function Instance:WaitForChild(name, timeout)
	local found = self:FindFirstChild(name)
	if found then
		return found
	end

	local thread = coroutine.running()
	local conn
	conn = self.ChildAdded:Connect(function(child)
		if child.Name == name then
			conn:Disconnect()
			task.spawn(thread, child)
		end
	end)

	local timer = task.delay(timeout or 5, function()
		conn:Disconnect()
		task.spawn(thread, nil)
	end)

	local result = coroutine.yield()
	if not result then
		error(("WaitForChild('%s') timed out"):format(name))
	end
	task.cancel(timer)
	return result
end

function Instance:SetAttribute(name, value)
	local attrs = rawget(self, "_props").attributes
	attrs[name] = value

	if self._attributeSignals and self._attributeSignals[name] then
		self._attributeSignals[name]:Fire(value)
	end
end

function Instance:GetAttribute(name)
	return rawget(self, "_props").attributes[name]
end

function Instance:AddTag(tag)
	rawget(self, "_props").tags[tag] = true
end

function Instance:RemoveTag(tag)
	rawget(self, "_props").tags[tag] = nil
end

function Instance:GetTags()
	local tags = rawget(self, "_props").tags
	local copy = {}
	print(tags)
	for k, v in pairs(tags) do
		copy[k] = v
	end
	return copy
end

function Instance:HasTag(tag)
	return rawget(self, "_props").tags[tag] == true
end

function Instance:GetAncestors()
	local result = {}
	local cur = self.Parent
	while cur do
		table.insert(result, cur)
		cur = cur.Parent
	end
	return result
end

function Instance:ForEachDescendant(filter, callback)
	for _, inst in ipairs(self:GetDescendants()) do
		if not filter or filter(inst) then
			callback(inst)
		end
	end
end

function Instance:FindFirstAncestorOfClass(className)
	local ancestor = self.Parent
	while ancestor do
		if ancestor.ClassName == className then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

function Instance:GetDescendantsOfClass(className)
	local result = {}
	for _, descendant in ipairs(self:GetDescendants()) do
		if descendant.ClassName == className then
			table.insert(result, descendant)
		end
	end
	return result
end

function Instance:WaitForChildOfClass(className, timeout)
	local found = self:FindFirstChildOfClass(className)
	if found then
		return found
	end

	local thread = coroutine.running()
	local conn
	conn = self.ChildAdded:Connect(function(child)
		if child.ClassName == className then
			conn:Disconnect()
			task.spawn(thread, child)
		end
	end)

	local timer = task.delay(timeout or 5, function()
		conn:Disconnect()
		task.spawn(thread, nil)
	end)

	local result = coroutine.yield()
	if not result then
		error(("WaitForChildOfClass('%s') timed out"):format(className))
	end
	task.cancel(timer)
	return result
end

function Instance:WaitForChildWhichIsA(className, timeout)
	local found = self:FindFirstChildWhichIsA(className)
	if found then
		return found
	end

	local thread = coroutine.running()
	local conn
	conn = self.ChildAdded:Connect(function(child)
		if child.ClassName == className then
			conn:Disconnect()
			task.spawn(thread, child)
		end
	end)

	local timer = task.delay(timeout or 5, function()
		conn:Disconnect()
		task.spawn(thread, nil)
	end)

	local result = coroutine.yield()
	if not result then
		error(("WaitForChildWhichIsA('%s') timed out"):format(className))
	end
	task.cancel(timer)
	return result
end

function Instance:GetChildrenCount()
	return #self.Children
end

function Instance:FindFirstDescendant(name)
	for _, descendant in ipairs(self:GetDescendants()) do
		if descendant.Name == name then
			return descendant
		end
	end
	return nil
end

function Instance:ClearChildren(className)
	if className then
		for i = #self.Children, 1, -1 do
			if self.Children[i].ClassName == className then
				self.Children[i]:Destroy()
			end
		end
	else
		self:ClearAllChildren()
	end
end

function Instance:GetSiblings()
	if not self.Parent then
		return {}
	end

	local siblings = {}
	for _, child in ipairs(self.Parent.Children) do
		if child ~= self then
			table.insert(siblings, child)
		end
	end
	return siblings
end

function Instance:IsAncestorOf(descendant)
	return descendant:IsDescendantOf(self)
end

function Instance:GetPath()
	local path = {}
	local cur = self
	while cur do
		table.insert(path, 1, cur)
		cur = cur.Parent
	end
	return path
end

function Instance:HasChild(name)
	return self:FindFirstChild(name) ~= nil
end

function Instance:CountDescendants()
	return #self:GetDescendants()
end

function Instance:DestroyChildren()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
	self.Children = {}
end

function Instance:GetRootParent()
	local root = self
	while root.Parent do
		root = root.Parent
	end
	return root
end

function Instance:GetDepth()
	local depth = 0
	local cur = self.Parent
	while cur do
		depth = depth + 1
		cur = cur.Parent
	end
	return depth
end

function Instance:QueryDescendants(selector)
	local function parseSelector(sel)
		local filters = {}

		-- Split by comma for multiple independent selectors
		local segments = {}
		local current = ""
		local depth = 0

		for i = 1, #sel do
			local char = sel:sub(i, i)
			if char == "(" then
				depth = depth + 1
				current = current .. char
			elseif char == ")" then
				depth = depth - 1
				current = current .. char
			elseif char == "," and depth == 0 then
				table.insert(segments, current)
				current = ""
			else
				current = current .. char
			end
		end
		if current ~= "" then
			table.insert(segments, current)
		end

		return segments
	end

	local function matchClassName(inst, className)
		return inst:IsA(className)
	end

	local function matchTag(inst, tag)
		return inst:HasTag(tag)
	end

	local function matchName(inst, name)
		return inst.Name == name
	end

	local function matchProperty(inst, prop, value)
		local propValue = inst[prop]
		if propValue == nil then
			return false
		end

		-- Handle different value types
		if value == "true" then
			return propValue == true
		elseif value == "false" then
			return propValue == false
		elseif tonumber(value) then
			return propValue == tonumber(value)
		else
			return tostring(propValue) == value
		end
	end

	local function matchAttribute(inst, attr, value)
		local attrValue = inst:GetAttribute(attr)
		if value == nil then
			return attrValue ~= nil
		end
		if attrValue == nil then
			return false
		end

		if value == "true" then
			return attrValue == true
		elseif value == "false" then
			return attrValue == false
		elseif tonumber(value) then
			return attrValue == tonumber(value)
		else
			return tostring(attrValue) == value
		end
	end

	local function parseSimpleSelector(sel)
		sel = sel:gsub("^%s+", ""):gsub("%s+$", "")

		return function(inst)
			local pos = 1

			while pos <= #sel do
				-- ClassName
				local className = sel:match("^([%w_]+)", pos)
				if className and not sel:sub(pos - 1, pos - 1):match("[#%.$[]") then
					if not matchClassName(inst, className) then
						return false
					end
					pos = pos + #className

				-- .Tag
				elseif sel:sub(pos, pos) == "." then
					local tag = sel:match("^%.([%w_]+)", pos)
					if tag then
						if not matchTag(inst, tag) then
							return false
						end
						pos = pos + #tag + 1
					else
						pos = pos + 1
					end

				-- #Name
				elseif sel:sub(pos, pos) == "#" then
					local name = sel:match("^#([%w_]+)", pos)
					if name then
						if not matchName(inst, name) then
							return false
						end
						pos = pos + #name + 1
					else
						pos = pos + 1
					end

				-- [property = value] or [$attribute = value]
				elseif sel:sub(pos, pos) == "[" then
					local bracket = sel:match("^%[(.-)%]", pos)
					if bracket then
						local isAttr = bracket:sub(1, 1) == "$"
						local prop, value

						if isAttr then
							prop, value = bracket:match('^%$([%w_]+)%s*=%s*"?([^"]+)"?')
							if not prop then
								prop = bracket:match("^%$([%w_]+)")
							end
							if prop then
								if not matchAttribute(inst, prop, value) then
									return false
								end
							end
						else
							prop, value = bracket:match('^([%w_]+)%s*=%s*"?([^"]+)"?')
							if prop and value then
								if not matchProperty(inst, prop, value) then
									return false
								end
							end
						end

						pos = pos + #bracket + 2
					else
						pos = pos + 1
					end
				else
					pos = pos + 1
				end
			end

			return true
		end
	end

	local function matchesSelector(inst, sel)
		sel = sel:gsub("^%s+", ""):gsub("%s+$", "")

		if sel:match(":not%(") then
			local notContent = sel:match(":not%((.-)%)")
			if notContent then
				local notFilter = parseSimpleSelector(notContent)
				local baseSelector = sel:gsub(":not%(.-%)", "")
				if baseSelector ~= "" then
					local baseFilter = parseSimpleSelector(baseSelector)
					return baseFilter(inst) and not notFilter(inst)
				else
					return not notFilter(inst)
				end
			end
		end

		if sel:match(":has%(") then
			local hasContent = sel:match(":has%((.-)%)")
			if hasContent then
				local baseSelector = sel:gsub(":has%(.-%)", "")
				local baseFilter = baseSelector ~= "" and parseSimpleSelector(baseSelector)
					or function()
						return true
					end

				if not baseFilter(inst) then
					return false
				end

				local hasDirectChild = hasContent:sub(1, 1) == ">"
				if hasDirectChild then
					hasContent = hasContent:sub(2):gsub("^%s+", "")
					local hasFilter = parseSimpleSelector(hasContent)
					for _, child in ipairs(inst.Children) do
						if hasFilter(child) then
							return true
						end
					end
					return false
				else
					local hasFilter = parseSimpleSelector(hasContent)
					for _, desc in ipairs(inst:GetDescendants()) do
						if hasFilter(desc) then
							return true
						end
					end
					return false
				end
			end
		end

		local filter = parseSimpleSelector(sel)
		return filter(inst)
	end

	local descendants
	if selector:sub(1, 1) == ">" then
		descendants = self:GetChildren()
		selector = selector:sub(2):gsub("^%s+", "")
	else
		if selector:sub(1, 2) == ">>" then
			selector = selector:sub(3):gsub("^%s+", "")
		end
		descendants = self:GetDescendants()
	end

	local segments = parseSelector(selector)
	local results = {}

	for _, desc in ipairs(descendants) do
		for _, seg in ipairs(segments) do
			seg = seg:gsub("^%s+", ""):gsub("%s+$", "")
			if matchesSelector(desc, seg) then
				table.insert(results, desc)
				break
			end
		end
	end

	return results
end

function Instance:SetMetadata(key, value)
	local meta = rawget(self, "_meta")
	if not meta then
		meta = {}
		rawset(self, "_meta", meta)
	end
	meta[key] = value
end

function Instance:GetMetadata(key)
	local meta = rawget(self, "_meta")
	return meta and meta[key]
end

function Instance:GetAttributes()
	local attrs = rawget(self, "_props").attributes
	local copy = {}
	for k, v in pairs(attrs) do
		copy[k] = v
	end
	return copy
end

function Instance:EnableHistory(limit)
	self._history = {}
	self._historyLimit = limit or 100
end

function Instance:Destroy()
	if rawget(self, "Destroyed") then
		return
	end

	local destroying = rawget(self, "Destroying")
	if destroying then
		destroying:Fire()
	end

	local children = {}
	for _, child in ipairs(rawget(self, "Children") or {}) do
		children[#children + 1] = child
	end

	rawset(self, "Children", {})

	for _, child in ipairs(children) do
		rawset(child, "_skipParentRemoval", true)
		child:Destroy()
	end

	local props = rawget(self, "_props")
	if props and props.Parent and not rawget(self, "_skipParentRemoval") then
		local parentChildren = rawget(props.Parent, "Children")
		if parentChildren then
			for i = #parentChildren, 1, -1 do
				if parentChildren[i] == self then
					table.remove(parentChildren, i)
					break
				end
			end
		end
	end

	rawset(self, "_props", nil)
	rawset(self, "_skipParentRemoval", nil)
	rawset(self, "Destroyed", true)
end

Instance.getChildren = Instance.GetChildren
Instance.findFirstChild = Instance.FindFirstChild
Instance.clone = Instance.Clone
Instance.destroy = Instance.Destroy

return Instance
