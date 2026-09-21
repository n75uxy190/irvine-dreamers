local Tools = {
	["Bat"] = {
		Description = "A clunky bat to bash thieves!",
		Icon = "rbxassetid://14434989783",

		Price = 0,
		Rebirth = 0,
		Starter = true,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://140443230343778",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 30,
		ReturnStolenThings = true,
		Hitbox = 7,
		Cooldown = 0.4
	},

	["Slap"] = {
		Description = "An average hand to slap thieves and send them flying!",
		Icon = "rbxassetid://132663704910045",

		Price = 500,
		Rebirth = 0,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 30,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["SpeedCoil"] = {
		Description = "Zoom around the map with additional speed!",
		Icon = "rbxassetid://452423769",

		Price = 750,
		Rebirth = 1,
		Starter = false,

		Category = "Mobility",

		EquippedSound = "rbxassetid://99173388",

		Speed = 20, -- Keep above 8
		AdditiveSpeed = true
	},

	["Trap"] = {
		Description = "Place traps that freeze thieves for 10 seconds!",
		Icon = "rbxassetid://125763614165048",

		Price = 1000,
		Rebirth = 1,
		Starter = false,

		Category = "Combat",

		TrapSound = "rbxassetid://17613919743",

		TrapTime = 7, --  10 seconds of being trapped
		TrapMaxPlace = 5, -- trap can be placed 5 times max until reset
		TrapMaxUses = 1, -- trap can only be used 1 time
		TrapLifetime = 420,
		TrapDelay = 1   -- how long till place another trap
	},

	["IronSlap"] = {
		Description = "Heavy iron slap that knocks players flying!",
		Icon = "rbxassetid://128725389712818",

		Price = 2500,
		Rebirth = 1,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 33,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["GravityCoil"] = {
		Description = "Reduced gravity coil lets you jump extra high!",
		Icon = "rbxassetid://16619617",

		Price = 5000,
		Rebirth = 1,
		Starter = false,

		Category = "Mobility",

		EquippedSound = "rbxassetid://16619553",

		Gravity = 25,
		GravityPercentRemaining = 0.25,
		GravityCounterPercent = 0.75,

		AdditiveSpeed = false
	},

	["BeeLauncher"] = {
		Description = "Release bees to attack your opponent and invert their controls!",
		Icon = "rbxassetid://122175485465612",

		Price = 10000,
		Rebirth = 2,
		Starter = false,

		Category = "Combat",	

		SoundId = "rbxassetid://119375791",

		Range = 25,
		Cooldown = 15
	},

	["GoldSlap"] = {
		Description = "Powerful golden slap that knocks enemies farther back!",
		Icon = "rbxassetid://134064693276233",

		Price = 15000,
		Rebirth = 2,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 35,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["CoilCombo"] = {
		Description = "Speed and jump coil combined for a double boost!",
		Icon = "rbxassetid://96032087851653",

		Price = 20000,
		Rebirth = 3,
		Starter = false,

		Category = "Mobility",

		EquippedSound = "rbxassetid://99173388",
		EquippedSound2 = "rbxassetid://16619553",

		Speed = 20,
		AdditiveSpeed = true,

		GravityPercentRemaining = 0.25,
		JumpMultiplier = 1
	},

	["DiamondSlap"] = {
		Description = "Charge up a diamond slap to knock others away!",
		Icon = "rbxassetid://113544150736256",

		Price = 50000,
		Rebirth = 3,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 40,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["EmeraldSlap"] = {
		Description = "Gem-infused slap that sends enemies flying with extra force!",
		Icon = "rbxassetid://83131212096419",

		Price = 150000,
		Rebirth = 4,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 43,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["InvisibilityCloak"] = {
		Description = "Cloak yourself to vanish and sprint at super speed!",
		Icon = "rbxassetid://122921009404001",

		Price = 500000,
		Rebirth = 5,
		Starter = false,

		Category = "Mobility",

		SoundIdStart = "rbxassetid://129425637", 
		SoundIdEnd = "rbxassetid://129425664"
	},

	["RubySlap"] = {
		Description = "Ultimate ruby-powered slap sends enemies flying far!",
		Icon = "rbxassetid://137113835509466",

		Price = 1000000,
		Rebirth = 6,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 45,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["MedusaHead"] = {
		Description = "Turn enemies into stone and recover stolen developers!",
		Icon = "rbxassetid://106161489392628",

		Price = 5000000,
		Rebirth = 7,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://82201758321584",
		ActivationSound = "rbxassetid://89371632",

		Range = 15,
		ReturnStolenThings = true,
		Cooldown = 25,
	},

	["FlameSlap"] = {
		Description = "Burn your enemies while sending them flying!",
		Icon = "rbxassetid://135046988244005",

		Price = 10000000,
		Rebirth = 8,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 50,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},
	
	["SapphireSlap"] = {
		Description = "A cool, crystalline slap infused with oceanic energy — freezes foes in their tracks before sending them flying!",
		Icon = "rbxassetid://72856463935768",

		Price = 25000000,
		Rebirth = 9,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 60,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["BodySwapPotion"] = {
		Description = "Switch souls. Trade bodies and confuse your foes!",
		Icon = "rbxassetid://116293799003992",

		Price = 50000000,
		Rebirth = 10,
		Starter = false,

		Category = "Mobility",

		SoundId = "rbxassetid://136486618791770",

		Range = 40,
		ReturnStolenThings = true,
		Cooldown = 30
	},

	["AmethystSlap"] = {
		Description = "Harness the mystical energy of amethyst to deliver a slap that shatters both pride and balance!",
		Icon = "rbxassetid://108474238182128",

		Price = 75000000,
		Rebirth = 11,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 70,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["CelestialSlap"] = {
		Description = "Channel the power of the stars themselves — one swing and your enemies are launched into the cosmos!",
		Icon = "rbxassetid://75685098378460",

		Price = 100000000,
		Rebirth = 12,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 80,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	},

	["ObsidianSlap"] = {
		Description = "Forged in volcanic fury, this dark slap erupts with power, leaving only scorched air and stunned foes behind!",
		Icon = "rbxassetid://115221109169300",

		Price = 500000000,
		Rebirth = 13,
		Starter = false,

		Category = "Combat",

		ActivationAnimation = "rbxassetid://99236704955736",
		ActivationSound = "rbxassetid://9113305311",
		HitSound = "rbxassetid://146163534",

		Power = 90,
		ReturnStolenThings = true,
		Hitbox = 9,
		Cooldown = 0.3
	}
}

return Tools
