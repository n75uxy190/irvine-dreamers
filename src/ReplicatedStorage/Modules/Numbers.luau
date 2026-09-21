local Numbers = {}

local Suffixes = {
	"", "K", "M", "B", "T", "Qa", "Qi"
}

function Numbers.Format(Number)
	if Number < 1000 then
		return tostring(Number)
	end

	local Tier = math.floor(math.log10(Number) / 3)
	if Tier > #Suffixes - 1 then
		Tier = #Suffixes - 1
	end

	local ScaledNumber = Number / (1000 ^ Tier)
	local Formatted = string.format("%.3f", ScaledNumber)
		:gsub("%.0+$", "")
		:gsub("(%.%d-)0+$", "%1")
	
	return Formatted .. Suffixes[Tier + 1]
end

function Numbers.Time(Seconds)
	local Years = math.floor(Seconds / 31536000)
	local Days = math.floor((Seconds % 31536000) / 86400)
	local Hours = math.floor((Seconds % 86400) / 3600)
	local Minutes = math.floor((Seconds % 3600) / 60)
	local Secs = math.floor(Seconds % 60)

	local Parts = {}

	if Years > 0 then
		table.insert(Parts, tostring(Years))
	end
	if Days > 0 or Years > 0 then
		table.insert(Parts, tostring(Days))
	end

	if Years > 0 or Days > 0 then
		table.insert(Parts, string.format("%02d", Hours))
		table.insert(Parts, string.format("%02d", Minutes))
		table.insert(Parts, string.format("%02d", Secs))
		return table.concat(Parts, ":")
	else
		if Hours > 0 then
			return string.format("%d:%02d:%02d", Hours, Minutes, Secs)
		else
			if Minutes == 0 then
				if Secs == 0 then
					return "0"
				else
					return tostring(Secs)
				end
			else
				return string.format("%d:%02d", Minutes, Secs)
			end
		end
	end
end


return Numbers