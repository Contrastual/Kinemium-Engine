local filesystem = require("../../modules/filesystem")
local sandboxer = require("../../modules/sandboxer")
local Instance = require("../class/Instance")
local datatypes = require("../datatypes/getDatatypes")
local zembed = require("@zembed")

local registry = {}
local listOfClasses = {}
local created = {}

sandboxer.enviroment = datatypes

local entries = {}

if zembed.IsEmbedded() then
	entries = zembed.GetScriptsThatHas([[class\list]])
else
	entries = zune.fs.entries("./src/enviroment/class/list")
end

task.spawn(function()
	local createClassesStart = os.clock()
	for _, entry in pairs(entries) do
		local createClassStart = os.clock()
		local requirePath
		if zembed.IsEmbedded() then
			local name = zune.fs.path.basename(entry)
			local full = "./list/" .. name
			requirePath = string.gsub(full, ".lua", "")
		else
			requirePath = "./list/" .. string.gsub(entry.name, ".lua", "")
		end

		local returned, s, r = require(requirePath)
		-- returned = { class = "Part", callback = function(Part) ... end }

		if not returned then
			warn(`CLASS: Failed to load {entry.name}: {s} {r}`)

			return
		end
		listOfClasses[returned.class] = returned

		log(
			string.format(
				"CLASS: Successfully created class '%s' in %.3fms from file: %s",
				returned.class,
				(os.clock() - createClassStart) * 1000,
				requirePath
			)
		)
	end
	log(string.format("CLASS: Created all classes in %.3fms", (os.clock() - createClassesStart) * 1000))
end)

function registry.createclass(data)
	listOfClasses[data.class] = data
	log("Created class for " .. data.class)
end

function registry.getClasses()
	return listOfClasses
end

function registry.ClassValid(class)
	if listOfClasses[class] then
		return true
	else
		return false
	end
	return false
end

function registry.new(class, renderer, datamodel)
	local found

	for _, looped_class in pairs(listOfClasses) do
		if looped_class.cover_up == class then
			found = looped_class
		elseif looped_class.class == class then
			found = looped_class
		end
	end

	if not found then
		return error("Class not found: " .. tostring(class))
	end
	if found.non_creatable then
		return error("Class is non-creatable: " .. tostring(class))
	end

	local instance = Instance.new(class)
	local success, result = pcall(function()
		found.callback(instance, renderer, datamodel)
	end)
	if not success then
		warn(`CLASS: Failed to create {class}: {result}`)
	end
	table.insert(created, instance)
	return instance
end

return registry
