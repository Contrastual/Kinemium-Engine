local PredictionBuffer = {}
PredictionBuffer.__index = PredictionBuffer

function PredictionBuffer.new(maxEntries)
	return setmetatable({
		maxEntries = maxEntries or 128,
		order = {},
		entries = {},
	}, PredictionBuffer)
end

function PredictionBuffer:Push(sequence, payload)
	if self.entries[sequence] ~= nil then
		self.entries[sequence] = payload
		return
	end

	self.entries[sequence] = payload
	table.insert(self.order, sequence)

	while #self.order > self.maxEntries do
		local oldest = table.remove(self.order, 1)
		self.entries[oldest] = nil
	end
end

function PredictionBuffer:Acknowledge(sequence)
	while #self.order > 0 and self.order[1] <= sequence do
		local oldest = table.remove(self.order, 1)
		self.entries[oldest] = nil
	end
end

function PredictionBuffer:GetLatest()
	local latestSequence = self.order[#self.order]
	if latestSequence == nil then
		return nil
	end

	return self.entries[latestSequence]
end

return PredictionBuffer
