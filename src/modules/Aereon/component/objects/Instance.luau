local Instance = {}
Instance.__index = Instance
setmetatable(Instance, {__index = require(script.Parent.Object)})

function Instance.new(className)
	local self = setmetatable(require(script.Parent.Object).new(), Instance)
	self.ClassName = className or "Instance"
	self.Properties = {}
	return self
end
return Instance
