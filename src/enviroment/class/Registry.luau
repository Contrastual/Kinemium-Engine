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
	local createdClassesLog = {}

	for _, entry in pairs(entries) do
		local createClassStart = os.clock()
		local requirePath
		if zembed.IsEmbedded() then
			local name = zune.fs.path.basename(entry)
			local full = "./list/" .. name
			requirePath = string.gsub(full, ".luau", "")
		else
			requirePath = "./list/" .. string.gsub(entry.name, ".luau", "")
		end

		local returned, s, r = require(requirePath)
		-- returned = { class = "Part", callback = function(Part) ... end }

		if not returned then
			warn(`CLASS: Failed to load {entry.name}: {s} {r}`)

			return
		end
		listOfClasses[returned.class] = returned

		table.insert(createdClassesLog, string.format("\t%s (%.3fms): %s", returned.class, (os.clock() - createClassStart) * 1000, requirePath))
	end
	log(
		string.format(
			"CLASS: Successfully created the following classes in %.3fms:\n",
			(os.clock() - createClassesStart) * 1000
		) .. table.concat(createdClassesLog, "\n")
	)
end)

function registry.createclass(data)
	listOfClasses[data.class] = data
	log("Created class for " .. data.class)
end

function registry.getClasses()
	return listOfClasses
end

function registry.ClassValid(class)
	return listOfClasses[class] ~= nil
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
	local success, result = pcall(found.callback, instance, renderer, datamodel)
	if not success then
		warn(`CLASS: Failed to create {class}: {result}`)
	end
	table.insert(created, instance) -- potential memory leak
	return instance
end

return registry
