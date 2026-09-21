local TraitsStorage = game.ReplicatedStorage:WaitForChild("TraitsStorage")
local MusicControlEvent = game.ReplicatedStorage.Remotes.Events:WaitForChild("MusicControlEvent")
local Bindables = game.ReplicatedStorage:WaitForChild("Bindables")
local DayNightToggle = Bindables:WaitForChild("DayNightTraitToggle")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")

local currentSpiderSky
local currentSpiderModel
local currentDevModel
local currentDevSky

local ActiveTraits = {}

local Traits = {
	["Studio"] = {
		Chance = 35,
		Multiplier = 2,
		Time = 180,
		Icon = "rbxassetid://105431805113489",

		Start = function()
			local endTime = os.time() + 180
			ActiveTraits["Studio"] = endTime

			Events.EventHandler:FireAllClients("Start", {
				Name = "Studio",
				Icon = "rbxassetid://105431805113489",
				Time = 180
			})
		end,

		Stop = function()
			ActiveTraits["Studio"] = nil

			Events.EventHandler:FireAllClients("Stop", {
				Name = "Studio"
			})
		end
	},

	["Developer"] = {
		Chance = 20,
		Multiplier = 5,
		Time = 300,
		Icon = "rbxassetid://121354745445254",

		Start = function()
			local endTime = os.time() + 300
			ActiveTraits["Developer"] = endTime

			currentDevModel = TraitsStorage.DeveloperTrait.DeveloperTraitModel:Clone()
			currentDevModel.Parent = workspace

			Events.EventHandler:FireAllClients("Start", {
				Name = "Developer",
				Icon = "rbxassetid://121354745445254",
				Time = 300
			})

			if Lighting:FindFirstChild("OriginalSky") then
				Lighting.OriginalSky:Destroy()
			end
			currentDevSky = TraitsStorage.DeveloperTrait.DeveloperSky:Clone()
			currentDevSky.Parent = Lighting

			DayNightToggle:Fire(true, 2)

			local TraitSoundEvent = game.ReplicatedStorage.Remotes.Events.TraitSoundEvent
			MusicControlEvent:FireAllClients("pause")
			TraitSoundEvent:FireAllClients("DeveloperTrait", true)
		end,

		Stop = function()
			ActiveTraits["Developer"] = nil

			if currentDevModel then
				currentDevModel:Destroy()
				currentDevModel = nil
			end

			if currentDevSky then
				currentDevSky:Destroy()
				currentDevSky = nil
			end

			Events.EventHandler:FireAllClients("Stop", {
				Name = "Developer"
			})

			local originalSky = TraitsStorage.OriginalSky:Clone()
			originalSky.Parent = Lighting

			DayNightToggle:Fire(false)

			local TraitSoundEvent = game.ReplicatedStorage.Remotes.Events.TraitSoundEvent
			TraitSoundEvent:FireAllClients("DeveloperTrait", false)
			MusicControlEvent:FireAllClients("resume")
		end
	},

	["Spider"] = {
		Chance = 25,
		Multiplier = 4,
		Time = 300,
		Icon = "rbxassetid://107988202297644",

		Start = function()
			local endTime = os.time() + 300
			ActiveTraits["Spider"] = endTime

			currentSpiderModel = TraitsStorage.SpiderTrait.SpiderTraitModel:Clone()
			currentSpiderModel.Parent = workspace

			Events.EventHandler:FireAllClients("Start", {
				Name = "Spider",
				Icon = "rbxassetid://107988202297644",
				Time = 300
			})

			if Lighting:FindFirstChild("OriginalSky") then
				Lighting.OriginalSky:Destroy()
			end
			currentSpiderSky = TraitsStorage.SpiderTrait.SpiderSky:Clone()
			currentSpiderSky.Parent = Lighting

			DayNightToggle:Fire(true, 2)

			local TraitSoundEvent = game.ReplicatedStorage.Remotes.Events.TraitSoundEvent
			MusicControlEvent:FireAllClients("pause")
			TraitSoundEvent:FireAllClients("SpiderTrait", true)
		end,

		Stop = function()
			ActiveTraits["Spider"] = nil

			if currentSpiderModel then
				currentSpiderModel:Destroy()
				currentSpiderModel = nil
			end

			if currentSpiderSky then
				currentSpiderSky:Destroy()
				currentSpiderSky = nil
			end

			Events.EventHandler:FireAllClients("Stop", {
				Name = "Spider"
			})

			local originalSky = TraitsStorage.OriginalSky:Clone()
			originalSky.Parent = Lighting

			DayNightToggle:Fire(false)

			local TraitSoundEvent = game.ReplicatedStorage.Remotes.Events.TraitSoundEvent
			TraitSoundEvent:FireAllClients("SpiderTrait", false)
			MusicControlEvent:FireAllClients("resume")
		end
	}
}

Traits.ActiveTraits = ActiveTraits

return Traits
