local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")

if RunService:IsClient() then
	ScriptContext.RunClientScripts()
else
	ScriptContext.RunServerScripts()
end
