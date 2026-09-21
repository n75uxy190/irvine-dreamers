local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Insert = require(ServerStorage.Modules:WaitForChild("Insert"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Index = require(ServerStorage.Modules:WaitForChild("Index"))
local Traits = require(ServerStorage.Configuration.Modules:WaitForChild("Traits"))

local Numbers = require(ReplicatedStorage.Modules:WaitForChild("Numbers"))
local Things = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Things"))
local Events = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Events"))
local Mutations = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Mutations"))
local Rarities = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rarities"))
local Rebirths = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rebirths"))
local ServerLuck = require(ReplicatedStorage.Configuration.Modules:WaitForChild("ServerLuck"))
local UpdateMoneyPerSecondModule = require(ReplicatedStorage.Modules:WaitForChild("UpdateMoneyPerSecond"))
local AssetIds = require(ReplicatedStorage.Configuration.Modules:WaitForChild("AssetIds"))
local SoundsModule = require(ReplicatedStorage.Configuration.Modules.Sounds)

local ReturnStolenThingEvent = ServerStorage.Bindables.Events:WaitForChild("ReturnStolenThing")

local NotificationEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Notification")
local ChatAnnouncementEvent = ReplicatedStorage.Remotes.Events:WaitForChild("ChatAnnouncement")
local SpinWheelEvent = ReplicatedStorage.Remotes.Events:WaitForChild("SpinWheel")
local ServerLuckEvent = ReplicatedStorage.Remotes.Events:WaitForChild("ServerLuck")

local MarketplaceService = game:GetService("MarketplaceService")
local GamepassID_X2 = AssetIds.GamePasses.x2Money


local Waypoints = workspace:WaitForChild("Waypoints")

local StolenThings = {}
local SpawnThings = {}
local SpawnedThings = {}

local LeavingPlayers = {}

pcall(function()
	PhysicsService:RegisterCollisionGroup("Things")
end)

PhysicsService:CollisionGroupSetCollidable("Things", "Things", false)
PhysicsService:CollisionGroupSetCollidable("Things", "Default", false)

local Module = {}

Module.Luck = 1
Module.LuckTime = 0
Module.Traits = {}
Module.EventsThings = {}
Module.EventsSpins = {}
Module.EventsTimes = {}
Module.EventTasks = {}

function Module.Random(Rarity)
	if Rarity and not Rarities[Rarity] then
		Rarity = nil
	end

	local UsedRarities = {}
	for _, Configuration in pairs(Things.Things) do
		local RarityValue = Configuration.Rarity
		if Rarities[RarityValue] then
			UsedRarities[RarityValue] = true
		end
	end

	local RandomRarity
	if Rarity then
		RandomRarity = Rarity
	else
		local BestRarity
		local BestChance = math.huge

		for Index = 1, Module.Luck do
			local TotalChance = 0
			for RarityKey, Data in pairs(Rarities) do
				if UsedRarities[RarityKey] then
					TotalChance = TotalChance + Data.Chance
				end
			end

			local Roll = math.random() * TotalChance
			local Sum = 0
			local RolledRarity

			for RarityKey, Data in pairs(Rarities) do
				if UsedRarities[RarityKey] then
					Sum = Sum + Data.Chance
					if Roll <= Sum then
						RolledRarity = RarityKey
						break
					end
				end
			end

			if RolledRarity then
				local Chance = Rarities[RolledRarity].Chance
				if Chance < BestChance then
					BestChance = Chance
					BestRarity = RolledRarity
				end
			end
		end

		RandomRarity = BestRarity
	end

	if not RandomRarity then return end

	local AppliedTraits = {}
	for Trait, Active in pairs(Module.Traits) do
		if Active then
			local TraitConfiguration = Traits[Trait]
			if TraitConfiguration and TraitConfiguration.Chance then
				local Roll = math.random(0, 100)
				if Roll <= TraitConfiguration.Chance then
					table.insert(AppliedTraits, Trait)
				end
			end
		end
	end

	local CurrentEvent
	for EventName, TimeLeft in pairs(Module.EventsTimes) do
		if TimeLeft and TimeLeft > 0 and Events[EventName] and Mutations[EventName] then
			CurrentEvent = EventName
			break
		end
	end

	local Mutation
	if CurrentEvent then
		if math.random(1, 100) <= Mutations[CurrentEvent].Chance then
			Mutation = CurrentEvent
		end
	end

	local RandomMutation
	if Mutation then
		RandomMutation = Mutation
	else
		local TotalMutationChance = 0
		for MutationKey, Configuration in pairs(Mutations) do
			if Configuration.Event then continue end

			TotalMutationChance = TotalMutationChance + Configuration.Chance
		end

		local MutationRoll = math.random() * TotalMutationChance
		local MutationSum = 0

		for MutationKey, Configuration in pairs(Mutations) do
			if Configuration.Event then continue end

			MutationSum = MutationSum + Configuration.Chance
			if MutationRoll <= MutationSum then
				RandomMutation = MutationKey
				break
			end
		end
	end

	if not RandomMutation then return end

	local MatchingNames = {}
	for Name, Configuration in pairs(Things.Things) do
		if Configuration.Rarity == RandomRarity then
			table.insert(MatchingNames, Name)
		end
	end

	if #MatchingNames == 0 then return end

	local RandomName = MatchingNames[math.random(1, #MatchingNames)]

	return RandomName, AppliedTraits, RandomMutation
end

function Module.Create(Name, AppliedTraits, Mutation, Spawn, Parent, Stolen)
	if not Stolen then
		Stolen = false
	end

	local Configuration = Things.Things[Name]
	if not Configuration then return end

	local Rarity = Configuration.Rarity
	local Price = Configuration.Price or 0
	local MoneyPerSecond = Configuration.MoneyPerSecond or 0

	local ThingsFolder = ServerStorage:FindFirstChild("Things")
	local MutationFolder = ThingsFolder and ThingsFolder:FindFirstChild(Mutation)
	local RarityFolder = MutationFolder and MutationFolder:FindFirstChild(Rarity)
	local Thing = RarityFolder and RarityFolder:FindFirstChild(Name)

	if not Thing then
		warn(string.format("Unable to find %s %s.", Mutation, Name))
		return
	end

	if not Thing.PrimaryPart then
		warn(string.format("PrimaryPart is not set for %s %s.", Mutation, Name))
		return
	end

	Thing = Thing:Clone()

	local ThingAttachment, ThingGui = Insert.Thing(Thing, Configuration, AppliedTraits, Mutation)

	if Stolen then
		for _, Descendant in ipairs(ThingGui:GetDescendants()) do
			if not Descendant:IsA("GuiObject") then continue end

			if Descendant.Name == "Stolen"then
				Descendant.Visible = true
			else
				Descendant.Visible = false
			end
		end
	end

	local PrimaryPart = Thing.PrimaryPart

	local ProximityPrompt
	if not Stolen then
		ProximityPrompt = Insert.ProximityPrompt(PrimaryPart)
		ProximityPrompt.ObjectText = Name
	end

	local Humanoid = Thing:FindFirstChildWhichIsA("Humanoid")
	local SpawnCFrame = Spawn.CFrame
	local Orientation = Spawn.Orientation

	local OffsetY
	if Stolen then
		local ExtentsSize = Thing:GetExtentsSize()

		OffsetY = ExtentsSize.Y + 1
	elseif Humanoid then
		local HipHeight = Humanoid.HipHeight or 0

		OffsetY = HipHeight + PrimaryPart.Size.Y / 2 - Spawn.Size.Y / 2
	else
		local _, Size = Thing:GetBoundingBox()
		local BaseY = Thing:GetBoundingBox().Position.Y - (Size.Y / 2)
		local OffsetFromPrimaryToBottom = PrimaryPart.Position.Y - BaseY

		OffsetY = OffsetFromPrimaryToBottom - Spawn.Size.Y / 2
	end

	local FinalCFrame = CFrame.new(
		SpawnCFrame.Position + Vector3.new(0, OffsetY, 0)
	) * CFrame.Angles(
		math.rad(Orientation.X),
		math.rad(Orientation.Y),
		math.rad(Orientation.Z)
	)

	for _, Descendant in ipairs(Thing:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Descendant.CollisionGroup = "Things"
		end
	end

	Thing:SetPrimaryPartCFrame(FinalCFrame)
	Thing.Parent = Parent

	local Animator
	if Humanoid then
		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		Animator = Humanoid:FindFirstChildOfClass("Animator")

		if not Animator then
			Animator = Instance.new("Animator", Humanoid)
		end
	else
		local AnimationController = Thing:FindFirstChildOfClass("AnimationController")

		if not AnimationController then
			AnimationController = Instance.new("AnimationController", Thing)
		end

		Animator = Instance.new("Animator", AnimationController)
	end

	local ThingConfiguration = Instance.new("Configuration")
	ThingConfiguration.Parent = Thing

	local MutationValue = Instance.new("StringValue")
	MutationValue.Name = "Mutation"
	MutationValue.Value = Mutation
	MutationValue.Parent = ThingConfiguration

	local TraitsValue = Instance.new("StringValue")
	TraitsValue.Name = "Traits"
	TraitsValue.Value = AppliedTraits and #AppliedTraits > 0 and table.concat(AppliedTraits, ",") or ""
	TraitsValue.Parent = ThingConfiguration

	local AnimationsFolder = Instance.new("Folder")
	AnimationsFolder.Name = "Animations"
	AnimationsFolder.Parent = ThingConfiguration

	local IdleTrack
	if Configuration.IdleAnimation and Configuration.IdleAnimation ~= "" then
		local IdleAnimation = Instance.new("Animation")
		IdleAnimation.Name = "IdleAnimation"
		IdleAnimation.AnimationId = Configuration.IdleAnimation
		IdleAnimation.Parent = AnimationsFolder

		IdleTrack = Animator:LoadAnimation(IdleAnimation)
	end

	local WalkTrack
	if Configuration.WalkAnimation and Configuration.WalkAnimation ~= "" then
		local WalkAnimation = Instance.new("Animation")
		WalkAnimation.Name = "WalkAnimation"
		WalkAnimation.AnimationId = Configuration.WalkAnimation
		WalkAnimation.Parent = AnimationsFolder

		WalkTrack = Animator:LoadAnimation(WalkAnimation)
	end

	local Sound
	if Configuration.Sound and Configuration.Sound ~= "" then
		Sound = Instance.new("Sound")
		Sound.Name = "ActivationSound"
		Sound.SoundId = Configuration.Sound
		Sound.Parent = ThingConfiguration
	end

	return Thing, Configuration, Rarity, Price, MoneyPerSecond, ThingAttachment, ThingGui, ProximityPrompt, OffsetY, IdleTrack, WalkTrack, Sound
end

function Module.Add(Player, Base, Slot, Name, AppliedTraits, Mutation, Time)
	if not Player then return end
	if not Base then return end
	if not Slot then return end

	if Slot.Configuration.Thing.Value then return end

	if not Name then return end
	if not Mutation then return end

	local Thing, Configuration, Rarity, Price, MoneyPerSecond, ThingAttachment, ThingGui, ProximityPrompt, OffsetY, IdleTrack, WalkTrack, Sound =  Module.Create(Name, AppliedTraits, Mutation, Slot.Spawn, Slot)

	if not Thing then return end

	local HasX2 = false
	pcall(function()
		HasX2 = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GamepassID_X2)
	end)

	Slot.Configuration.Occupied.Value = true
	Slot.Configuration.Thing.Value = Thing

	UpdateMoneyPerSecondModule.Update(Player)

	Index.PlayerThing(Player, Name, Mutation)

	local CollectAttachment, CollectGui = Insert.Collect(Slot.Collect)

	ProximityPrompt.HoldDuration = 1

	SetProperties.AllClients(ProximityPrompt, {
		ActionText = "Steal"
	})

	SetProperties.Client(Player, ProximityPrompt, {
		KeyboardKeyCode = Enum.KeyCode.F,
		ActionText = string.format("Sell $%s", Numbers.Format(Configuration.Price / 2)),
	})

	if IdleTrack then IdleTrack:Play() end

	local PlayerLeaderstats = Player:WaitForChild("leaderstats")
	local PlayerMoneyValue = PlayerLeaderstats:WaitForChild("Money")

	local PlayerConfiguration = Player:WaitForChild("Configuration")
	local MultiplierValue = PlayerConfiguration:WaitForChild("Multiplier")

	ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
		if LeavingPlayers[Player.UserId] then return end
		if ThingGui.Stolen.Visible then return end

		if not TriggeringPlayer then return end
		if not TriggeringPlayer:IsDescendantOf(game.Players) then return end

		local TriggeringCharacter = TriggeringPlayer.Character
		if not TriggeringCharacter or not TriggeringCharacter:IsDescendantOf(workspace) then return end

		local TriggeringHumanoid = TriggeringCharacter:FindFirstChildOfClass("Humanoid")
		if not TriggeringHumanoid then return end

		local TriggeringHumanoidRootPart = TriggeringCharacter.PrimaryPart
		if not TriggeringHumanoidRootPart then return end

		local SlotRebirthValue = Slot.Configuration.Rebirth.Value

		local ClosestFloorHitbox

		if SlotRebirthValue == 0 then
			local Floor1Folder = Base.Floors:FindFirstChild("Floor1")
			if not Floor1Folder then return end
			ClosestFloorHitbox = Floor1Folder:FindFirstChild("Hitbox")
		else
			local ClosestRebirth = math.huge
			for RebirthLevel, Data in pairs(Rebirths) do
				local FloorNumber = Data.Unlocks.Floor
				if FloorNumber and RebirthLevel >= SlotRebirthValue and RebirthLevel < ClosestRebirth then
					local FloorFolder = Base.Floors:FindFirstChild("Floor"..FloorNumber)
					local Hitbox = FloorFolder and FloorFolder:FindFirstChild("Hitbox")
					if Hitbox then
						ClosestRebirth = RebirthLevel
						ClosestFloorHitbox = Hitbox
					end
				end
			end
		end

		if not ClosestFloorHitbox then return end

		local Size = ClosestFloorHitbox.Size / 2
		local Center = ClosestFloorHitbox.Position
		local Position = TriggeringHumanoidRootPart.Position

		local Inside = (Position.X >= Center.X - Size.X and Position.X <= Center.X + Size.X) and
			(Position.Y >= Center.Y - Size.Y and Position.Y <= Center.Y + Size.Y) and
			(Position.Z >= Center.Z - Size.Z and Position.Z <= Center.Z + Size.Z)

		if not Inside then return end

		if TriggeringPlayer == Player then
			local Earned = Configuration.Price / 2
			if HasX2 then
				Earned *= 2
			end
			PlayerMoneyValue.Value += Earned

			CollectAttachment:Destroy()
			Thing:Destroy()

			Slot.Configuration.Thing.Value = nil
			Slot.Configuration.Occupied.Value = false

			UpdateMoneyPerSecondModule.Update(Player)
		else
			local TriggeringPlayerLeaderstats = TriggeringPlayer:FindFirstChild("leaderstats")
			if not TriggeringPlayerLeaderstats then return end
			
			if _G.ForceResetPlayer then
				_G.ForceResetPlayer(TriggeringPlayer, true)
			end


			local Rebirths = TriggeringPlayerLeaderstats:FindFirstChild("Rebirths")
			if not Rebirths then return end

			local TriggeringPlayerConfiguration = TriggeringPlayer:FindFirstChild("Configuration")
			if not TriggeringPlayerConfiguration then return end

			local Base = TriggeringPlayerConfiguration:FindFirstChild("Base") and TriggeringPlayerConfiguration.Base.Value
			if not Base or not Base:IsDescendantOf(workspace) then return end

			local CollectZone = Base:FindFirstChild("CollectZone")
			if not CollectZone then return end

			local Slots = Base:FindFirstChild("Slots")
			if not Slots then return end

			local Slots = Slots:GetChildren()
			table.sort(Slots, function(A, B)
				local AIndex = tonumber(string.match(A.Name, "%d+")) or 0
				local BIndex = tonumber(string.match(B.Name, "%d+")) or 0
				return AIndex < BIndex
			end)

			local UnoccupiedSlot = nil
			for _, Slot in ipairs(Slots) do
				if Slot.Configuration.Occupied.Value == false and Slot.Configuration.Rebirth.Value <= Rebirths.Value then
					Slot.Configuration.Occupied.Value = true
					UnoccupiedSlot = Slot
					break
				end
			end

			if StolenThings[TriggeringPlayer] then
				NotificationEvent:FireClient(TriggeringPlayer, "Already stealing!", false)
				return
			elseif not UnoccupiedSlot then
				NotificationEvent:FireClient(TriggeringPlayer, "Not enough room!", false)
				return
			else
				NotificationEvent:FireClient(Player, string.format("Someone is stealing your %s!", Name), false)
				StolenThings[TriggeringPlayer] = true
				ReplicatedStorage.Remotes.Events.SomeoneStealingSound:FireClient(Player, SoundsModule.StealSound, 3)
			end

			SetProperties.AllClients(ProximityPrompt, {Enabled = false})

			if Sound then
				local PlayStealSound = ReplicatedStorage.Remotes.Events:WaitForChild("PlayStealSound")
				PlayStealSound:FireClient(TriggeringPlayer, Sound.SoundId:gsub("rbxassetid://", ""), 5) -- 5 is the client-side volume
			end

			for _, Descendant in ipairs(ThingGui:GetDescendants()) do
				if not Descendant:IsA("GuiObject") then continue end

				if Descendant.Name == "Stolen"then
					Descendant.Visible = true
				else
					Descendant.Visible = false
				end
			end

			local Animator = TriggeringHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", TriggeringHumanoid)

			local TriggeringCharacterConfiguration = TriggeringCharacter:FindFirstChildOfClass("Configuration")

			if not TriggeringCharacterConfiguration then
				TriggeringCharacterConfiguration = Instance.new("Configuration")
				TriggeringCharacterConfiguration.Parent = TriggeringCharacter
			end

			local AnimationsFolder = TriggeringCharacterConfiguration:FindFirstChild("Animations")

			if not AnimationsFolder then
				AnimationsFolder = Instance.new("Folder")
				AnimationsFolder.Name = "Animations"
				AnimationsFolder.Parent = TriggeringCharacterConfiguration
			end

			local CarryTrack
			if Configuration.CarryAnimation and Configuration.CarryAnimation ~= "" then
				local CarryAnimation = AnimationsFolder:FindFirstChild("CarryAnimation")

				if not CarryAnimation then
					CarryAnimation = Instance.new("Animation")
					CarryAnimation.Name = "CarryAnimation"
					CarryAnimation.Parent = AnimationsFolder
				end

				CarryAnimation.AnimationId = Configuration.CarryAnimation

				CarryTrack = Animator:LoadAnimation(CarryAnimation)
			end

			if CarryTrack then CarryTrack:Play() end

			local StolenThing, _, _, _, _, _, _, _, _, IdleTrack, _, _ =  Module.Create(Name, AppliedTraits, Mutation, TriggeringHumanoidRootPart, TriggeringHumanoidRootPart, true)

			if not StolenThing then return end

			if IdleTrack then IdleTrack:Play() end

			-- position stolen thing a bit lower relative to the HRP (adjust lowerOffset as needed)
			local lowerOffset = -5.1 -- studs lower than HRP center (increase to move it further down)
			local forwardOffset = 0  -- studs forward; set >0 to move in front

			local hrpCFrame = TriggeringHumanoidRootPart.CFrame
			local desiredCFrame = hrpCFrame * CFrame.new(0, -lowerOffset, -forwardOffset)

			-- place stolen thing at desired spot before welding
			StolenThing:SetPrimaryPartCFrame(desiredCFrame)

			-- simple WeldConstraint to keep stolen thing attached; we set the parts' positions first
			local PrimaryWeld = Instance.new("WeldConstraint")
			PrimaryWeld.Part0 = StolenThing.PrimaryPart
			PrimaryWeld.Part1 = TriggeringHumanoidRootPart
			PrimaryWeld.Parent = StolenThing.PrimaryPart

			for _, Descendant in ipairs(StolenThing:GetDescendants()) do
				if Descendant:IsA("BasePart") then
					if not IdleTrack and Descendant ~= StolenThing.PrimaryPart then
						local SecondaryWeld = Instance.new("WeldConstraint")
						SecondaryWeld.Part0 = Descendant
						SecondaryWeld.Part1 = StolenThing.PrimaryPart
						SecondaryWeld.Parent = Descendant
					end

					Descendant.Anchored = false
				elseif Descendant:IsA("Motor6D") then
					if not IdleTrack then
						Descendant.Enabled = false
					end
				end
			end


			local StealSpeed = tonumber(Things.StealSpeed)
			if TriggeringHumanoid and TriggeringCharacter:FindFirstChildOfClass("Humanoid") and StealSpeed then
				TriggeringHumanoid.WalkSpeed = StealSpeed
			end

			local Backpack = TriggeringPlayer:FindFirstChild("Backpack")
			if Backpack then
				TriggeringHumanoid:UnequipTools()

				local ToolsFolder = TriggeringPlayer:FindFirstChild("Tools")
				if not ToolsFolder then
					ToolsFolder = Instance.new("Folder")
					ToolsFolder.Name = "Tools"
					ToolsFolder.Parent = TriggeringPlayer
				end

				for _, Tool in pairs(Backpack:GetChildren()) do
					if Tool:IsA("Tool") then
						Tool.Parent = ToolsFolder
					end
				end
			end

			local PlayerRemovingConnection
			local CharacterRemovingConnection
			local ReturnStolenThingConnection
			local RebirthConnection
			local CollectZoneConnection

			local EventCollectZoneConnections = {}

			local function DisconnectConnections()
				if PlayerRemovingConnection then
					PlayerRemovingConnection:Disconnect()
					PlayerRemovingConnection = nil
				end

				if CharacterRemovingConnection then
					CharacterRemovingConnection:Disconnect()
					CharacterRemovingConnection = nil
				end

				if ReturnStolenThingConnection then
					ReturnStolenThingConnection:Disconnect()
					ReturnStolenThingConnection = nil
				end

				if RebirthConnection then
					RebirthConnection:Disconnect()
					RebirthConnection = nil
				end

				if CollectZoneConnection then
					CollectZoneConnection:Disconnect()
					CollectZoneConnection = nil
				end

				for _, Connection in ipairs(EventCollectZoneConnections) do
					if Connection.Disconnect then
						Connection:Disconnect()
					end
				end

				EventCollectZoneConnections = nil
			end

			local function DestroyStolenThing()
				if not StolenThing then return end

				PrimaryWeld:Destroy()
				StolenThing:Destroy()

				if CarryTrack then CarryTrack:Stop() end
			end

			local function ReturnStolenThing()
				DestroyStolenThing()

				UnoccupiedSlot.Configuration.Occupied.Value = false

				if not Thing then return end

				local AppliedTraitsSet = {}
				for _, Trait in ipairs(AppliedTraits) do
					AppliedTraitsSet[Trait] = true
				end

				for _, Descendant in ipairs(ThingGui:GetDescendants()) do
					if not Descendant:IsA("GuiObject") then continue end

					if Descendant.Name == "Stolen" then
						Descendant.Visible = false
					elseif Descendant.Name == "Mutation" then
						Descendant.Visible = Mutation ~= "Default"
					elseif AppliedTraitsSet[Descendant.Name] ~= nil then
						Descendant.Visible = true
					elseif Descendant.Parent == "Traits" then
						Descendant.Visible = false
					else
						Descendant.Visible = true
					end
				end

				SetProperties.AllClients(ProximityPrompt, {Enabled = true})

				UpdateMoneyPerSecondModule.Update(Player)
			end

			local function DisableStealing()
				if TriggeringHumanoid and TriggeringCharacter:FindFirstChildOfClass("Humanoid") then
					TriggeringHumanoid.WalkSpeed = 30
				end

				local Backpack = TriggeringPlayer:FindFirstChild("Backpack")
				if not Backpack then return end

				local Tools = TriggeringPlayer:FindFirstChild("Tools")
				if not Tools then return end

				for _, Tool in pairs(Tools:GetChildren()) do
					if Tool:IsA("Tool") then
						Tool.Parent = Backpack
					end
				end

				if #Tools:GetChildren() == 0 then
					Tools:Destroy()
				end
			end

			ReturnStolenThingConnection = ReturnStolenThingEvent.Event:Connect(function(TouchingPlayer)
				if TouchingPlayer ~= TriggeringPlayer then return end

				DisableStealing()
				ReturnStolenThing()

				StolenThings[TriggeringPlayer] = nil
				DisconnectConnections()
			end)

			PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(LeavingPlayer)
				local PlayerExists = Player and Players:FindFirstChild(Player.Name)
				local TriggeringPlayerExists = TriggeringPlayer and Players:FindFirstChild(TriggeringPlayer.Name)

				if LeavingPlayer == TriggeringPlayer then
					if PlayerExists then
						ReturnStolenThing()
					else
						DestroyStolenThing()
					end
				elseif LeavingPlayer == Player then
					if TriggeringPlayerExists then
						DisableStealing()
					else
						DestroyStolenThing()

						if PlayerExists then
							UpdateMoneyPerSecondModule.Update(Player)
						end
					end
				end

				if not PlayerExists and not TriggeringPlayerExists then
					StolenThings[TriggeringPlayer] = nil
					DisconnectConnections()
				end
			end)

			CharacterRemovingConnection = TriggeringPlayer.CharacterRemoving:Connect(function()
				if not Players:FindFirstChild(TriggeringPlayer.Name) then
					return
				end

				local PlayerExists = Player and Players:FindFirstChild(Player.Name)
				local TriggeringPlayerExists = TriggeringPlayer and Players:FindFirstChild(TriggeringPlayer.Name)

				if TriggeringPlayerExists then
					DisableStealing()

					if PlayerExists then
						ReturnStolenThing()
					else
						DestroyStolenThing()
						UpdateMoneyPerSecondModule.Update(Player)
					end
				end

				StolenThings[TriggeringPlayer] = nil
				DisconnectConnections()
			end)

			RebirthConnection = Rebirths.Changed:Connect(function()
				local PlayerExists = Player and Players:FindFirstChild(Player.Name)
				local TriggeringPlayerExists = TriggeringPlayer and Players:FindFirstChild(TriggeringPlayer.Name)

				if TriggeringPlayerExists then
					DisableStealing()

					if PlayerExists then
						ReturnStolenThing()
					else
						DestroyStolenThing()
						UpdateMoneyPerSecondModule.Update(Player)
					end
				end

				StolenThings[TriggeringPlayer] = nil
				DisconnectConnections()
			end)

			local Debounce = false

			CollectZoneConnection = CollectZone.Touched:Connect(function(Hit)
				if Debounce then return end

				Debounce = true

				local TouchingPlayer = Players:GetPlayerFromCharacter(Hit.Parent)
				if not TouchingPlayer then
					Debounce = false
					return
				end

				local PlayerExists = Player and Players:FindFirstChild(Player.Name)
				local TriggeringPlayerExists = TriggeringPlayer and Players:FindFirstChild(TriggeringPlayer.Name)

				if not TriggeringPlayerExists or TouchingPlayer ~= TriggeringPlayer then
					Debounce = false
					return
				end

				Debounce = true

				DisableStealing()

				task.spawn(Module.Add, TriggeringPlayer, Base, UnoccupiedSlot, Name, AppliedTraits, Mutation)

				CollectAttachment:Destroy()
				Thing:Destroy()

				Slot.Configuration.Thing.Value = nil
				Slot.Configuration.Occupied.Value = false

				DestroyStolenThing()

				UpdateMoneyPerSecondModule.Update(Player)

				local TriggeringPlayerLeaderstats = TriggeringPlayer:WaitForChild("leaderstats")
				local TriggeringPlayerStealsValue = TriggeringPlayerLeaderstats:WaitForChild("Steals")

				TriggeringPlayerStealsValue.Value += 1

				if PlayerExists then
					NotificationEvent:FireClient(Player, string.format("Your %s got stolen!", Name), false)
				end

				NotificationEvent:FireClient(TriggeringPlayer, string.format("You stole %s!", Name), true)

				StolenThings[TriggeringPlayer] = nil

				DisconnectConnections()
			end)

			for Event, Configuration in pairs(Events) do
				local EventModel = workspace.Events:FindFirstChild(Event)
				if not EventModel then continue end

				local CollectZone = EventModel:FindFirstChild("CollectZone")
				if not CollectZone then continue end

				EventCollectZoneConnections[Event] = CollectZone.Touched:Connect(function(Hit)
					if Debounce then return end

					Debounce = true

					local TouchingPlayer = Players:GetPlayerFromCharacter(Hit.Parent)
					if not TouchingPlayer then
						Debounce = false
						return
					end

					local PlayerExists = Player and Players:FindFirstChild(Player.Name)
					local TriggeringPlayerExists = TriggeringPlayer and Players:FindFirstChild(TriggeringPlayer.Name)

					if not TriggeringPlayerExists or TouchingPlayer ~= TriggeringPlayer then
						Debounce = false
						return
					end

					local ThingNameMatches = (not Configuration.Things.Name) or (Name == Configuration.Things.Name)
					local MutationMatches = (not Configuration.Things.Mutation) or (Mutation == Configuration.Things.Mutation)

					if not (ThingNameMatches and MutationMatches) or (Module.EventsTimes[Event] or 0) > 0 then
						Debounce = false
						return
					end

					DisableStealing()

					Module.EventsThings[Event] = (Module.EventsThings[Event] or 0) + 1

					CollectAttachment:Destroy()
					Thing:Destroy()

					Slot.Configuration.Thing.Value = nil
					Slot.Configuration.Occupied.Value = false

					UnoccupiedSlot.Configuration.Occupied.Value = false

					DestroyStolenThing()

					UpdateMoneyPerSecondModule.Update(Player)

					local TriggeringPlayerLeaderstats = TriggeringPlayer:WaitForChild("leaderstats")
					local TriggeringPlayerStealsValue = TriggeringPlayerLeaderstats:WaitForChild("Steals")

					TriggeringPlayerStealsValue.Value += 1

					if PlayerExists then
						NotificationEvent:FireClient(Player, string.format("Your %s got stolen!", Name), false)
					end

					NotificationEvent:FireClient(TriggeringPlayer, string.format("You stole %s!", Name), true)

					StolenThings[TriggeringPlayer] = nil

					DisconnectConnections()
				end)
			end
		end
	end)

	local MoneyPerSecond = Configuration.MoneyPerSecond
	local CollectMoney = 0
	
	local MAX_ONLINE_SECONDS = 600 -- 10 minutes cap
	local ElapsedOnlineTime = 0 -- how long this thing has produced online

	AppliedTraits = AppliedTraits or {}

	local TraitMultiplier = 0
	for _, TraitName in ipairs(AppliedTraits) do
		local TraitConfiguration = Traits[TraitName]
		if TraitConfiguration then
			TraitMultiplier += TraitConfiguration.Multiplier or 0
		end
	end

	local MutationMultiplier = Mutations[Mutation] and Mutations[Mutation].Multiplier or 1
	local DefaultMultiplier = (Mutations.Default and Mutations.Default.Multiplier) or 1

	local SubtractValue = 0
	if TraitMultiplier ~= 0 then
		SubtractValue = DefaultMultiplier
	end

	local TotalMultiplier = MutationMultiplier + (TraitMultiplier - SubtractValue)


	-- Detect instant purchase
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerWhoBought, purchasedGamePassID, wasPurchased)
		if playerWhoBought == Player and purchasedGamePassID == GamepassID_X2 and wasPurchased then
			HasX2 = true

			-- Update money UI instantly
			if CollectGui and CollectGui:IsDescendantOf(game) then
				CollectGui.Money.RichText = true
				CollectGui.Money.Text = string.format("$%s <font color='#FFFF00'>(x2)</font>", Numbers.Format(CollectMoney))
			end
		end
	end)

	-- Initial display
	local MaxOfflineTime = 3600 
	local OfflineRate = 0.1 -- you get 10% of what you would originally get

	if Time then
		local TimeOffline = math.min(os.time() - Time, MaxOfflineTime)

		if TimeOffline > 0 and MoneyPerSecond > 0 and MultiplierValue then
			CollectMoney = math.round(
				(TimeOffline * math.round(MoneyPerSecond * TotalMultiplier) * MultiplierValue.Value) * OfflineRate
			)

			CollectGui.OfflineMoney.Text = string.format("(Offline Money $%s)", Numbers.Format(CollectMoney))
			CollectGui.OfflineMoney.Visible = true
		end
	end

	-- Initial Money display
	if HasX2 then
		CollectGui.Money.RichText = true
		CollectGui.Money.Text = string.format("$%s <font color='#FFFF00'>(x2)</font>", Numbers.Format(CollectMoney))
	else
		CollectGui.Money.Text = string.format("$%s", Numbers.Format(CollectMoney))
	end

	-- Collect touch logic
	local CollectConnection
	local PlayCollectSound = ReplicatedStorage.Remotes.Events:WaitForChild("PlayCollectSound")
	CollectConnection = Slot.Collect.Touched:Connect(function(Hit)
		local TouchingPlayer = Players:GetPlayerFromCharacter(Hit.Parent)
		if not TouchingPlayer then return end
		if not CollectGui or not CollectGui:IsDescendantOf(game) then return end

		if TouchingPlayer == Player and CollectMoney > 0 then
			local Earned = CollectMoney
			if HasX2 then
				Earned *= 2
			end
			PlayerMoneyValue.Value += Earned
			CollectMoney = 0
			ElapsedOnlineTime = 0

			if HasX2 then
				CollectGui.Money.RichText = true
				CollectGui.Money.Text = string.format("$%s <font color='#FFFF00'>(x2)</font>", Numbers.Format(CollectMoney))
			else
				CollectGui.Money.Text = string.format("$%s", Numbers.Format(CollectMoney))
			end

			CollectGui.OfflineMoney.Visible = false

			PlayCollectSound:FireClient(TouchingPlayer)
		end
	end)

	task.spawn(function()
		-- Main update loop
		while task.wait(1) and CollectGui and CollectGui.Parent and not ThingGui.Stolen.Visible do
			if MultiplierValue and MoneyPerSecond > 0 then
				local AddedMoney = math.round(math.round(MoneyPerSecond * TotalMultiplier) * MultiplierValue.Value)
				if HasX2 then
					AddedMoney *= 2
				end
				if ElapsedOnlineTime < MAX_ONLINE_SECONDS then
					CollectMoney += AddedMoney
					ElapsedOnlineTime += 1
				end
			end

			if HasX2 then
				CollectGui.Money.RichText = true
				CollectGui.Money.Text = string.format("$%s <font color='#FFFF00'>(x2)</font>", Numbers.Format(CollectMoney))
			else
				CollectGui.Money.Text = string.format("$%s", Numbers.Format(CollectMoney))
			end
		end

		-- Secondary loop for when Thing is not stolen
		while CollectGui and CollectGui:IsDescendantOf(game) do
			task.wait(1)

			local Stolen = ThingGui:FindFirstChild("Stolen")
			if not Stolen then break end
			if Stolen.Visible then continue end

			if MutationMultiplier and MultiplierValue and MoneyPerSecond > 0 then
				local AddedMoney = math.round(MoneyPerSecond * TotalMultiplier * MultiplierValue.Value)
				if HasX2 then
					AddedMoney *= 2
				end
				if ElapsedOnlineTime < MAX_ONLINE_SECONDS then
					CollectMoney += AddedMoney
					ElapsedOnlineTime += 1
				end

			end

			if HasX2 then
				CollectGui.Money.RichText = true
				CollectGui.Money.Text = string.format("$%s <font color='#FFFF00'>(x2)</font>", Numbers.Format(CollectMoney))
			else
				CollectGui.Money.Text = string.format("$%s", Numbers.Format(CollectMoney))
			end
		end

		-- Cleanup at the end of the task
		if CollectConnection then
			CollectConnection:Disconnect()
			CollectConnection = nil
		end
	end)

end

function Module.Spawn(Name, AppliedTraits, Mutation)
	local Thing, Configuration, Rarity, Price, MoneyPerSecond, ThingAttachment, ThingGui, ProximityPrompt, OffsetY, IdleTrack, WalkTrack, Sound =  Module.Create(Name, AppliedTraits, Mutation, Waypoints.Waypoint1, workspace.Things)

	if not Thing then return end

	ProximityPrompt.ActionText = string.format("Purchase $%s", Numbers.Format(Configuration.Price))
	ProximityPrompt.HoldDuration = 0.25

	SetProperties.AllClients(ProximityPrompt, {Enabled = true})

	if WalkTrack then WalkTrack:Play() end

	local RarityConfiguration = Rarities[Rarity]

	if Sound and (Rarity == "Developer God" or Rarity == "Secret") then
		Sound.Volume = 3
		Sound:Play()
	end

	if RarityConfiguration and RarityConfiguration.ChatAnnouncement then
		local rarityColor = Color3.fromRGB(255, 255, 255) -- default

		if Rarity == "Developer God" then
			rarityColor = Color3.fromRGB(255, 0, 0) -- red
		elseif Rarity == "Secret" then
			rarityColor = Color3.fromRGB(0, 0, 0) -- black
		end

		local messageParts = {
			{Text = "[Server] ", Color = Color3.fromRGB(0, 170, 255)}, -- blue
			{Text = Rarity .. " ", Color = rarityColor},
			{Text = "has spawned!", Color = Color3.fromRGB(255, 255, 255)} -- white
		}

		ChatAnnouncementEvent:FireAllClients(messageParts)
	end



	local WaypointRotationTween
	local WaypointMovementTween

	local CollectZoneRotationTween
	local CollectZoneMovementTween

	local Speed = tonumber(Things.Speed)

	ProximityPrompt.Triggered:Connect(function(Player)
		if SpawnedThings[Thing] and SpawnedThings[Thing].Owner == Player then return end

		local Leaderstats = Player:FindFirstChild("leaderstats")
		local Money = Leaderstats and Leaderstats:FindFirstChild("Money")
		local RebirthsValue = Leaderstats and Leaderstats:FindFirstChild("Rebirths")

		local Price = Configuration.Price or 0
		local PurchasedAmount = SpawnedThings[Thing] and SpawnedThings[Thing].PurchasedAmount or 0

		PurchasedAmount += 1

		if not Money or Money.Value < Price * PurchasedAmount then
			NotificationEvent:FireClient(Player, "Not enough money!", false)
			return
		end

		local ConfigurationFolder = Player:FindFirstChild("Configuration")
		local BaseValue = ConfigurationFolder and ConfigurationFolder:FindFirstChild("Base")
		local Base = BaseValue and BaseValue.Value
		if not Base then return end

		local CollectZone = Base:FindFirstChild("CollectZone")
		if not CollectZone then return end

		local SlotsFolder = Base:FindFirstChild("Slots")
		if not SlotsFolder then return end

		local Slots = SlotsFolder:GetChildren()
		table.sort(Slots, function(A, B)
			local AIndex = tonumber(string.match(A.Name, "%d+")) or 0
			local BIndex = tonumber(string.match(B.Name, "%d+")) or 0
			return AIndex < BIndex
		end)

		local PreviousSlot = SpawnedThings[Thing] and SpawnedThings[Thing].Slot
		if PreviousSlot then
			PreviousSlot.Configuration.Occupied.Value = false
		end

		local Rebirths = RebirthsValue and RebirthsValue.Value or 0

		local UnoccupiedSlot = nil
		for _, Slot in ipairs(Slots) do
			if Slot.Configuration.Occupied.Value == false and Slot.Configuration.Rebirth.Value <= Rebirths then
				Slot.Configuration.Occupied.Value = true
				UnoccupiedSlot = Slot
				break
			end
		end

		if not UnoccupiedSlot then
			NotificationEvent:FireClient(Player, "Not enough room!", false)
			return
		end

		Money.Value = Money.Value - Price * PurchasedAmount

		local PreviousOwner = SpawnedThings[Thing] and SpawnedThings[Thing].Owner
		if PreviousOwner then
			SetProperties.Client(PreviousOwner, ProximityPrompt, {Enabled = true})
		end

		SpawnedThings[Thing] = {
			Owner = Player,
			Slot = UnoccupiedSlot,
			PurchasedAmount = PurchasedAmount,
			Rebirths = Rebirths 
		}

		SetProperties.Client(Player, ProximityPrompt, {Enabled = false})

		ProximityPrompt.ActionText = string.format("Purchase $%s", Numbers.Format(Price * (SpawnedThings[Thing].PurchasedAmount + 1)))

		if Sound then
			Sound.Volume = 3
			Sound:Play()
		end

		local CurrentCFrame = Thing.PrimaryPart.CFrame

		if WaypointRotationTween then
			WaypointRotationTween:Cancel()
			WaypointRotationTween = nil
		end

		if WaypointMovementTween then
			WaypointMovementTween:Cancel()
			WaypointMovementTween = nil
		end

		if CollectZoneRotationTween then
			CollectZoneRotationTween:Cancel()
			CollectZoneRotationTween = nil
		end

		if CollectZoneMovementTween then
			CollectZoneMovementTween:Cancel()
			CollectZoneMovementTween = nil
		end

		Thing:SetPrimaryPartCFrame(CurrentCFrame)

		local StartPosition = CurrentCFrame.Position
		local CollectZonePosition = Vector3.new(CollectZone.Position.X, CollectZone.Position.Y + OffsetY, CollectZone.Position.Z)
		local Direction = (CollectZonePosition - StartPosition).Unit
		local YAngle = math.atan2(-Direction.X, -Direction.Z)
		local TargetRotation = CFrame.new(StartPosition) * CFrame.Angles(0, YAngle, 0)

		CollectZoneRotationTween = TweenService:Create(Thing.PrimaryPart, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
			CFrame = TargetRotation
		})

		CollectZoneRotationTween:Play()
		CollectZoneRotationTween.Completed:Wait()

		local Distance = (CollectZonePosition - StartPosition).Magnitude

		if Speed then
			CollectZoneMovementTween = TweenService:Create(Thing.PrimaryPart, TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(CollectZonePosition) * CFrame.Angles(0, YAngle, 0)
			})

			CollectZoneMovementTween:Play()
			CollectZoneMovementTween.Completed:Wait()
		end

		if not SpawnedThings[Thing] or SpawnedThings[Thing].Owner ~= Player then return end

		local StoredRebirths = SpawnedThings[Thing] and SpawnedThings[Thing].Rebirths or 0
		Rebirths = RebirthsValue and RebirthsValue.Value or 0

		if Rebirths > StoredRebirths then
			if UnoccupiedSlot then
				UnoccupiedSlot.Configuration.Occupied.Value = false
			end

			SpawnedThings[Thing] = nil
			Thing:Destroy()

			return
		end

		SpawnedThings[Thing] = nil
		Thing:Destroy()

		if not Player then return end
		if not UnoccupiedSlot then return end
		if not Name then return end

		Module.Add(Player, Base, UnoccupiedSlot, Name, AppliedTraits, Mutation)
	end)

	local WaypointList = Waypoints:GetChildren()
	table.sort(WaypointList, function(A, B)
		return tonumber(string.match(A.Name, "%d+")) < tonumber(string.match(B.Name, "%d+"))
	end)

	for _, Waypoint in ipairs(WaypointList) do
		if SpawnedThings[Thing] then break end

		local TargetPosition = Vector3.new(Waypoint.Position.X, Waypoint.Position.Y + OffsetY, Waypoint.Position.Z)
		local CurrentPosition = Thing.PrimaryPart.Position
		local StartPosition = Vector3.new(CurrentPosition.X, TargetPosition.Y, CurrentPosition.Z)
		local Direction = (TargetPosition - StartPosition).Unit
		local YAngle = math.atan2(-Direction.X, -Direction.Z)

		local CurrentCFrame = Thing.PrimaryPart.CFrame
		local _, CurrentY, _ = CurrentCFrame:ToEulerAnglesYXZ()

		if Speed then
			WaypointMovementTween = TweenService:Create(Thing.PrimaryPart, TweenInfo.new((TargetPosition - StartPosition).Magnitude / Speed, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(TargetPosition) * CFrame.Angles(0, YAngle, 0)
			})
		end

		if math.abs(CurrentY - YAngle) > 0.01 then
			WaypointRotationTween = TweenService:Create(Thing.PrimaryPart, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(Vector3.new(CurrentCFrame.Position.X, TargetPosition.Y, CurrentCFrame.Position.Z)) * CFrame.Angles(0, YAngle, 0)
			})
			WaypointRotationTween:Play()
			WaypointRotationTween.Completed:Wait()
		else
			Thing:SetPrimaryPartCFrame(CFrame.new(StartPosition) * CFrame.Angles(0, YAngle, 0))
		end

		if WaypointMovementTween then
			WaypointMovementTween:Play()
			WaypointMovementTween.Completed:Wait()
		end

		local FinalOrientation = Waypoint.Orientation
		local FinalCFrame = CFrame.new(TargetPosition) * CFrame.Angles(
			math.rad(FinalOrientation.X),
			math.rad(FinalOrientation.Y),
			math.rad(FinalOrientation.Z)
		)

		if not SpawnedThings[Thing] then
			Thing:SetPrimaryPartCFrame(FinalCFrame)
		end
	end

	if not SpawnedThings[Thing] then
		ThingAttachment:Destroy()
		ProximityPrompt:Destroy()

		if WalkTrack then
			WalkTrack:Stop()
		end

		Thing:Destroy()
	end
end

local ActiveTraitTimers = {}

function Module.Trait(Trait, Active)
	if not Trait then return end

	local Configuration = Traits[Trait]
	if not Configuration then return end

	if Active == nil then Active = false end

	-- Set active state
	Module.Traits[Trait] = Active

	-- Cancel old timer (if the trait gets toggled early)
	if ActiveTraitTimers[Trait] then
		ActiveTraitTimers[Trait] = nil
	end

	if Active then
		-- Run Start()
		if Configuration.Start then
			Configuration.Start()
		end

		-- Start timer if Time exists
		if Configuration.Time and Configuration.Time > 0 then
			local thisTimer = {}
			ActiveTraitTimers[Trait] = thisTimer

			task.spawn(function()
				task.wait(Configuration.Time)

				-- If a new timer replaced this one, stop.
				if ActiveTraitTimers[Trait] ~= thisTimer then
					return
				end

				-- Auto disable trait
				Module.Trait(Trait, false)
			end)
		end

	else
		-- Run Stop()
		if Configuration.Stop then
			Configuration.Stop()
		end
	end
end


function Module.Event(Event, NewTime)
	if not Event then return end

	local Configuration = Events[Event]
	if not Configuration then return end

	local EventModel = workspace.Events:FindFirstChild(Event)

	local Machine = EventModel and EventModel:FindFirstChild("Machine")
	local EventPart = Machine and Machine:FindFirstChild("Event")
	local MachineGui = EventPart and EventPart:FindFirstChild("MachineGui")

	local BaseTime = tonumber(Configuration.Time)
	if not BaseTime or BaseTime <= 0 then return end

	local ExistingTime = Module.EventsTimes[Event] or 0
	local AddTime = (NewTime and type(NewTime) == "number" and NewTime > 0) and NewTime or BaseTime

	if ExistingTime <= 0 and AddTime > 0 then
		for _, Player in pairs(Players:GetPlayers()) do
			Module.EventsSpins[Event][Player] = (Module.EventsSpins[Event][Player] or 0) + 1
		end
	end

	local Wheel = EventModel and EventModel:FindFirstChild("Wheel")
	local Spin = Wheel and Wheel:FindFirstChild("Spin")
	local ProximityPrompt = Spin and Spin:FindFirstChildOfClass("ProximityPrompt")

	if ProximityPrompt then
		for _, Player in pairs(Players:GetPlayers()) do
			SetProperties.Client(Player, ProximityPrompt, {ActionText = "Free"})
		end
	end

	Module.EventsThings[Event] = 0
	Module.EventsTimes[Event] = ExistingTime + AddTime

	if Module.EventTasks[Event] then
		Module.EventTasks[Event].Running = false
		Module.EventTasks[Event] = nil
	end

	if Configuration.Start then
		Configuration.Start()
	end

	local EventTask = {Running = true}
	Module.EventTasks[Event] = EventTask

	local Time = MachineGui and MachineGui:FindFirstChild("Time")

	task.spawn(function()
		while EventTask.Running do
			local TimeLeft = Module.EventsTimes[Event] or 0

			if MachineGui and Time then
				if TimeLeft > 0 then
					Time.Text = Numbers.Time(TimeLeft)
				end
			end

			task.wait(1)

			if not EventTask.Running then
				break
			end

			if TimeLeft > 0 then
				Module.EventsTimes[Event] = TimeLeft - 1

				if Module.EventsTimes[Event] <= 0 then
					EventTask.Running = false
				end
			end
		end

		if Configuration.Stop and (Module.EventsTimes[Event] or 0) <= 0 then
			Configuration.Stop()

			if ProximityPrompt then
				for _, Player in pairs(Players:GetPlayers()) do
					SetProperties.Client(Player, ProximityPrompt, {ActionText = "Purchase"})
				end
			end

			Module.EventsSpins[Event] = {}
		end

		if Module.EventTasks[Event] == EventTask then
			Module.EventTasks[Event] = nil
		end
	end)
end

function Module.Initialize()
	local Rate = tonumber(Things.Rate)
	if not Rate then return end

	for Trait in pairs(Traits) do
		Module.Traits[Trait] = false
	end

	for Event, Configuration in pairs(Events) do
		Module.EventsThings[Event] = 0
		Module.EventsTimes[Event] = 0

		Module.EventsSpins[Event] = {}

		local EventModel = workspace.Events:FindFirstChild(Event)
		local Machine = EventModel and EventModel:FindFirstChild("Machine")

		local MachineGui, _ = Insert.Event(EventModel, Event)

		local CollectZone = Machine:FindFirstChild("CollectZone")
		if CollectZone then
			local CollectZoneGui = Insert.CollectZone(CollectZone)
		end

		local ProximityPrompt

		local Purchase = Machine:FindFirstChild("Purchase")
		if Purchase then
			ProximityPrompt = Insert.ProximityPrompt(Purchase)
			ProximityPrompt.ActionText = "Purchase"
			ProximityPrompt.ObjectText = Event

			SetProperties.AllClients(ProximityPrompt, {Enabled = true})

			ProximityPrompt.Triggered:Connect(function(Player)
				MarketplaceService:PromptProductPurchase(Player, Configuration.Machine.DeveloperProductId)
			end)
		end

		local Time = MachineGui and MachineGui:FindFirstChild("Time")
		local Progress = MachineGui and MachineGui:FindFirstChild("Progress")

		task.spawn(function()
			while task.wait(1) do
				if (Module.EventsTimes[Event] or 0) > 0 then
					if Time then Time.Visible = true end
					if Progress then Progress.Visible = false end

					if ProximityPrompt then
						SetProperties.AllClients(ProximityPrompt, {Enabled = false})
					end
				else
					if Time then Time.Visible = false end

					if Progress then
						Progress.Text = string.format("%s/%s", Numbers.Format(Module.EventsThings[Event]), Numbers.Format(tonumber(Configuration.Machine.Things.Amount) or 1))
						Progress.Visible = true
					end

					if ProximityPrompt then
						SetProperties.AllClients(ProximityPrompt, {Enabled = true})
					end

					if Module.EventsThings[Event] >= (tonumber(Configuration.Machine.Things.Amount) or 1) then
						Module.Event(Event)
					end
				end
			end
		end)

		local Wheel = EventModel and EventModel:FindFirstChild("Wheel")
		local Segments = Wheel and Wheel:FindFirstChild("Segments")

		if Segments then
			local Segments = {}

			for Index = 1, 8 do
				local Segment = Wheel.Segments:FindFirstChild(string.format("Segment%s", Index))
				if Segment then
					Segments[Index] = Segment
				end
			end

			local SegmentsConfiguration = {}

			local ChanceUsed = 0

			for Thing, PrizeConfiguration in pairs(Configuration.Wheel.Prizes.Things or {}) do
				ChanceUsed += PrizeConfiguration.Chance

				local ThingConfiguration = Things.Things[Thing]
				if not ThingConfiguration then continue end

				local MutationConfiguration = Mutations[PrizeConfiguration.Mutation]
				if not MutationConfiguration then continue end

				table.insert(SegmentsConfiguration, {
					Name = Thing,
					Mutation = PrizeConfiguration.Mutation,
					Colour = MutationConfiguration.Colour,
					Icon = ThingConfiguration.Icon,
					Chance = PrizeConfiguration.Chance
				})
			end

			for Money, PrizeConfiguration in pairs(Configuration.Wheel.Prizes.Money or {}) do
				if tonumber(Money) <= 0 then continue end

				ChanceUsed += PrizeConfiguration.Chance

				table.insert(SegmentsConfiguration, {
					Name = string.format("$%s", Numbers.Format(Money)),
					Money = Money,
					Colour = Color3.fromRGB(0, 255, 0),
					Icon = "rbxassetid://129722939235976",
					Chance = PrizeConfiguration.Chance
				})
			end

			local NothingChance = (100 - ChanceUsed) / (#Segments - #SegmentsConfiguration)

			for Index = 1, #Segments do
				if Index <= #SegmentsConfiguration then
					Insert.Segment(Segments[Index], SegmentsConfiguration[Index])
				else
					local NothingConfiguration = {
						Name = "Nothing",
						Colour = Color3.fromRGB(163, 162, 165),
						Icon = "",
						Chance = NothingChance
					}

					table.insert(SegmentsConfiguration, NothingConfiguration)
					Insert.Segment(Segments[Index], NothingConfiguration)
				end
			end

			local Spin = Wheel:FindFirstChild("Spin")
			if Spin then
				local ProximityPrompt = Insert.ProximityPrompt(Spin)
				ProximityPrompt.ObjectText = "Spin"
				ProximityPrompt.Enabled = true

				SetProperties.AllClients(ProximityPrompt, {ActionText = "Purchase"})

				local function SpinWheel(Player)
					local Roll = math.random() * 100
					local Cumulative = 0

					local ChosenSegmentConfiguration
					local ChosenSegment

					for Index, SegmentConfiguration in ipairs(SegmentsConfiguration) do
						Cumulative += SegmentConfiguration.Chance

						if Roll <= Cumulative then
							ChosenSegmentConfiguration = SegmentConfiguration
							ChosenSegment = Segments[Index]

							break
						end
					end

					if ChosenSegment then
						SpinWheelEvent:FireClient(Player, Wheel, ChosenSegment)

						task.delay(2.5, function()
							local Name = ChosenSegmentConfiguration.Name

							if Name == "Nothing" then
								NotificationEvent:FireClient(Player, Name, false)
								return
							end

							local Money = tonumber(ChosenSegmentConfiguration.Money)
							local Mutation = Mutations[ChosenSegmentConfiguration.Mutation] and ChosenSegmentConfiguration.Mutation

							local Leaderstats = Player:FindFirstChild("leaderstats")
							if not Leaderstats then return end

							if Money then
								local MoneyValue = Leaderstats:FindFirstChild("Money")
								if not MoneyValue then return end

								NotificationEvent:FireClient(Player, string.format("%s!", Name), true)

								MoneyValue.Value += Money
							elseif Name and Things.Things[Name] and Mutation then
								local Rebirths = Leaderstats:FindFirstChild("Rebirths")
								if not Rebirths then return end

								local Configuration = Player:FindFirstChild("Configuration")

								local Base = Configuration:FindFirstChild("Base") and Configuration.Base.Value
								if not Base then return end

								local SlotsFolder = Base:FindFirstChild("Slots")
								if not SlotsFolder then return end

								local Slots = SlotsFolder:GetChildren()
								table.sort(Slots, function(A, B)
									local AIndex = tonumber(string.match(A.Name, "%d+")) or 0
									local BIndex = tonumber(string.match(B.Name, "%d+")) or 0
									return AIndex < BIndex
								end)

								local UnoccupiedSlot = nil
								for _, Slot in ipairs(Slots) do
									if Slot.Configuration.Occupied.Value == false and Slot.Configuration.Rebirth.Value <= Rebirths.Value then
										Slot.Configuration.Occupied.Value = true
										UnoccupiedSlot = Slot
										break
									end
								end

								if not UnoccupiedSlot then
									NotificationEvent:FireClient(Player, "Not enough room!", false)
									return
								end

								NotificationEvent:FireClient(Player, string.format("%s!", Name), true)

								task.spawn(Module.Add, Player, Base, UnoccupiedSlot, Name, {}, Mutation)
							end
						end)
					end
				end

				ProximityPrompt.Triggered:Connect(function(Player)
					Module.EventsSpins[Event] = Module.EventsSpins[Event] or {}

					local Spins = Module.EventsSpins[Event][Player] or 0

					if Spins > 0 then
						Module.EventsSpins[Event][Player] = Module.EventsSpins[Event][Player] - 1

						SetProperties.Client(Player, ProximityPrompt, {ActionText = Module.EventsSpins[Event][Player] > 0 and "Free" or "Purchase"})

						SpinWheel(Player)
					else
						MarketplaceService:PromptProductPurchase(Player, Configuration.Wheel.DeveloperProductId)
					end
				end)

				MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserId, ProductId, IsPurchased)
					if not IsPurchased then return end

					if Configuration.Wheel.DeveloperProductId == ProductId then
						local Player = Players:GetPlayerByUserId(UserId)

						SpinWheel(Player)
					end
				end)
			end
		end

		local Cooldown = tonumber(Configuration.Cooldown)
		local Chance = tonumber(Configuration.Chance)

		if not Cooldown or Cooldown <= 0 then continue end
		if not Chance or Chance <= 0 then continue end

		task.spawn(function()
			while task.wait(Cooldown) do
				if math.random(1, 100) <= Chance then
					Module.Event(Event)
				end
			end
		end)
	end

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserId, ProductId, IsPurchased)
		if not IsPurchased then return end

		for Event, Configuration in pairs(Events) do
			if Configuration.Machine.DeveloperProductId == ProductId then
				Module.Event(Event)

				break
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(Player)
		for Event, _ in pairs(Events) do
			if Module.EventsSpins[Event][Player] then
				Module.EventsSpins[Event][Player] = nil
			end
		end
	end)

	task.spawn(function()
		while task.wait(Rate) do
			if #SpawnThings > 0 then
				local Thing = table.remove(SpawnThings, 1)
				task.spawn(Module.Spawn, Thing.Name, Thing.Traits, Thing.Mutation)
			else
				local RandomName, AppliedTraits, RandomMutation = Module.Random()
				task.spawn(Module.Spawn, RandomName, AppliedTraits, RandomMutation)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local Time = os.time()

			if Module.LuckTime > 0 and Time >= Module.LuckTime then
				Module.Luck = 1
				Module.LuckTime = 0

				ServerLuckEvent:FireAllClients(Module.Luck, Module.LuckTime)
			end
		end
	end)
end

function Module.Queue(Amount, Name, AppliedTraits, Mutation)
	if typeof(Amount) ~= "number" or Amount < 1 then return end

	local function Match(Table, Input)
		for Key in pairs(Table) do
			if Key:lower() == tostring(Input):lower() then
				return Key
			end
		end

		return
	end

	local Name = Match(Things.Things, Name)
	if not Name then return end

	AppliedTraits = AppliedTraits or {}

	local ValidTraits = {}
	for _, Trait in ipairs(AppliedTraits) do
		local ValidTrait = Match(Traits, Trait)
		if ValidTrait then
			table.insert(ValidTraits, ValidTrait)
		end
	end

	local Mutation = Match(Mutations, Mutation)
	if not Mutation then return end

	for _ = 1, Amount do
		table.insert(SpawnThings, {
			Name = Name,
			Traits = ValidTraits,
			Mutation = Mutation
		})
	end
end

function Module.ServerLuck(NextLuck, Duration)
	if not tonumber(NextLuck) then return end

	local TimeNow = os.time()

	-- Reset luck
	if NextLuck == 1 then
		Module.Luck = 1
		Module.LuckTime = 0
		ServerLuckEvent:FireAllClients(Module.Luck, Module.LuckTime)

		-- Update ServerLuckState
		local ServerLuckState = game:GetService("ReplicatedStorage"):WaitForChild("ServerLuckState")
		ServerLuckState.Luck.Value = 1
		ServerLuckState.LuckTime.Value = 0

		return
	end

	local Configuration = ServerLuck[NextLuck]
	if not Configuration then return end

	Duration = tonumber(Duration) or Configuration.Time or 0

	-- Extend current luck if higher or same
	if NextLuck >= (Module.Luck or 1) then
		if Module.LuckTime and Module.LuckTime > TimeNow then
			Module.LuckTime = Module.LuckTime + Duration -- extend remaining time
		else
			Module.LuckTime = TimeNow + Duration -- fresh timer
		end
		Module.Luck = NextLuck
	end

	-- Send absolute timestamp only
	ServerLuckEvent:FireAllClients(Module.Luck, Module.LuckTime)

	-- Update ServerLuckState
	local ServerLuckState = game:GetService("ReplicatedStorage"):WaitForChild("ServerLuckState")
	ServerLuckState.Luck.Value = Module.Luck
	ServerLuckState.LuckTime.Value = Module.LuckTime
end

Players.PlayerRemoving:Connect(function(Player)
	LeavingPlayers[Player.UserId] = true
end)

Players.PlayerAdded:Connect(function(Player)
	LeavingPlayers[Player.UserId] = nil
end)

return Module