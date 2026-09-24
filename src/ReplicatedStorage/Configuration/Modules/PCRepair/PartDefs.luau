--[[
	Catalog of specific parts. Each entry is a named, concrete part (not a
	category) — e.g. "RTX4080" is one entry, distinct from "GTX1050", even
	though both are GPUs. `partType` is what ties a part to a ZoneDef slot;
	`tierWeights` rolls which condition/rarity this particular instance is
	(reuses the tier names in Rarities.luau, not a separate scale).

	`model` is an intentionally empty placeholder — no real assets exist yet
	(see journal/002 and journal/003). Fill these in once assets land; the
	container logic never reads this field, so leaving it blank doesn't
	block anything.
]]

return {
	-- Mainboard & Compute
	Ryzen5 = { partType = "CPU", model = "", tierWeights = { Common = 55, Rare = 30, Epic = 12, Legendary = 3 } },
	Ryzen9 = { partType = "CPU", model = "", tierWeights = { Common = 20, Rare = 35, Epic = 30, Legendary = 15 } },
	StandardATX = { partType = "Motherboard", model = "", tierWeights = { Common = 60, Rare = 30, Epic = 10 } },
	DDR4_8GB = { partType = "RAM", model = "", tierWeights = { Common = 65, Rare = 25, Epic = 10 } },
	NVMe512 = { partType = "M2Drive", model = "", tierWeights = { Common = 50, Rare = 35, Epic = 15 } },

	-- Expansion / Graphics
	GTX1050 = { partType = "GPU", model = "", tierWeights = { Common = 60, Rare = 30, Epic = 10 } },
	RTX4080 = { partType = "GPU", model = "", tierWeights = { Common = 10, Rare = 30, Epic = 40, Legendary = 20 } },
	SoundCard = { partType = "ExpansionCard", model = "", tierWeights = { Common = 70, Rare = 25, Epic = 5 } },
	WifiCard = { partType = "ExpansionCard", model = "", tierWeights = { Common = 70, Rare = 25, Epic = 5 } },

	-- Cooling
	StockCooler = { partType = "CPUCooler", model = "", tierWeights = { Common = 75, Rare = 20, Epic = 5 } },
	AIO240 = { partType = "CPUCooler", model = "", tierWeights = { Common = 20, Rare = 35, Epic = 30, Legendary = 15 } },
	CaseFan120 = { partType = "CaseFan", model = "", tierWeights = { Common = 80, Rare = 20 } },

	-- Storage
	HDD1TB = { partType = "SATADrive", model = "", tierWeights = { Common = 70, Rare = 25, Epic = 5 } },
	SSD500 = { partType = "SATADrive", model = "", tierWeights = { Common = 40, Rare = 35, Epic = 20, Legendary = 5 } },

	-- Power
	PSU500W = { partType = "PSU", model = "", tierWeights = { Common = 65, Rare = 25, Epic = 10 } },
	PSU750W = { partType = "PSU", model = "", tierWeights = { Common = 30, Rare = 35, Epic = 25, Legendary = 10 } },
}
