local DateTime = {}
DateTime.__index = DateTime

function DateTime.now()
	return DateTime.fromUnixTimestamp(os.time())
end

function DateTime.fromUnixTimestamp(timestamp)
	local self = setmetatable({}, DateTime)
	self.UnixTimestamp = timestamp
	self.UnixTimestampMillis = timestamp * 1000
	return self
end

function DateTime.fromIsoDate(isoDate)
	-- Basic ISO 8601 parser (YYYY-MM-DDTHH:MM:SSZ)
	local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z"
	local year, month, day, hour, min, sec = isoDate:match(pattern)

	if not year then
		return nil
	end

	local time = os.time({
		year = tonumber(year) or 1970,
		month = tonumber(month) or 1,
		day = tonumber(day) or 1,
		hour = tonumber(hour) or 0,
		min = tonumber(min) or 0,
		sec = tonumber(sec) or 0,
	})

	return DateTime.fromUnixTimestamp(time)
end

function DateTime:ToIsoDate()
	return os.date("!%Y-%m-%dT%H:%M:%SZ", self.UnixTimestamp)
end

function DateTime:FormatLocalTime(formatString, locale)
	return os.date(formatString, self.UnixTimestamp)
end

function DateTime:FormatUniversalTime(formatString, locale)
	return os.date("!" .. formatString, self.UnixTimestamp)
end

function DateTime:ToTable()
	return {
		type = "DateTime",
		UnixTimestamp = self.UnixTimestamp,
		UnixTimestampMillis = self.UnixTimestampMillis,
	}
end

function DateTime.FromTable(tbl)
	assert(tbl.type == "DateTime", "Table is not a DateTime")
	return DateTime.fromUnixTimestamp(tbl.UnixTimestamp)
end

return DateTime
