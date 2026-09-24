--[[
	Picks a random key from a table of {key = weight}. Shared by part-tier
	rolling and (once there's more than one candidate part per partType)
	part-candidate rolling. Pure — no Roblox APIs, Lune-testable.
]]

local WeightedPick = {}

function WeightedPick.fromWeights(weights: { [string]: number }): string?
	local total = 0
	for _, weight in weights do
		total += weight
	end
	if total <= 0 then
		return nil
	end

	local roll = math.random() * total
	local cumulative = 0
	for key, weight in weights do
		cumulative += weight
		if roll <= cumulative then
			return key
		end
	end

	-- Only reachable via float rounding at the very top of the range.
	local lastKey = nil
	for key in weights do
		lastKey = key
	end
	return lastKey
end

return WeightedPick
