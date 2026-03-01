local Transpiler = {}

local default = require("./superset/kilang")
local cpp = require("./superset/cpp")

local langs = {
	kilang = default,
	cpp = cpp,
}

function Transpiler.run(code, lang, gsubFuncs, dataThread)
	local env = lang.env or {}

	for _, rule in ipairs(gsubFuncs) do
		local success, result = pcall(function()
			return rule.gsub(code, env)
		end)

		if success then
			code = result
			if rule.success then
				rule.success(code)
			end
		else
			warn("Rule failed:", result)
		end
	end

	return code, dataThread
end

function Transpiler.registerLang(name, rules)
	langs[name] = rules
end

function Transpiler.runLang(code, name)
	local lang = langs[name]
	local gsubFuncs, dataThread = lang.process(code)
	if not lang then
		error("Language not registered: " .. name)
	end
	return Transpiler.run(code, lang, gsubFuncs, dataThread)
end

return Transpiler
