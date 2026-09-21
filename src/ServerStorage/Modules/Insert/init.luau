local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Traits = require(ServerStorage.Configuration.Modules:WaitForChild("Traits"))

local Numbers = require(ReplicatedStorage.Modules:WaitForChild("Numbers"))
local Mutations = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Mutations"))
local Rarities = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rarities"))

local Insert = {}

function Insert.Thing(Thing, Configuration, AppliedTraits, Mutation)
	local ThingAttachment = Instance.new("Attachment")
	ThingAttachment.Name = "ThingAttachment"
	ThingAttachment.Parent = Thing.PrimaryPart

	if not ThingAttachment.Parent then return end

	local Rarity = Configuration.Rarity

	local ThingGui = script.ThingGui:Clone()
	ThingGui.Thing.Text = Thing.Name
	ThingGui.Rarity.Text = Rarity
	ThingGui.Rarity.TextColor3 = Rarities[Rarity].Colour

	AppliedTraits = AppliedTraits or {}
	
	if Rarity == "Developer God" then
		local ezVisuals = require(ReplicatedStorage.Modules.EasyVisuals)
		local Rarity = ThingGui.Rarity
		local gradient = ezVisuals.new(Rarity, "OceanicStroke", 0.20)
		gradient.Parent = ThingGui.Rarity
	end

	if Rarity == "Secret" then
		local ezVisuals = require(ReplicatedStorage.Modules.EasyVisuals)
		local Rarity = ThingGui.Rarity
		local gradient = ezVisuals.new(Rarity, "Zebra", 0.35)
		gradient.Parent = ThingGui.Rarity
	end

	if Mutation == "Rainbow" then
		local ezVisuals = require(ReplicatedStorage.Modules.EasyVisuals)
		local MutationTextLabel = ThingGui.Mutation
		local gradient = ezVisuals.new(MutationTextLabel, "Rainbow", 0.35)
		gradient.Parent = ThingGui.Mutation
	end

	local TraitMultiplier = 0
	for _, TraitName in ipairs(AppliedTraits) do
		local TraitConfiguration = Traits[TraitName]
		if TraitConfiguration then
			TraitMultiplier += TraitConfiguration.Multiplier or 0
			ThingGui.Traits.Visible = true

			local Trait = ThingGui.Traits.Trait:Clone()
			Trait.Name = TraitName
			Trait.Image = TraitConfiguration.Icon or ""
			Trait.Visible = true
			Trait.Parent = ThingGui.Traits
		end
	end

	local MutationMultiplier = Mutations[Mutation] and Mutations[Mutation].Multiplier or 1
	local DefaultMultiplier = (Mutations.Default and Mutations.Default.Multiplier) or 1

	local SubtractValue = 0

	if TraitMultiplier ~= 0 then
		SubtractValue = DefaultMultiplier
	end

	local TotalMultiplier = MutationMultiplier + (TraitMultiplier - SubtractValue)

	ThingGui.MoneyPerSecond.Text = string.format("$%s/s", Numbers.Format(math.round(Configuration.MoneyPerSecond * TotalMultiplier)))
	ThingGui.Price.Text = string.format("$%s", Numbers.Format(Configuration.Price))

	if Mutation ~= "Default" then
		ThingGui.Mutation.Text = Mutation
		ThingGui.Mutation.Visible = true
		ThingGui.Mutation.TextColor3 = Mutations[Mutation].Colour
	end

	ThingGui.Enabled = true
	ThingGui.Parent = ThingAttachment

	local OffsetY = 1 + Thing:GetExtentsSize().Y / 2 + ThingGui.Size.Y.Scale / 2
	ThingAttachment.Position = Vector3.new(0, OffsetY, 0)

	return ThingAttachment, ThingGui
end

function Insert.Collect(Collect, Configuration)
	local CollectAttachment = Instance.new("Attachment")
	CollectAttachment.Name = "CollectAttachment"
	CollectAttachment.Parent = Collect

	if not CollectAttachment.Parent then return end

	local CollectGui = script.CollectGui:Clone()
	CollectGui.Enabled = true
	CollectGui.Parent = CollectAttachment

	local OffsetY = 1 + CollectGui.Size.Y.Scale / 2 + Collect.Size.Y / 2
	CollectAttachment.Position = Vector3.new(0, OffsetY, 0)

	return CollectAttachment, CollectGui
end

function Insert.Friends(Friends)
	local FriendsAttachment = Instance.new("Attachment")
	FriendsAttachment.Name = "FriendsAttachment"
	FriendsAttachment.Parent = Friends

	if not FriendsAttachment.Parent then return end

	local FriendsGui = script.FriendsGui:Clone()
	FriendsGui.Enabled = true
	FriendsGui.Parent = FriendsAttachment

	local FriendsSurfaceGui = script.FriendsSurfaceGui:Clone()
	FriendsSurfaceGui.Enabled = true
	FriendsSurfaceGui.Parent = Friends

	local OffsetY = 1 + FriendsGui.Size.Y.Scale / 2 + Friends.Size.Y / 2
	FriendsAttachment.Position = Vector3.new(0, OffsetY, 0)

	return FriendsAttachment, FriendsGui, FriendsSurfaceGui
end

function Insert.Lock(Lock)
	local LockAttachment = Instance.new("Attachment")
	LockAttachment.Name = "LockAttachment"
	LockAttachment.Parent = Lock

	if not LockAttachment.Parent then return end

	local LockGui = script.LockGui:Clone()
	LockGui.Enabled = true
	LockGui.Parent = LockAttachment

	local OffsetY = 1 + LockGui.Size.Y.Scale / 2 + Lock.Size.Y / 2
	LockAttachment.Position = Vector3.new(0, OffsetY, 0)

	return LockAttachment, LockGui
end

function Insert.Multiplier(CollectZone)
	local MultiplierAttachment = Instance.new("Attachment")
	MultiplierAttachment.Name = "MultiplierAttachment"
	MultiplierAttachment.Parent = CollectZone

	if not MultiplierAttachment.Parent then
		return
	end

	local MultiplierGui = script.MultiplierGui:Clone()
	MultiplierGui.Enabled = true
	MultiplierGui.Parent = MultiplierAttachment

	local OffsetY = 1 + MultiplierGui.Size.Y.Scale / 2 + CollectZone.Size.Y / 2
	MultiplierAttachment.Position = Vector3.new(0, OffsetY, 0)

	return MultiplierAttachment, MultiplierGui
end

function Insert.Owner(Owner)
	local OwnerAttachment = Instance.new("Attachment")
	OwnerAttachment.Name = "OwnerAttachment"
	OwnerAttachment.Parent = Owner

	if not OwnerAttachment.Parent then return end

	local OwnerGui = script.OwnerGui:Clone()
	OwnerGui.Parent = OwnerAttachment

	local OwnerSurfaceGui = script.OwnerSurfaceGui:Clone()
	OwnerSurfaceGui.Enabled = true
	OwnerSurfaceGui.Parent = Owner

	local OffsetY = 1 + OwnerGui.Size.Y.Scale / 2 + Owner.Size.Y / 2
	OwnerAttachment.Position = Vector3.new(0, OffsetY, 0)

	return OwnerGui, OwnerSurfaceGui
end

function Insert.Event(Event, Name)
	local Machine = Event and Event:FindFirstChild("Machine")
	local EventPart = Machine and Machine:FindFirstChild("Event")

	local MachineGui

	if EventPart then
		MachineGui = script.MachineGui:Clone()
		MachineGui.Event.Text = string.format("%s Event", Name)
		MachineGui.Time.Text = Numbers.Time(0)
		MachineGui.Progress.Text = string.format("%s/%s", Numbers.Time(0), Numbers.Time(0))

		local Colour = Mutations[Name] and Mutations[Name].Colour
		if Colour then
			MachineGui.Event.TextColor3 = Colour
		end

		MachineGui.Enabled = true
		MachineGui.Parent = EventPart
	end

	local Wheel = Event and Event:FindFirstChild("Wheel")
	local EventPart = Wheel and Wheel:FindFirstChild("Event")

	local WheelGui

	if EventPart then
		WheelGui = script.WheelGui:Clone()
		WheelGui.Event.Text = string.format("%s Wheel", Name)

		local Colour = Mutations[Name] and Mutations[Name].Colour
		if Colour then
			WheelGui.Event.TextColor3 = Colour
		end

		WheelGui.Enabled = true
		WheelGui.Parent = EventPart
	end

	return MachineGui, WheelGui
end

function Insert.CollectZone(CollectZone)
	local CollectZoneGui = script.CollectZoneGui:Clone()
	CollectZoneGui.Enabled = true
	CollectZoneGui.Parent = CollectZone

	return CollectZoneGui
end

function Insert.Segment(Segment, Configuration)
	Segment.Color = Configuration.Colour or Color3.fromRGB(163, 162, 165)

	local SegmentGui = script.SegmentGui:Clone()

	local SegmentFrame = SegmentGui.SegmentFrame
	SegmentFrame.Icon.Image = Configuration.Icon or ""
	SegmentFrame.Prize.Text = Configuration.Name or "Nothing"
	SegmentFrame.Chance.Text = string.format("%d%%", Configuration.Chance or 0)

	SegmentGui.Enabled = true
	SegmentGui.Parent = Segment

	return SegmentGui
end

function Insert.ProximityPrompt(Parent)
	local ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.ActionText = ""
	ProximityPrompt.Enabled = false
	ProximityPrompt.RequiresLineOfSight = false
	ProximityPrompt.Parent = Parent

	return ProximityPrompt
end

return Insert