local Enum = require("@EnumMap")

local TweenInfo = {}
TweenInfo.__index = TweenInfo

function TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
	local self = setmetatable({}, TweenInfo)

	self.Time = time or 1.0
	self.EasingStyle = easingStyle or Enum.EasingStyle.Quad
	self.EasingDirection = easingDirection or Enum.EasingDirection.Out
	self.RepeatCount = repeatCount or 0
	self.Reverses = reverses or false
	self.DelayTime = delayTime or 0

	return self
end

return TweenInfo
