local signal = require("@Kinemium.signal")
local Instance = require("@Instance")
local encoder = require("./_encoder")
local Registry = require("@InstanceRegistry")

local serde = zune.serde
local zstd = serde.zstd

local Enum = require("@EnumMap")
local Datatypes = require("@Kinemium.datatypes.get")

local SerializationService = Instance.new("SerializationService")
SerializationService.ExplorerHidden = true

local BLACKLISTED_TYPES = {
	["function"] = true,
	["userdata"] = true,
	["FFIPointer"] = true,
	["buffer"] = true,
}

local TYPE_DESERIALIZERS = {
	EnumItem = function(v)
		local enumTypeName = if type(v) == "table" and type(v.EnumType) == "table" then v.EnumType.Name else v.EnumType
		if type(v) ~= "table" or type(enumTypeName) ~= "string" or type(v.Name) ~= "string" then
			return nil
		end
		local enumGroup = Enum[enumTypeName]
		if enumGroup == nil then
			warn("[SerializationService] Unknown EnumType '" .. enumTypeName .. "' during deserialization")
			return nil
		end
		local item = enumGroup[v.Name]
		if item == nil then
			warn(
				"[SerializationService] Unknown Enum value '"
					.. enumTypeName
					.. "."
					.. v.Name
					.. "' during deserialization"
			)
		end
		return item
	end,
}

for name, datatype in pairs(Datatypes) do
	if datatype.FromTable then
		TYPE_DESERIALIZERS[name] = function(v)
			return datatype.FromTable(v)
		end
	end
end

local function compress(tbl)
	local encoded = encoder.encode(tbl)
	return zstd.compress(encoded)
end

local function decompress(str)
	local decompressed = zstd.decompress(str)
	local ok, decoded = pcall(encoder.decode, decompressed)
	if not ok then
		print("[SerializationService] Failed to decode serialized payload: " .. tostring(decoded))
	end
	return decoded
end

local function serialize_value(value, visited)
	visited = visited or {}

	local luaType = type(value)

	if luaType == "function" or luaType == "thread" or luaType == "userdata" then
		return nil, false
	end

	local robloxType = typeof(value)

	if luaType == "number" or luaType == "string" or luaType == "boolean" or value == nil then
		return value, true
	end

	if BLACKLISTED_TYPES[robloxType] then
		return nil, false
	end

	if luaType == "table" and value.ClassName and value._props and value._props.UniqueId then
		return { __ref = value._props.UniqueId }, true
	end

	if luaType == "table" and value.__type then
		robloxType = value.__type
	end

	local datatype = Datatypes[robloxType]
	if luaType == "table" and robloxType ~= "table" and value ~= datatype and type(value.ToTable) == "function" then
		return value:ToTable(), true
	end

	if datatype and value ~= datatype and datatype.ToTable then
		return datatype.ToTable(value), true
	end

	if luaType == "table" then
		if visited[value] then
			return nil, false
		end
		visited[value] = true

		local dict = {}

		if robloxType ~= "table" then
			if not TYPE_DESERIALIZERS[robloxType] then
				return nil, false
			end
			dict.type = robloxType
		end
		for k, v in pairs(value) do
			local sv, ok = serialize_value(v, visited)
			if ok then
				dict[k] = sv
			end
		end
		return dict, true
	end

	return nil, false
end

local function serialize_object(object, obj_visited)
	obj_visited = obj_visited or {}
	if obj_visited[object] then
		return nil
	end
	obj_visited[object] = true

	local result = {
		c = object.ClassName,
		n = object.Name,
		p = {},
		ch = {},
		at = {},
		t = {},
		uid = object._props.UniqueId,
	}

	for propname, propvalue in pairs(object._props) do
		if type(propname) == "buffer" or type(propvalue) == "buffer" then
			continue
		end
		if propname == "Parent" or propname == "Children" or propname == "UniqueId" then
			continue
		end
		-- Each property gets a fresh visited set — independent of the object tree traversal
		local serialized, ok = serialize_value(propvalue, {})
		if ok then
			result.p[propname] = serialized
		end
	end

	for attrname, attrvalue in pairs(object:GetAttributes()) do
		local serialized, ok = serialize_value(attrvalue, {})
		if ok then
			result.at[attrname] = serialized
		end
	end

	for _, tag in ipairs(object:GetTags()) do
		table.insert(result.t, tag)
	end

	for _, child in ipairs(object:GetChildren()) do
		local serialized_child = serialize_object(child, obj_visited)
		if serialized_child then
			table.insert(result.ch, serialized_child)
		end
	end

	return result
end

local function deserialize_value(v)
	if type(v) ~= "table" then
		return v
	end
	if v.__ref then
		return v
	end
	if v.type then
		local deserializer = TYPE_DESERIALIZERS[v.type]
		if deserializer then
			return deserializer(v)
		else
			warn("Unknown type tag during deserialization: " .. tostring(v.type))
			return v
		end
	end
	local dict = {}
	for key, val in pairs(v) do
		dict[key] = deserialize_value(val)
	end
	return dict
end

SerializationService.InitRenderer = function(renderer, renderer_signal, datamodel)
	SerializationService:SetProperties({
		SerializeInstancesAsync = function(instances)
			local objects = {}
			for _, v in ipairs(instances) do
				table.insert(objects, serialize_object(v, {}))
			end
			return compress(objects)
		end,
		Deserialize = function(str, cb)
			local tbl = decompress(str)
			local instances = {}
			local id_map = {}

			local function create_object(objTbl)
				if type(objTbl.c) ~= "string" or objTbl.c == "" then
					warn("Class not found: " .. tostring(objTbl.c))
					return nil
				end

				if Registry.ClassValid(objTbl.c) then
					return Registry.new(objTbl.c, renderer, datamodel, true)
				end

				return Instance.new(objTbl.c)
			end

			local function deserialize_object_with_map(objTbl)
				local obj = create_object(objTbl)
				if not obj then
					return nil
				end
				obj.Name = objTbl.n

				if cb then
					cb(obj)
				end

				if objTbl.uid then
					id_map[objTbl.uid] = obj
				end

				for k, v in pairs(objTbl.p) do
					local ok, err = pcall(function()
						obj._props[k] = deserialize_value(v)
					end)
					if not ok then
						warn(("Failed to set property %q on %s: %s"):format(k, objTbl.c, err))
					end
				end

				for k, v in pairs(objTbl.at or {}) do
					local ok, err = pcall(function()
						obj:SetAttribute(k, deserialize_value(v))
					end)
					if not ok then
						warn(("Failed to set attribute %q on %s: %s"):format(k, objTbl.c, err))
					end
				end

				obj.tags = objTbl.t or {}

				for _, childTbl in ipairs(objTbl.ch) do
					local child = deserialize_object_with_map(childTbl)
					if child then
						child.Parent = obj
					end
					zune.task.wait()
				end

				return obj
			end

			for _, objTbl in ipairs(tbl) do
				local ok, result = pcall(deserialize_object_with_map, objTbl)
				if ok and result then
					table.insert(instances, result)
				else
					warn(("Failed to deserialize object of class %q: %s"):format(tostring(objTbl.c), tostring(result)))
				end
			end

			local function resolve_refs_in_table(t, visited)
				visited = visited or {}
				if visited[t] then
					return
				end
				visited[t] = true

				for k, v in pairs(t) do
					if type(v) == "table" then
						if v.__ref then
							local ref_obj = id_map[v.__ref]
							if ref_obj then
								t[k] = ref_obj
							else
								t[k] = nil
							end
						else
							resolve_refs_in_table(v, visited)
						end
					end
				end
			end

			for _, inst in ipairs(instances) do
				local all = { inst }
				local descendants = inst:GetDescendants()
				for i = 1, #descendants do
					all[#all + 1] = descendants[i]
				end

				for _, descendant in ipairs(all) do
					resolve_refs_in_table(descendant._props)
					if descendant.attributes then
						resolve_refs_in_table(descendant.attributes)
					end
				end
			end

			return instances
		end,

		userdata = {
			Encode = function(value)
				local serialized, ok = serialize_value(value)
				if ok then
					return serialized
				end
				return nil
			end,
			Decode = function(value)
				return deserialize_value(value)
			end,
		},
	})
end

return SerializationService
