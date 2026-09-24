--[[
	Rarities.luau (the template's existing rarity system) has no income
	concept — just Chance/Colour/ChatAnnouncement/VisualsPreset. Reusing its
	tier *names* was the decision (see journal/002-003), but income-per-tier
	is genuinely new data this feature needs and nothing else defines, so it
	gets its own small table here — not a parallel tier scale, just the one
	missing number, keyed by the same tier names Rarities.luau uses.
]]

return {
	Common = 1.0,
	Rare = 1.5,
	Epic = 2.25,
	Legendary = 3.5,
	Mythic = 5.0,
	["Developer God"] = 8.0,
	Secret = 12.0,
}
