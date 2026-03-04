local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local encoder = require("./encoder")
local Registry = require("@InstanceRegistry")

local serde = zune.serde
local zstd = serde.zstd

local Vector3 = require("@Vector3")
local CFrame = require("@CFrame")
local Color3 = require("@Color3")
local Color4 = require("@Color4")
local UDim = require("@UDim")
local UDim2 = require("@UDim2")
local Ray = require("@Ray")
local NumberSequence = require("@NumberSequence")
local NumberSequenceKeypoint = require("@NumberSequenceKeypoint")
local ColorSequence = require("@ColorSequence")
local ColorSequenceKeypoint = require("@ColorSequenceKeypoint")
local BrickColorMap = require("@BrickColorMap")
local CustomPhysicalProperties = require("@CustomPhysicalProperties")
local BoundingBox = require("@BoundingBox")

local SerializationService = Instance.new("SerializationService")
SerializationService.ExplorerHidden = true

local blacklisted = {
	"function",
	"userdata",
	"FFIPointer",
	"buffer",
}

local function compress(tbl)
	local encoded = encoder.encode(tbl)
	return zstd.compress(encoded)
end

local function decompress(str)
	local compressed = zstd.decompress(str)
	return encoder.decode(compressed)
end

local function serialize_value(value)
	if type(value) == "table" then
		if value["ToTable"] then
			print(value)
			return value:ToTable()
		end
	elseif table.find(blacklisted, typeof(value)) then
		return nil
	else
		return value
	end
end

local function serialize_object(object)
	local result = {
		c = object.ClassName,
		n = object.Name,
		p = {},
		ch = {},
		at = {},
		t = object.tags,
	}

	for propname, propvalue in pairs(object._props) do
		if type(propvalue) == "buffer" then
			continue
		end
		if type(propname) == "buffer" then
			continue
		end
		if type(propvalue) == "table" then
			continue
		end
		result.p[propname] = serialize_value(propvalue)
	end

	for propname, propvalue in pairs(object:GetAttributes()) do
		if type(propvalue) == "table" then
			continue
		end
		result.at[propname] = serialize_value(propvalue)
	end

	for _, tag in pairs(object:GetTags()) do
		table.insert(result.t, tag)
	end

	for _, child in pairs(object:GetChildren()) do
		result.ch[child.Name] = serialize_object(child)
	end

	return result
end

local function fromtble(v)
	if not v then
		return
	end
	if v.type then
		if v.type == "Vector3" then
			return Vector3.FromTable(v)
		elseif v.type == "CFrame" then
			return CFrame.FromTable(v)
		elseif v.type == "Color3" then
			return Color3.FromTable(v)
		elseif v.type == "Color4" then
			return Color4.FromTable(v)
		elseif v.type == "UDim" then
			return UDim.FromTable(v)
		elseif v.type == "UDim2" then
			return UDim2.FromTable(v)
		elseif v.type == "Ray" then
			return Ray.FromTable(v)
		elseif v.type == "NumberSequence" then
			return NumberSequence.FromTable(v)
		elseif v.type == "NumberSequenceKeypoint" then
			return NumberSequenceKeypoint.FromTable(v)
		elseif v.type == "ColorSequence" then
			return ColorSequence.FromTable(v)
		elseif v.type == "ColorSequenceKeypoint" then
			return ColorSequenceKeypoint.FromTable(v)
		elseif v.type == "BrickColorMap" then
			return BrickColorMap.FromTable(v)
		elseif v.type == "CustomPhysicalProperties" then
			return CustomPhysicalProperties.FromTable(v)
		elseif v.type == "BoundingBox" then
			return BoundingBox.FromTable(v)
		elseif v.type == "EnumItem" then
			return Enum[v.EnumType][v.Name]
		end
	end
end

SerializationService.InitRenderer = function(renderer, renderer_signal, datamodel)
	local function deserialize_object(tbl)
		if not Registry.ClassValid(tbl.c) then
			warn(`Class {tbl.c} not found`)
			return
		end
		local obj = Registry.new(tbl.c, renderer, datamodel)
		obj.Name = tbl.n

		for k, v in pairs(tbl.p) do
			if type(v) == "table" then
				obj._props[k] = fromtble(v)
			else
				obj._props[k] = v
			end
		end

		for _, childTbl in pairs(tbl.ch) do
			local child = deserialize_object(childTbl)
			child.Parent = obj
		end

		-- table of strings, just apply
		obj.tags = tbl.t or {}

		for k, v in pairs(tbl.at or {}) do
			-- decode value also
			obj:SetAttribute(k, fromtble(v))
		end

		return obj
	end

	SerializationService:SetProperties({
		SerializeInstancesAsync = function(m)
			local objects = {}

			for _, v in pairs(m) do
				local serialized = serialize_object(v)
				table.insert(objects, serialized)
			end

			local compressed = compress(objects)
			return compressed
		end,
		Deserialize = function(str)
			local tbl = decompress(str)
			local instances = {}
			for _, objTbl in pairs(tbl) do
				local success, deserialized = pcall(function()
					return deserialize_object(objTbl)
				end)
				if success then
					table.insert(instances, deserialized)
				else
					warn(`Failed to deserialize object {objTbl.class}: {deserialized}`)
				end
			end
			return instances
		end,

		userdata = {
			Encode = function(value)
				return serialize_value(value)
			end,
			Decode = function(value)
				return fromtble(value)
			end,
		},
	})
end

return SerializationService
