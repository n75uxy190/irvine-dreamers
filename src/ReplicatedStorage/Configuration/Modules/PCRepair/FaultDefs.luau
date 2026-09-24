--[[
	Faults are data, not subclasses — `appliesTo` is what filters a fault to
	compatible part types at roll time (a CPU can't roll DriedPaste because
	it isn't in that list). Every partType referenced by ZoneDefs has at
	least one applicable fault here, so issue-rolling always has a valid
	target regardless of which slots got filled.
]]

return {
	BentPins = {
		appliesTo = { "CPU", "Motherboard" },
		minigame = "PinStraighten",
		baseTime = 12,
	},
	DriedPaste = {
		appliesTo = { "CPUCooler" },
		minigame = "PasteApply",
		baseTime = 8,
	},
	DustyFan = {
		appliesTo = { "CaseFan", "GPU" },
		minigame = "Dusting",
		baseTime = 6,
	},
	LooseCable = {
		appliesTo = { "PSU", "SATADrive", "GPU" },
		minigame = "CableReseat",
		baseTime = 5,
	},
	CorrodedContacts = {
		appliesTo = { "RAM", "M2Drive", "ExpansionCard" },
		minigame = "ContactScrub",
		baseTime = 7,
	},
}
