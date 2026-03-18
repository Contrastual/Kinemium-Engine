local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local encoder = require("./_encoder")
local Registry = require("@Kinemium.registry")

local serde = zune.serde
local zstd = serde.zstd

local Vector3 = require("@datatypes/Vector3")
local CFrame = require("@datatypes/CFrame")
local Enum = require("@EnumMap")
local Color3 = require("@datatypes/Color3")
local Color4 = require("@datatypes/Color4")
local UDim = require("@datatypes/UDim")
local UDim2 = require("@datatypes/UDim2")
local Ray = require("@datatypes/Ray")
local NumberSequence = require("@datatypes/NumberSequence")
local NumberSequenceKeypoint = require("@datatypes/NumberSequenceKeypoint")
local ColorSequence = require("@datatypes/ColorSequence")
local ColorSequenceKeypoint = require("@datatypes/ColorSequenceKeypoint")
local BrickColorMap = require("@BrickColorMap")
local CustomPhysicalProperties = require("@datatypes/CustomPhysicalProperties")
local BoundingBox = require("@datatypes/BoundingBox")

local SerializationService = Instance.new("SerializationService")
SerializationService.ExplorerHidden = true

local BLACKLISTED_TYPES = {
	["function"] = true,
	["userdata"] = true,
	["FFIPointer"] = true,
	["buffer"] = true,
}

local TYPE_DESERIALIZERS = {
	Vector3 = function(v)
		return Vector3.FromTable(v)
	end,
	CFrame = function(v)
		return CFrame.FromTable(v)
	end,
	Color3 = function(v)
		return Color3.FromTable(v)
	end,
	Color4 = function(v)
		return Color4.FromTable(v)
	end,
	UDim = function(v)
		return UDim.FromTable(v)
	end,
	UDim2 = function(v)
		return UDim2.FromTable(v)
	end,
	Ray = function(v)
		return Ray.FromTable(v)
	end,
	NumberSequence = function(v)
		return NumberSequence.FromTable(v)
	end,
	NumberSequenceKeypoint = function(v)
		return NumberSequenceKeypoint.FromTable(v)
	end,
	ColorSequence = function(v)
		return ColorSequence.FromTable(v)
	end,
	ColorSequenceKeypoint = function(v)
		return ColorSequenceKeypoint.FromTable(v)
	end,
	BrickColorMap = function(v)
		return BrickColorMap.FromTable(v)
	end,
	CustomPhysicalProperties = function(v)
		return CustomPhysicalProperties.FromTable(v)
	end,
	BoundingBox = function(v)
		return BoundingBox.FromTable(v)
	end,
	EnumItem = function(v)
		print("Got enum item ", v)
		return Enum[v.EnumType][v.Name]
	end,
}

local function compress(tbl)
	local encoded = encoder.encode(tbl)
	return zstd.compress(encoded)
end

local function decompress(str)
	local decompressed = zstd.decompress(str)
	return encoder.decode(decompressed)
end

local function serialize_value(value)
	local t = typeof(value)
	if BLACKLISTED_TYPES[t] then
		return nil, false
	end
	if type(value) == "table" then
		if value.ToTable and type(value.ToTable) == "function" then
			return value:ToTable(), true
		end
		return nil, false
	end
	return value, true
end

local function serialize_object(object)
	local result = {
		c = object.ClassName, -- class name
		n = object.Name, -- instance name
		p = {}, -- properties
		ch = {}, -- children (array)
		at = {}, -- attributes
		t = {}, -- tags
	}

	for propname, propvalue in pairs(object._props) do
		if type(propname) == "buffer" or type(propvalue) == "buffer" then
			continue
		end
		local serialized, ok = serialize_value(propvalue)
		if ok then
			result.p[propname] = serialized
		end
	end

	for attrname, attrvalue in pairs(object:GetAttributes()) do
		local serialized, ok = serialize_value(attrvalue)
		if ok then
			result.at[attrname] = serialized
		end
	end

	for _, tag in ipairs(object:GetTags()) do
		table.insert(result.t, tag)
	end

	for _, child in ipairs(object:GetChildren()) do
		table.insert(result.ch, serialize_object(child))
	end

	return result
end

local function deserialize_value(v)
	if type(v) ~= "table" then
		return v
	end
	if v.type then
		local deserializer = TYPE_DESERIALIZERS[v.type]
		if deserializer then
			return deserializer(v)
		else
			warn("Unknown type tag during deserialization: " .. tostring(v.type))
		end
	end
	return v
end

SerializationService.InitRenderer = function(renderer, renderer_signal, datamodel)
	local function deserialize_object(tbl)
		if not Registry.ClassValid(tbl.c) then
			warn("Class not found: " .. tostring(tbl.c))
			return nil
		end

		local obj = Registry.new(tbl.c, renderer, datamodel)
		obj.Name = tbl.n

		for k, v in pairs(tbl.p) do
			local ok, err = pcall(function()
				obj._props[k] = deserialize_value(v)
			end)
			if not ok then
				warn(("Failed to set property %q on %s: %s"):format(k, tbl.c, err))
			end
		end

		for k, v in pairs(tbl.at or {}) do
			local ok, err = pcall(function()
				obj:SetAttribute(k, deserialize_value(v))
			end)
			if not ok then
				warn(("Failed to set attribute %q on %s: %s"):format(k, tbl.c, err))
			end
		end

		obj.tags = tbl.t or {}

		for _, childTbl in ipairs(tbl.ch) do
			local child = deserialize_object(childTbl)
			if child then
				child.Parent = obj
			end
		end

		return obj
	end

	SerializationService:SetProperties({
		SerializeInstancesAsync = function(instances)
			local objects = {}
			for _, v in ipairs(instances) do
				table.insert(objects, serialize_object(v))
			end
			return compress(objects)
		end,

		Deserialize = function(str)
			local tbl = decompress(str)
			local instances = {}
			for _, objTbl in ipairs(tbl) do
				local ok, result = pcall(deserialize_object, objTbl)
				if ok and result then
					table.insert(instances, result)
				else
					warn(("Failed to deserialize object of class %q: %s"):format(tostring(objTbl.c), tostring(result)))
				end
			end
			return instances
		end,

		userdata = {
			Encode = function(value)
				local serialized, ok = serialize_value(value)
				return ok and serialized or nil
			end,
			Decode = function(value)
				return deserialize_value(value)
			end,
		},
	})
end

return SerializationService
