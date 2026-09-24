--[[
	The five physical zones of a PC case. Adding a sixth zone, or changing
	what a zone holds, is a config-only change — never touch PCFactory to
	do it. `count` on a slot rolls a variable number of that part per PC
	(e.g. 2-4 RAM sticks); slots with no `count` always roll exactly one.
]]

return {
	Cooling = {
		region = "RearTopVentPanel",
		slots = {
			{ partType = "CPUCooler" },
			{ partType = "CaseFan", count = { min = 2, max = 3 } },
		},
	},
	MainboardCompute = {
		region = "MainTrayUpper",
		slots = {
			{ partType = "Motherboard" },
			{ partType = "CPU" },
			{ partType = "RAM", count = { min = 2, max = 4 } },
			{ partType = "M2Drive" },
		},
	},
	ExpansionGraphics = {
		region = "MainTrayLower",
		slots = {
			{ partType = "GPU" },
			{ partType = "ExpansionCard", count = { min = 0, max = 2 } },
		},
	},
	Storage = {
		region = "MidLeftCutout",
		slots = {
			{ partType = "SATADrive", count = { min = 1, max = 2 } },
		},
	},
	Power = {
		region = "BottomShroud",
		slots = {
			{ partType = "PSU" },
		},
	},
}
