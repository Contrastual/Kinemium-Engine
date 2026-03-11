local Transpiler = {}

local default = require("./superset/kilang")
local cpp = require("./superset/cpp")

local langs = {
	kilang = default,
	cpp = cpp,
	typescript = require("./superset/typescript"),
}

local function resolveLang(lang, code)
	if type(lang) ~= "table" then
		error("Language definition must be a table")
	end

	if type(lang.process) == "function" then
		local gsubFuncs, dataThread = lang.process(code)
		return gsubFuncs or {}, dataThread or {}
	end

	if type(lang[1]) == "table" then
		return lang, {}
	end

	error("Invalid language definition: expected process() or rule array")
end

function Transpiler.run(code, lang, gsubFuncs, dataThread)
	local env = lang.env or {}

	for _, rule in ipairs(gsubFuncs) do
		local success, nextCode, nextDataThread = pcall(function()
			return rule.gsub(code, env, dataThread)
		end)

		if success then
			if type(nextCode) == "string" then
				code = nextCode
			end
			if type(nextDataThread) == "table" then
				dataThread = nextDataThread
			end
			if type(rule.success) == "function" then
				local ok, err = pcall(rule.success, code, dataThread)
				if not ok then
					warn("Rule success handler failed:", err)
				end
			end
		else
			local ruleName = type(rule) == "table" and rule.name or "unknown"
			warn(("Rule failed (%s): %s"):format(tostring(ruleName), tostring(nextCode)))
		end
	end

	return code, dataThread
end

function Transpiler.registerLang(name, rules)
	langs[name] = rules
end

function Transpiler.runLang(code, name)
	local lang = langs[name]
	if not lang then
		error("Language not registered: " .. name)
	end
	local gsubFuncs, dataThread = resolveLang(lang, code)
	return Transpiler.run(code, lang, gsubFuncs, dataThread)
end

return Transpiler
