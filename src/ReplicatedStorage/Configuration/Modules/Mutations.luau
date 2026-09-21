local Mutations = {
	["Default"] = {
		Event = false,
		
		Chance = 84, --84
		Multiplier = 1,
		IndexMultiplier = 0.5,
		
		Colour = Color3.fromRGB(255, 255, 255),
		VisualsPreset = nil
	},
	
	["Gold"] = {
		Event = false,
		
		Chance = 10, --10
		Multiplier = 1.25,
		IndexMultiplier = 0.5,
		
		Colour = Color3.fromRGB(255, 215, 0),
		VisualsPreset = nil
	},
	
	["Diamond"] = {
		Event = false,

		Chance = 5, --5
		Multiplier = 1.5,
		IndexMultiplier = 0.5,

		Colour = Color3.fromRGB(17, 223, 255),
		VisualsPreset = nil
	},
	
	["Rainbow"] = {
		Event = false,

		Chance = 1, --1
		Multiplier = 10,
		IndexMultiplier = 0.5,

		Colour = Color3.fromRGB(255, 255, 255),
		VisualsPreset = "Rainbow"
	}
}

return Mutations