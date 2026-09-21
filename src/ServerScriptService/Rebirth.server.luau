local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rebirths = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rebirths"))

local RebirthEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Rebirth")

RebirthEvent.OnServerEvent:Connect(function(Player)
	local Leaderstats = Player:FindFirstChild("leaderstats")
	local Configuration = Player:FindFirstChild("Configuration")
	if not Leaderstats or not Configuration then return end

	local Money = Leaderstats:FindFirstChild("Money")
	local RebirthsValue = Leaderstats:FindFirstChild("Rebirths")
	local Base = Configuration:FindFirstChild("Base") and Configuration.Base.Value
	if not Money or not RebirthsValue or not Base then return end

	local NextRebirth = RebirthsValue.Value + 1
	
	local Configuration = Rebirths[NextRebirth]
	if not Configuration then return end

	if Money.Value < (Configuration.Requirements.Money or 0) then return end

	local RequiredList = Configuration.Requirements.Things or {}
	local RequiredCounts = {}
	for _, Name in ipairs(RequiredList) do
		RequiredCounts[Name] = (RequiredCounts[Name] or 0) + 1
	end

	local OwnedCounts = {}
	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local SlotConfiguration = Slot:FindFirstChild("Configuration")
		if SlotConfiguration and SlotConfiguration:FindFirstChild("Thing") then
			local Thing = SlotConfiguration.Thing.Value
			if Thing then
				OwnedCounts[Thing.Name] = (OwnedCounts[Thing.Name] or 0) + 1
			end
		end
	end

	for Name, Count in pairs(RequiredCounts) do
		if (OwnedCounts[Name] or 0) < Count then return end
	end

	RebirthsValue.Value = NextRebirth
	Money.Value = 0
	
	if Configuration.Unlocks.Money then
		Money.Value = Money.Value + Configuration.Unlocks.Money
	end
	
	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local SlotConfiguration = Slot:FindFirstChild("Configuration")
		if SlotConfiguration and SlotConfiguration:FindFirstChild("Thing") then
			local Thing = SlotConfiguration.Thing.Value
			if Thing then
				local CollectAttachment = Slot.Collect:FindFirstChild("CollectAttachment")
				if CollectAttachment then CollectAttachment:Destroy() end
				
				Thing:Destroy()
				
				SlotConfiguration.Thing.Value = nil
				SlotConfiguration.Occupied.Value = false
			end
		end
	end
end)