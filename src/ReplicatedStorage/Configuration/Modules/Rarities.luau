local Rarities = {
	["Common"] = {
		Chance = 40.75, --40.75
		Colour = Color3.fromRGB(13, 139, 4),
		ChatAnnouncement = false,
		VisualsPreset = nil
	},
	
	["Rare"] = {
		Chance = 30, --30
		Colour = Color3.fromRGB(44, 134, 202),
		ChatAnnouncement = false,
		VisualsPreset = nil
	},
	
	["Epic"] = {
		Chance = 15, --15
		Colour = Color3.fromRGB(109, 10, 166),
		ChatAnnouncement = false,
		VisualsPreset = nil
	},

	["Legendary"] = {
		Chance = 9, --9
		Colour = Color3.fromRGB(235, 255, 12),
		ChatAnnouncement = false,
		VisualsPreset = nil
	},
	
	["Mythic"] = {
		Chance = 5, --5
		Colour = Color3.fromRGB(199, 18, 36),
		ChatAnnouncement = false,
		VisualsPreset = nil
	},

	["Developer God"] = {
		Chance = 0.2, --0.2
		Colour = Color3.fromRGB(0, 0, 0),
		ChatAnnouncement = true,
		VisualsPreset = "OceanicStroke"
	},
	
	["Secret"] = {
		Chance = 0.05, --0.05
		Colour = Color3.fromRGB(255, 255, 255),
		ChatAnnouncement = true,
		VisualsPreset = "Zebra"
	}
}

return Rarities