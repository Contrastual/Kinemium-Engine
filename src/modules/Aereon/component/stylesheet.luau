local StyleSheet = {}

local classes = {}

function StyleSheet.registerClass(name, properties)
	classes[name] = properties
end

function StyleSheet.getClass(name)
	return classes[name]
end

function StyleSheet.apply(data)
	if not data or not data.class then
		return data
	end

	local classNames = {}
	if type(data.class) == "string" then
		for name in data.class:gmatch("%S+") do
			table.insert(classNames, name)
		end
	elseif type(data.class) == "table" then
		classNames = data.class
	end

	local merged = {}

	for _, className in ipairs(classNames) do
		local classProps = classes[className]
		if classProps then
			for k, v in pairs(classProps) do
				merged[k] = v
			end
		end
	end

	for k, v in pairs(data) do
		if k ~= "class" then
			merged[k] = v
		end
	end

	return merged
end

return StyleSheet
