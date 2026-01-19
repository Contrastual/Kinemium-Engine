local Enum = {}
local EnumItem = {}
EnumItem.__index = EnumItem

function EnumItem:IsA(value)
	return self.EnumType == value
end

function EnumItem:__tostring()
	return string.format("Enum.%s.%s", self.EnumType.Name, self.Name)
end

-- Optional: allow comparison by value
function EnumItem:__eq(other)
	if getmetatable(other) == EnumItem then
		return self.EnumType == other.EnumType and self.Value == other.Value
	end
	return false
end

local function createEnum(api)
	Enum._numberIndex = {}

	for enumName, items in pairs(api) do
		local enumType = {}
		enumType.Name = enumName
		enumType.__index = enumType
		enumType.type = "EnumType"

		-- Store all EnumItems in order for GetEnumItems()
		local itemList = {}

		for itemName, itemValue in pairs(items) do
			local item = setmetatable({}, EnumItem)
			item.Name = itemName
			item.Value = itemValue
			item.EnumType = enumType
			item.type = "EnumItem"

			if type(itemValue) == "number" then
				Enum._numberIndex[itemName] = item
			end

			enumType[itemName] = item
			table.insert(itemList, item)
		end

		function enumType:GetEnumItems()
			-- Returns a copy of the item list
			local copy = {}
			for i, v in ipairs(itemList) do
				copy[i] = v
			end
			return copy
		end

		Enum[enumName] = enumType
	end

	return Enum
end

Enum.new = createEnum

return Enum
