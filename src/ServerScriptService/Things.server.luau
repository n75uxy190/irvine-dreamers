local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local AssetIds = require(ReplicatedStorage.Configuration.Modules:WaitForChild("AssetIds"))

local VIP_GAMEPASS_ID = AssetIds.GamePasses.VIP

local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local Insert = require(ServerStorage.Modules:WaitForChild("Insert"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local AssetIds = require(ReplicatedStorage.Configuration.Modules:WaitForChild("AssetIds"))
local Traits = require(ServerStorage.Configuration.Modules:WaitForChild("Traits"))
local UpdateMoneyPerSecondModule = require(ReplicatedStorage.Modules:WaitForChild("UpdateMoneyPerSecond"))

local Numbers = require(ReplicatedStorage.Modules:WaitForChild("Numbers"))
local Rebirths = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rebirths"))

local StealsOrderedDataStore = DataStoreService:GetOrderedDataStore("Steals")
local RebirthsOrderedDataStore= DataStoreService:GetOrderedDataStore("Rebirths")
local MoneyOrderedDataStore= DataStoreService:GetOrderedDataStore("Money")
local ThingsDataStore = DataStoreService:GetDataStore("Things")

local NotificationEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Notification")

local Bases = workspace:WaitForChild("Bases")

local BasesData = {}
local BasesConnections = {}

local PlayersInFloors = {}

local function UpdateMultiplier(Player, MultiplierGui)
	local Leaderstats = Player:WaitForChild("leaderstats")
	local RebirthsValue = Leaderstats:WaitForChild("Rebirths")

	local Configuration = Player:WaitForChild("Configuration")
	local FriendsValue = Configuration:WaitForChild("Friends")
	local MultiplierValue = Configuration:WaitForChild("Multiplier")
	local IndexMultiplierValue = Configuration:WaitForChild("IndexMultiplier")

	local Rebirth = RebirthsValue.Value
	local RebirthConfig = Rebirths[Rebirth]

	local RebirthMultiplier = 0
	if RebirthConfig and RebirthConfig.Unlocks and RebirthConfig.Unlocks.Multiplier then
		RebirthMultiplier = RebirthConfig.Unlocks.Multiplier
	end

	local BaseMultiplier = 1
	local FriendsBonus = FriendsValue.Value * 0.1
	local IndexMultiplier = IndexMultiplierValue.Value

	local TotalMultiplier = BaseMultiplier + RebirthMultiplier + FriendsBonus + IndexMultiplier

	-- VIP check
	local success, hasVIP = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, Player.UserId, VIP_GAMEPASS_ID)
	if success and hasVIP then
		TotalMultiplier += 0.5
	end

	MultiplierValue.Value = TotalMultiplier
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, PassId, Purchased)
	if Purchased and PassId == VIP_GAMEPASS_ID then
		UpdateMultiplier(Player)
	end
end)

local function UpdateFriends()
	for _, Player in ipairs(Players:GetPlayers()) do
		local Configuration = Player:WaitForChild("Configuration")
		local FriendsValue = Configuration:WaitForChild("Friends")

		local Friends = 0
		local Success, FriendPages = pcall(function()
			return Players:GetFriendsAsync(Player.UserId)
		end)

		if Success and FriendPages then
			local OtherUserIds = {}
			for _, OtherPlayer in ipairs(Players:GetPlayers()) do
				OtherUserIds[OtherPlayer.UserId] = true
			end

			while true do
				local FriendPage = FriendPages:GetCurrentPage()
				for _, FriendData in ipairs(FriendPage) do
					if OtherUserIds[FriendData.Id] then
						Friends += 1
					end
				end

				local SuccessAdvance = pcall(function()
					FriendPages:AdvanceToNextPageAsync()
				end)

				if not SuccessAdvance or FriendPages.IsFinished then
					break
				end
			end
		end

		FriendsValue.Value = Friends
	end
end

local function LoadThings(Player)
	local Base = Player:FindFirstChild("Configuration") and Player.Configuration:FindFirstChild("Base") and Player.Configuration.Base.Value
	if not Base then return end

	local Slots = Base:FindFirstChild("Slots")
	if not Slots then return end

	Slots = Slots:GetChildren()

	table.sort(Slots, function(A, B)
		local AIndex = tonumber(string.match(A.Name, "%d+")) or 0
		local BIndex = tonumber(string.match(B.Name, "%d+")) or 0
		return AIndex < BIndex
	end)

	local Success, ThingsSavedData = pcall(function()
		return ThingsDataStore:GetAsync(tostring(Player.UserId))
	end)
	
	if not Success then
		warn("Failed to load things for player:", Player.Name)
		Player:Kick("Data loading failed, please rejoin.")
		return
	end

	local ThingsAmount = 0
	for _ in pairs(ThingsSavedData) do
		ThingsAmount += 1
	end

	if ThingsAmount > #Slots then
		NotificationEvent:FireClient(Player, "Too many saved things to load!", false)
		return
	end

	for Index, ThingSavedData in pairs(ThingsSavedData) do
		local Slot = Slots[tonumber(Index)]
		if Slot then
			local SavedTraits = ThingSavedData.Traits or ""

			local AppliedTraits = {}
			for TraitName in string.gmatch(SavedTraits, "([^,]+)") do
				TraitName = TraitName:gsub("^%s*(.-)%s*$", "%1")
				table.insert(AppliedTraits, TraitName)
			end

			Things.Add(Player, Base, Slot, ThingSavedData.Name, AppliedTraits, ThingSavedData.Mutation, ThingSavedData.Time)
		end
	end
end

-- Global queue to store failed saves
local FailedSavesQueue = {}

-- Function to periodically retry failed saves
task.spawn(function()
	while true do
		local processed = 0
		for key, profileData in pairs(FailedSavesQueue) do
			local success = pcall(function()
				ThingsDataStore:UpdateAsync(key, function(oldData)
					local Profile = oldData or {}
					Profile.Things = Profile.Things or {}
					for slotIndex, slotData in pairs(profileData) do
						-- merge only if slotData is newer
						local oldSlot = Profile.Things[slotIndex]
						if not oldSlot or (slotData.Time or 0) >= (oldSlot.Time or 0) then
							Profile.Things[slotIndex] = slotData
						end
					end
					return Profile
				end)
			end)

			if success then
				FailedSavesQueue[key] = nil -- remove successful save from queue
			end

			processed = processed + 1
			if processed >= 2 then
				break -- process only 1-2 keys per tick
			end
		end
		task.wait(1) -- smaller wait so keys retry more frequently without overloading
	end
end)

local function SaveThings(Player)
	local Base = Player:FindFirstChild("Configuration") 
		and Player.Configuration:FindFirstChild("Base") 
		and Player.Configuration.Base.Value
	if not Base then return end

	local Slots = Base:FindFirstChild("Slots")
	if not Slots then return end

	Slots = Slots:GetChildren()
	table.sort(Slots, function(A, B)
		local AIndex = tonumber(string.match(A.Name, "%d+")) or 0
		local BIndex = tonumber(string.match(B.Name, "%d+")) or 0
		return AIndex < BIndex
	end)

	local key = tostring(Player.UserId)

	-- Fetch old data once for all slots
	local oldData
	pcall(function()
		oldData = ThingsDataStore:GetAsync(key) or {}
	end)

	local ThingsSavedData = {}

	for Index, Slot in ipairs(Slots) do
		local Thing = Slot.Configuration.Thing.Value
		if not Thing then continue end

		local ThingAttachment = Thing.PrimaryPart:FindFirstChild("ThingAttachment")
		local ThingGui = ThingAttachment and ThingAttachment:FindFirstChild("ThingGui")
		local Stolen = ThingGui and ThingGui:FindFirstChild("Stolen")

		if Slot.Configuration.Occupied.Value 
			and Thing.Parent == Slot 
			and ThingGui 
			and Stolen 
			and not Stolen.Visible then

			local ThingConfiguration = Thing:FindFirstChild("Configuration")
			local MutationValue = ThingConfiguration and ThingConfiguration:FindFirstChild("Mutation")
			local TraitsValue = ThingConfiguration and ThingConfiguration:FindFirstChild("Traits")

			-- Use relative timestamp from oldData if available
			local oldSlotTime = nil
			if oldData[tostring(Index)] then
				oldSlotTime = oldData[tostring(Index)].Time
			end

			ThingsSavedData[tostring(Index)] = {
				Name = Thing.Name,
				Mutation = MutationValue and MutationValue.Value or "Default",
				Traits = TraitsValue and TraitsValue.Value or "",
				Time = oldSlotTime or 0 -- fallback to 0 if no previous timestamp
			}
		end
	end

	local success = pcall(function()
		ThingsDataStore:UpdateAsync(key, function(oldProfileData)
			local Profile = oldProfileData or {}
			-- Remove old slots that are now empty
			for slotIndex in pairs(Profile) do
				if not ThingsSavedData[slotIndex] then
					Profile[slotIndex] = nil
				end
			end

			-- Add/update current slots
			for slotIndex, slotData in pairs(ThingsSavedData) do
				local oldSlot = Profile[slotIndex]
				if not oldSlot or (slotData.Time or 0) >= (oldSlot.Time or 0) then
					Profile[slotIndex] = slotData
				end
			end
			return Profile
		end)
	end)

	if not success then
		warn("SaveThings failed for", Player.Name, "- queued for retry")
		FailedSavesQueue[key] = ThingsSavedData -- queue for retry later
	end
end


local function GetUnlockedFloors(Base, RebirthsAmount)
	if not RebirthsAmount or type(RebirthsAmount) ~= "number" then
		return {}
	end

	local UnlockedFloors = {}
	local Added = {}

	local function AddUnlockedFloor(Number)
		local Pattern = string.format("^Floor%d.*", Number)
		for _, Floor in pairs(Base.Floors:GetChildren()) do
			if Floor:IsA("Model") and Floor.Name:match(Pattern) and not Added[Floor] then
				table.insert(UnlockedFloors, Floor)
				Added[Floor] = true
			end
		end
	end

	AddUnlockedFloor(1)

	for Index = 1, RebirthsAmount do
		local Data = Rebirths[Index]
		if Data and Data.Unlocks and Data.Unlocks.Floor then
			AddUnlockedFloor(Data.Unlocks.Floor)
		end
	end

	return UnlockedFloors
end

local function GetUnlockedDoors(Base, RebirthsAmount)
	local UnlockedDoors = {}
	local UnlockedFloors = GetUnlockedFloors(Base, RebirthsAmount)

	for _, Floor in ipairs(UnlockedFloors) do
		local Doors = Floor:FindFirstChild("Doors")
		if Doors then
			for _, Door in ipairs(Doors:GetChildren()) do
				table.insert(UnlockedDoors, Door)
			end
		end
	end

	return UnlockedDoors
end

local function RefreshFriends()
	for _, Player in ipairs(Players:GetPlayers()) do
		local Configuration = Player:FindFirstChild("Configuration")
		local Base = Configuration and Configuration:FindFirstChild("Base") and Configuration.Base.Value
		if Base then
			local BaseData = BasesData[Base]
			if BaseData and BaseData.Allowed then
				local Rebirths = Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Rebirths")
				if Rebirths then
					local Success, Pages = pcall(function()
						return Players:GetFriendsAsync(Player.UserId)
					end)
					if Success then
						local OnlinePlayers = Players:GetPlayers()
						local OnlineIds = {}

						for _, OnlinePlayer in ipairs(OnlinePlayers) do
							OnlineIds[OnlinePlayer.UserId] = OnlinePlayer
						end

						local UnlockedDoors = GetUnlockedDoors(Base, Rebirths.Value)
						local NewAllowedFriends = {}

						repeat
							local Friends = Pages:GetCurrentPage()
							for _, Friend in ipairs(Friends) do
								local FriendPlayer = OnlineIds[Friend.Id]
								if FriendPlayer then
									NewAllowedFriends[FriendPlayer] = true

									for _, Door in ipairs(UnlockedDoors) do
										for _, Descendant in ipairs(Door:GetDescendants()) do
											if Descendant:IsA("BasePart") then
												SetProperties.Client(FriendPlayer, Descendant, {CanCollide = false})
											end
										end

										local ProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
										if ProximityPrompt then
											SetProperties.Client(FriendPlayer, ProximityPrompt, {Enabled = false})
										end
									end
								end
							end
						until Pages.IsFinished or not pcall(function() Pages:AdvanceToNextPageAsync() end)

						for OldFriend in pairs(BaseData.AllowedFriends) do
							if OldFriend:IsDescendantOf(Players) and not NewAllowedFriends[OldFriend] then
								for _, Door in ipairs(UnlockedDoors) do
									for _, Descendant in ipairs(Door:GetDescendants()) do
										if Descendant:IsA("BasePart") then
											SetProperties.Client(OldFriend, Descendant, {CanCollide = true})
										end
									end

									local ProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
									if ProximityPrompt then
										SetProperties.Client(OldFriend, ProximityPrompt, {Enabled = true})
									end
								end
							end
						end

						BaseData.AllowedFriends = NewAllowedFriends
					end
				end
			end
		end
	end
end

local function UpdateBase(Player)
	local Leaderstats = Player:WaitForChild("leaderstats")
	local RebirthsValue = Leaderstats and Leaderstats:WaitForChild("Rebirths")
	if not RebirthsValue then return end

	local Configuration = Player:FindFirstChild("Configuration")
	local Base = Configuration and Configuration:FindFirstChild("Base") and Configuration.Base.Value
	if not Base then return end

	local RebirthsAmount = RebirthsValue.Value

	-- Remove Roof from Floor2 if the player has 9+ rebirths
	if RebirthsAmount >= 9 then
		local Floors = Base:FindFirstChild("Floors")
		if Floors then
			local Floor2 = Floors:FindFirstChild("Floor2")
			if Floor2 then
				local Roof = Floor2:FindFirstChild("Roof")
				if Roof then
					Roof:Destroy()
				end
			end
		end
	end


	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local Configuration = Slot:FindFirstChild("Configuration")
		if not Configuration then
			continue
		end

		local Thing = Configuration:FindFirstChild("Thing")
		if not Thing then
			continue
		end

		local Rebirth = Configuration:FindFirstChild("Rebirth")
		if not Rebirth or not Rebirth.Value then
			continue
		end

		local IsUnlocked = RebirthsValue.Value >= Rebirth.Value

		for _, Child in ipairs(Slot:GetChildren()) do
			if Child ~= Thing.Value then
				if Child:IsA("BasePart") then
					if Child.Name ~= "Spawn" and Child.Name ~= "Collect" then
						Child.Transparency = IsUnlocked and 0 or 1
					else
						Child.Transparency = 1
					end
					Child.CanCollide = IsUnlocked
				end

				for _, Descendant in ipairs(Child:GetDescendants()) do
					if Descendant:IsA("BasePart") then
						if Descendant.Name ~= "Spawn" and Descendant.Name ~= "Collect" then
							Descendant.Transparency = IsUnlocked and 0 or 1
						else
							Descendant.Transparency = 1
						end
						Descendant.CanCollide = IsUnlocked
					end
				end
			end
		end
	end


	local UnlockedFloors = GetUnlockedFloors(Base, RebirthsAmount)
	local Added = {}
	for _, Floor in ipairs(UnlockedFloors) do
		Added[Floor] = true
	end

	for _, Floor in ipairs(Base.Floors:GetChildren()) do
		local IsUnlocked = Added[Floor] == true

		for _, Child in ipairs(Floor:GetChildren()) do
			if Child.Name ~= "Hitbox" and Child.Name ~= "Doors" then
				if Child:IsA("BasePart") then
					if Child.Name == "Staklo" then
						Child.Transparency = IsUnlocked and 0.6 or 1
						Child.CanCollide = IsUnlocked
					elseif Child.Name == "Lock" then
						Child.Transparency = 1
						Child.CanCollide = false
					else
						Child.Transparency = IsUnlocked and 0 or 1
						Child.CanCollide = IsUnlocked
					end
				end

				for _, Descendant in ipairs(Child:GetDescendants()) do
					if Descendant:IsA("BasePart") then
						if Descendant.Name == "Staklo" then
							Descendant.Transparency = IsUnlocked and 0.6 or 1
							Descendant.CanCollide = IsUnlocked
						elseif Descendant.Name == "Lock" then
							Descendant.Transparency = 1
							Descendant.CanCollide = false
						else
							Descendant.Transparency = IsUnlocked and 0 or 1
							Descendant.CanCollide = IsUnlocked
						end
					end
				end
			end
		end
	end

	local BaseData = BasesData[Base]
	if not BaseData then return end

	local UnlockedDoors = GetUnlockedDoors(Base, RebirthsAmount)
	for _, Door in ipairs(UnlockedDoors) do
		for _, Descendant in ipairs(Door:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.CanCollide = BaseData.Locked

			if BaseData.Locked then
				SetProperties.Client(Player, Descendant, {CanCollide = false})

				if BaseData.Allowed then
					for FriendPlayer in pairs(BaseData.AllowedFriends) do
						if FriendPlayer:IsDescendantOf(Players) then
							SetProperties.Client(FriendPlayer, Descendant, {CanCollide = false})
						end
					end
				end
			end

			if Descendant.Name == "Hitbox" then continue end

			Descendant.Transparency = BaseData.Locked and 0 or 1
		end
	end

	for _, Door in ipairs(UnlockedDoors) do
		local Hitbox = Door:FindFirstChild("Hitbox")
		if not Hitbox then continue end

		local ExistingPrompt = Hitbox:FindFirstChild("ProximityPrompt")
		if not ExistingPrompt then
			local ProximityPrompt = Insert.ProximityPrompt(Hitbox)
			ProximityPrompt.ActionText = "Unlock Base"
			ProximityPrompt.HoldDuration = 0.25

			ProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
				if TriggeringPlayer == Player then return end

				if not BaseData.Locked then
					NotificationEvent:FireClient(TriggeringPlayer, "Base already unlocked!", false)
					return
				end

				if BaseData.Starter then
					NotificationEvent:FireClient(TriggeringPlayer, "Base loading!", false)
					return
				end

				MarketplaceService:PromptProductPurchase(TriggeringPlayer, AssetIds.DeveloperProducts.UnlockBase)
			end)
		end
	end

	if BaseData.Locked then
		for _, Door in ipairs(UnlockedDoors) do
			local DoorProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
			if not DoorProximityPrompt then continue end

			SetProperties.AllClients(DoorProximityPrompt, {Enabled = true})
			SetProperties.Client(Player, DoorProximityPrompt, {Enabled = false})

			if BaseData.Allowed then
				for FriendPlayer in pairs(BaseData.AllowedFriends) do
					if FriendPlayer:IsDescendantOf(Players) then
						SetProperties.Client(FriendPlayer, DoorProximityPrompt, {Enabled = false})
					end
				end
			end
		end
	end	
end

local function GetSlotFloorNumber(Base, SlotRebirthValue)
	if SlotRebirthValue == 0 then
		local Floor1Folder = Base.Floors:FindFirstChild("Floor1")
		return Floor1Folder and 1 or nil
	else
		local ClosestRebirth = math.huge
		local SlotFloorNumber = nil
		for RebirthLevel, Data in pairs(Rebirths) do
			local FloorNumber = Data.Unlocks.Floor
			if FloorNumber and RebirthLevel >= SlotRebirthValue and RebirthLevel < ClosestRebirth then
				ClosestRebirth = RebirthLevel
				SlotFloorNumber = FloorNumber
			end
		end
		return SlotFloorNumber
	end
end

local function SetBase(Player)
	local AvailableBases = {}

	for _, Base in pairs(Bases:GetChildren()) do
		if not Base.Configuration.Player.Value then
			table.insert(AvailableBases, Base)
		end
	end

	if #AvailableBases == 0 then
		Player:Kick("No available Bases.")
		return
	end

	local RandomIndex = math.random(1, #AvailableBases)
	local Base = AvailableBases[RandomIndex]

	local Leaderstats = Player:WaitForChild("leaderstats")
	local RebirthsValue = Leaderstats:WaitForChild("Rebirths")

	local Configuration = Player:WaitForChild("Configuration")
	local BaseValue = Configuration:WaitForChild("Base")
	local MultiplierValue = Configuration:WaitForChild("Multiplier")

	BasesConnections[Base] = {}

	Base.Configuration.Player.Value = Player
	BaseValue.Value = Base

	local CharacterAddedConnection = Player.CharacterAdded:Connect(function(Character)
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		local Humanoid = Character:WaitForChild("Humanoid")

		local AssignedBase = Player:FindFirstChild("Configuration") and Player.Configuration:FindFirstChild("Base") and Player.Configuration.Base.Value
		if AssignedBase and AssignedBase:FindFirstChild("Spawn") then
			local SpawnPart = AssignedBase.Spawn
			local OffsetY = Humanoid.HipHeight + (HumanoidRootPart.Size.Y / 2) + (SpawnPart.Size.Y / 2)
			local SpawnCFrame = SpawnPart.CFrame + Vector3.new(0, OffsetY, 0)

			Character:PivotTo(SpawnCFrame)
		end
	end)

	table.insert(BasesConnections[Base], CharacterAddedConnection)

	BasesData[Base] = {
		Locked = false,
		Starter = false,
		Allowed = false,
		AllowedFriends = {}
	}

	local BaseData = BasesData[Base]

	local Debounce = false

	local LockAttachment, LockGui = Insert.Lock(Base.Lock)

	local function Unlock()
		if not LockGui then return end
		if not LockGui:FindFirstChild("Lock") then return end

		LockGui.Lock.Text = "Lock"
		LockGui.Lock.TextColor3 = Color3.fromRGB(255, 247, 0)

		LockGui.Time.Visible = false

		local UnlockedDoors = GetUnlockedDoors(Base, RebirthsValue.Value)
		for _, Door in ipairs(UnlockedDoors) do
			for _, Descendant in ipairs(Door:GetDescendants()) do
				if not Descendant:IsA("BasePart") then continue end

				Descendant.CanCollide = false
				Descendant.Transparency = 1
			end
		end

		BaseData.Locked = false
	end

	local function Lock(Time)
		if not LockGui then return end

		-- APPLY VIP +10s if user already owns it
		local HasVIP = false
		pcall(function()
			HasVIP = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, VIP_GAMEPASS_ID)
		end)
		-- track whether this lock already received VIP bonus (prevents double apply)
		local vipApplied = false
		if HasVIP then
			Time += 10
			vipApplied = true
		end

		-- per-lock purchase listener: if they buy VIP while this lock is active, add +10 immediately (only once)
		local vipConnection
		vipConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchaser, purchasedPassID, wasPurchased)
			if purchaser == Player and purchasedPassID == VIP_GAMEPASS_ID and wasPurchased and not vipApplied then
				vipApplied = true
				Time += 10
				-- update displayed time immediately
				if LockGui and LockGui:FindFirstChild("Time") then
					LockGui.Time.Text = Numbers.Time(Time)
				end
			end
		end)

		BaseData.Locked = true
		
		ReplicatedStorage.Remotes.Events.BaseLockSound:FireClient(Player)

		LockGui.Lock.Text = "Locked:"
		LockGui.Lock.TextColor3 = Color3.fromRGB(250, 0, 0)

		LockGui.Time.Visible = true
		LockGui.Time.Text = Numbers.Time(Time)

		local UnlockedDoors = GetUnlockedDoors(Base, RebirthsValue.Value)
		for _, Door in ipairs(UnlockedDoors) do
			for _, Descendant in ipairs(Door:GetDescendants()) do
				if not Descendant:IsA("BasePart") then continue end

				Descendant.CanCollide = true

				SetProperties.Client(Player, Descendant, {CanCollide = false})

				if BaseData.Allowed then
					for FriendPlayer in pairs(BaseData.AllowedFriends) do
						if FriendPlayer:IsDescendantOf(Players) then
							SetProperties.Client(FriendPlayer, Descendant, {CanCollide = false})
						end
					end
				end

				if Descendant.Name == "Hitbox" then continue end

				Descendant.Transparency = 0
			end
		end

		for _, Door in ipairs(UnlockedDoors) do
			local DoorProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
			if not DoorProximityPrompt then continue end

			SetProperties.AllClients(DoorProximityPrompt, {Enabled = true})
			SetProperties.Client(Player, DoorProximityPrompt, {Enabled = false})

			if BaseData.Allowed then
				for FriendPlayer in pairs(BaseData.AllowedFriends) do
					if FriendPlayer:IsDescendantOf(Players) then
						SetProperties.Client(FriendPlayer, DoorProximityPrompt, {Enabled = false})
					end
				end
			end
		end

		if not BaseData.Starter then
			NotificationEvent:FireClient(Player, string.format("Locked base for %ss!", Time), true)
		end

		task.spawn(function()
			while Time > 0 and Player and BaseData.Locked and LockGui do
				task.wait(1)

				Time -= 1

				if LockGui and LockGui:FindFirstChild("Time") then
					LockGui.Time.Text = Numbers.Time(Time)
				end
			end

			-- disconnect vip listener for this lock to avoid leaks / duplicate triggers
			if vipConnection then
				vipConnection:Disconnect()
				vipConnection = nil
			end

			local UnlockedDoors = GetUnlockedDoors(Base, RebirthsValue.Value)
			for _, Door in ipairs(UnlockedDoors) do
				local DoorProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
				if not DoorProximityPrompt then continue end

				SetProperties.AllClients(DoorProximityPrompt, {Enabled = false})
			end

			BaseData.Starter = false
			Unlock()
		end)
	end

	UpdateBase(Player)

	if math.random() > 0.25 then
		AssetIds.DeveloperProducts.UnlockBase = AssetIds.DeveloperProducts.UnlockBase
	end

	local PromptProductPurchaseFinishedConnection = MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserId, AssetId, IsPurchased)
		local Success, PurchasingPlayer = pcall(function()
			return Players:GetPlayerByUserId(UserId)
		end)

		if not (IsPurchased and Success and PurchasingPlayer and PurchasingPlayer ~= Player) or AssetId ~= AssetIds.DeveloperProducts.UnlockBase then
			return
		end

		if not BaseData.Locked then
			NotificationEvent:FireClient(PurchasingPlayer, "Base already unlocked!", false)
			return
		end

		if BaseData.Starter then
			NotificationEvent:FireClient(PurchasingPlayer, "Unable to unlock fresh base!", false)
			return
		end

		local UnlockedDoors = GetUnlockedDoors(Base, RebirthsValue.Value)
		for _, Door in ipairs(UnlockedDoors) do
			local DoorProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
			if not DoorProximityPrompt then continue end

			SetProperties.AllClients(DoorProximityPrompt, {Enabled = false})
		end

		Unlock()

		NotificationEvent:FireClient(PurchasingPlayer, "Unlocked base!", true)
	end)

	table.insert(BasesConnections[Base], PromptProductPurchaseFinishedConnection)


	local LockConnection = Base.Lock.Touched:Connect(function(Hit)
		local Character = Hit.Parent
		local TouchingPlayer = Players:GetPlayerFromCharacter(Character)
		if not TouchingPlayer then return end

		if Debounce then return end

		Debounce = true

		task.delay(1, function()
			Debounce = false
		end)

		if TouchingPlayer == Player and not BaseData.Locked then
			local Time = 60

			for Rebirth = 1, RebirthsValue.Value do
				local RebirthConfiguration = Rebirths[Rebirth]
				if RebirthConfiguration and RebirthConfiguration.Unlocks and RebirthConfiguration.Unlocks.Time then
					Time += RebirthConfiguration.Unlocks.Time
				end
			end

			Lock(Time, false)
		else
			if TouchingPlayer == Player then
				NotificationEvent:FireClient(Player, "Base already locked!", false)
				ReplicatedStorage.Remotes.Events.BaseErrorSound:FireClient(Player)
			end
		end
	end)

	table.insert(BasesConnections[Base], LockConnection)

	local FloorsFolder = Base:FindFirstChild("Floors")
	if FloorsFolder then
		local FloorLockGuis = {}

		for _, FloorModel in ipairs(FloorsFolder:GetChildren()) do
			if FloorModel:IsA("Model") and FloorModel.Name:match("^Floor(%d+)$") then
				local FloorNumber = tonumber(FloorModel.Name:match("%d+"))
				local LockPart = FloorModel:FindFirstChild("Lock")

				if LockPart then
					-- determine rebirth requirement
					local RequiredRebirth
					if FloorNumber == 2 then
						RequiredRebirth = 1
					elseif FloorNumber == 3 then
						RequiredRebirth = 9
					else
						RequiredRebirth = FloorNumber - 1
					end

					-- make GUI for this lock part (clone of base LockGui)
					local NewAttachment, NewGui = Insert.Lock(LockPart)
					FloorLockGuis[LockPart] = NewGui

					-- visibility based on rebirths
					local function UpdateLockVisibility()
						if RebirthsValue.Value >= RequiredRebirth then
							LockPart.Transparency = 1
							LockPart.CanTouch = true
							if NewGui then NewGui.Enabled = true end
						else
							LockPart.Transparency = 1
							LockPart.CanTouch = false
							if NewGui then NewGui.Enabled = false end
						end
					end

					UpdateLockVisibility()
					RebirthsValue:GetPropertyChangedSignal("Value"):Connect(UpdateLockVisibility)

					-- shared lock behavior (uses same Lock/Unlock)
					local FloorDebounce = false
					local FloorLockConnection = LockPart.Touched:Connect(function(Hit)
						local Character = Hit.Parent
						local TouchingPlayer = Players:GetPlayerFromCharacter(Character)
						if not TouchingPlayer then return end
						if TouchingPlayer ~= Player then return end
						if RebirthsValue.Value < RequiredRebirth then return end
						if FloorDebounce then return end

						FloorDebounce = true
						task.delay(1, function() FloorDebounce = false end)

						if not BaseData.Locked then
							local Time = 60
							for Rebirth = 1, RebirthsValue.Value do
								local RebirthConfiguration = Rebirths[Rebirth]
								if RebirthConfiguration and RebirthConfiguration.Unlocks and RebirthConfiguration.Unlocks.Time then
									Time += RebirthConfiguration.Unlocks.Time
								end
							end

							-- Lock instantly with GUI update
							Lock(Time)
						else
							if TouchingPlayer == Player then
								NotificationEvent:FireClient(Player, "Base already locked!", false)
								ReplicatedStorage.Remotes.Events.BaseErrorSound:FireClient(Player)
							end
						end
					end)

					table.insert(BasesConnections[Base], FloorLockConnection)
				end
			end
		end

		-- Sync GUIs with main LockGui updates
		local function SyncFloorLockGuis(Text, Color, TimeTextVisible, TimeValue)
			for _, Gui in pairs(FloorLockGuis) do
				if not Gui then continue end
				if Gui:FindFirstChild("Lock") then
					Gui.Lock.Text = Text
					Gui.Lock.TextColor3 = Color
				end
				if Gui:FindFirstChild("Time") then
					Gui.Time.Visible = TimeTextVisible
					if TimeValue then
						Gui.Time.Text = TimeValue
					end
				end
			end
		end

		-- Hook into existing Lock() + Unlock()
		local OriginalLock = Lock
		local OriginalUnlock = Unlock

		function Unlock()
			OriginalUnlock()
			SyncFloorLockGuis("Lock", Color3.fromRGB(255, 247, 0), false)
		end

		function Lock(Time)
			-- Lock the main base
			OriginalLock(Time)
			-- Immediately sync all floor GUIs
			SyncFloorLockGuis("Locked:", Color3.fromRGB(250, 0, 0), true, Numbers.Time(Time))

			-- Countdown loop for updating timer every second
			-- (read main LockGui.Time.Text each second and mirror it to floors so VIP +10 mid-lock stays synced)
			task.spawn(function()
				while BaseData.Locked do
					if not LockGui or not LockGui:FindFirstChild("Time") then break end
					local currentTimeText = LockGui.Time.Text
					SyncFloorLockGuis("Locked:", Color3.fromRGB(250, 0, 0), true, currentTimeText)
					if not BaseData.Locked then break end
					task.wait(1)
				end

				if not BaseData.Locked then
					SyncFloorLockGuis("Lock", Color3.fromRGB(255, 247, 0), false)
				end
			end)
		end
	end

	BaseData.Starter = true
	Lock(30)	

	local FriendsProximityPrompt = Insert.ProximityPrompt(Base.Friends)
	FriendsProximityPrompt.ActionText = BaseData.Allowed and "Disallow" or "Allow"
	FriendsProximityPrompt.HoldDuration = 1
	FriendsProximityPrompt.ObjectText = "Friends"

	SetProperties.Client(Player, FriendsProximityPrompt, {Enabled = true})

	local FriendsAttachment, FriendsGui, FriendsSurfaceGui = Insert.Friends(Base.Friends)

	FriendsSurfaceGui.Indicator.Image = BaseData.Allowed and "rbxassetid://97831093995551" or "rbxassetid://79702096050504"

	FriendsProximityPrompt.Triggered:Connect(function(TriggeringPlayer)
		if TriggeringPlayer ~= Player then return end

		BaseData.Allowed = not BaseData.Allowed
		FriendsProximityPrompt.ActionText = BaseData.Allowed and "Disallow" or "Allow"
		FriendsSurfaceGui.Indicator.Image = BaseData.Allowed and "rbxassetid://97831093995551" or "rbxassetid://79702096050504"

		NotificationEvent:FireClient(Player, string.format("%s friends!", BaseData.Allowed and "Allowed" or "Disallowed"), BaseData.Allowed)

		if not BaseData.Allowed and BaseData.Locked then
			for FriendPlayer in pairs(BaseData.AllowedFriends) do
				if FriendPlayer:IsDescendantOf(Players) then
					local UnlockedDoors = GetUnlockedDoors(Base, RebirthsValue.Value)
					for _, Door in ipairs(UnlockedDoors) do
						for _, Descendant in ipairs(Door:GetDescendants()) do
							if not Descendant:IsA("BasePart") then continue end
							SetProperties.Client(FriendPlayer, Descendant, {CanCollide = true})
						end
					end

					for _, Door in ipairs(GetUnlockedDoors(Base, RebirthsValue.Value)) do
						local ProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
						if ProximityPrompt then
							SetProperties.Client(FriendPlayer, ProximityPrompt, {Enabled = true})
						end
					end
				end
			end

			table.clear(BaseData.AllowedFriends)
			return
		end

		RefreshFriends()
		UpdateBase(Player)
	end)

	local MultiplierAttachment, MultiplierGui = Insert.Multiplier(Base.CollectZone)
	local CollectZoneGui = Insert.CollectZone(Base.CollectZone)

	MultiplierValue:GetPropertyChangedSignal("Value"):Connect(function()
		MultiplierGui.Multiplier.Text = string.format("x%.1f", MultiplierValue.Value):gsub("%.0+$", ""):gsub("(%.%d-)0+$", "%1")	
		UpdateMoneyPerSecondModule.Update(Player)
	end)

	local OwnerAttachment = Base.Owner:FindFirstChild("OwnerAttachment")
	local OwnerGui, OwnerSurfaceGui

	if OwnerAttachment then
		OwnerGui = OwnerAttachment:FindFirstChild("OwnerGui")
		OwnerSurfaceGui = Base.Owner:FindFirstChildWhichIsA("SurfaceGui", true)
	else
		OwnerGui, OwnerSurfaceGui = Insert.Owner(Base.Owner)
	end

	SetProperties.Client(Player, OwnerGui, {Enabled = true})

	if OwnerSurfaceGui and OwnerSurfaceGui:FindFirstChild("DisplayName") then
		OwnerSurfaceGui.DisplayName.Text = Player.Name .. "'s Base"
	end


	for _, FloorFolder in ipairs(Base.Floors:GetChildren()) do
		local Hitbox = FloorFolder:FindFirstChild("Hitbox")
		if Hitbox and Hitbox:IsA("BasePart") then
			local FloorNumber = tonumber(FloorFolder.Name:match("%d+"))
			if not FloorNumber then continue end

			local HitboxTouchedConnection = Hitbox.Touched:Connect(function(OtherPart)
				local TouchingPlayer = Players:GetPlayerFromCharacter(OtherPart.Parent)
				if not TouchingPlayer then return end

				PlayersInFloors[TouchingPlayer] = FloorNumber

				for _, Slot in ipairs(Base.Slots:GetChildren()) do
					local Configuration = Slot:FindFirstChild("Configuration")
					if not Configuration then continue end

					local ThingValue = Configuration:FindFirstChild("Thing")
					if not ThingValue or not ThingValue.Value then continue end

					local Rebirth = Configuration:FindFirstChild("Rebirth")
					if not Rebirth then continue end

					local SlotFloorNumber = GetSlotFloorNumber(Base, Rebirth.Value)
					if SlotFloorNumber == FloorNumber then
						local ProximityPrompt = ThingValue.Value:FindFirstChildWhichIsA("ProximityPrompt", true)
						if ProximityPrompt then
							SetProperties.Client(TouchingPlayer, ProximityPrompt, {Enabled = true})
						end
					end
				end
			end)

			local HitboxTouchEndedConnection = Hitbox.TouchEnded:Connect(function(OtherPart)
				local TouchingPlayer = Players:GetPlayerFromCharacter(OtherPart.Parent)
				if not TouchingPlayer then return end

				PlayersInFloors[TouchingPlayer] = FloorNumber

				if PlayersInFloors[TouchingPlayer] == FloorNumber then
					PlayersInFloors[TouchingPlayer] = nil

					for _, Slot in ipairs(Base.Slots:GetChildren()) do
						local Configuration = Slot:FindFirstChild("Configuration")
						if not Configuration then continue end

						local ThingValue = Configuration:FindFirstChild("Thing")
						if not ThingValue or not ThingValue.Value then continue end

						local Rebirth = Configuration:FindFirstChild("Rebirth")
						if not Rebirth then continue end

						local SlotFloorNumber = GetSlotFloorNumber(Base, Rebirth.Value)
						if SlotFloorNumber == FloorNumber then
							local ProximityPrompt = ThingValue.Value:FindFirstChildWhichIsA("ProximityPrompt", true)
							if ProximityPrompt then
								SetProperties.Client(TouchingPlayer, ProximityPrompt, {Enabled = false})
							end
						end
					end
				end
			end)

			table.insert(BasesConnections[Base], HitboxTouchedConnection)
			table.insert(BasesConnections[Base], HitboxTouchEndedConnection)
		end
	end

	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local Configuration = Slot:FindFirstChild("Configuration")
		if not Configuration then continue end

		local ThingValue = Configuration:FindFirstChild("Thing")
		if not ThingValue then continue end

		local ThingConnection = ThingValue:GetPropertyChangedSignal("Value"):Connect(function()
			local ThingInstance = ThingValue.Value
			if not ThingInstance then return end

			local Rebirth = Configuration:FindFirstChild("Rebirth")
			if not Rebirth then return end

			local SlotFloorNumber = GetSlotFloorNumber(Base, Rebirth.Value)
			if not SlotFloorNumber then return end

			local ProximityPrompt = ThingInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
			if not ProximityPrompt then return end

			for PlayerInFloor, FloorNumber in pairs(PlayersInFloors) do
				if FloorNumber == SlotFloorNumber then
					SetProperties.Client(PlayerInFloor, ProximityPrompt, {Enabled = true})
				end
			end

			UpdateMoneyPerSecondModule.Update(Player)
		end)

		table.insert(BasesConnections[Base], ThingConnection)
	end

	local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)
		PlayersInFloors[Player] = nil
	end)

	table.insert(BasesConnections[Base], PlayerRemovingConnection)

	LoadThings(Player)
	UpdateMoneyPerSecondModule.Update(Player)
end

local function ResetBase(Base)
	if not Base then return end

	if BasesConnections[Base] then
		for _, Connection in ipairs(BasesConnections[Base] or {}) do
			if Connection.Disconnect then
				Connection:Disconnect()
			end
		end

		BasesConnections[Base] = nil
	end

	if BasesData[Base] then
		BasesData[Base] = nil
	end

	local FriendsAttachment = Base.Friends:FindFirstChild("FriendsAttachment")
	if FriendsAttachment then FriendsAttachment:Destroy() end

	local FriendsSurfaceGui = Base.Friends:FindFirstChild("FriendsSurfaceGui")
	if FriendsSurfaceGui then FriendsSurfaceGui:Destroy() end

	local FriendsProximityPrompt = Base.Friends:FindFirstChild("ProximityPrompt")
	if FriendsProximityPrompt then FriendsProximityPrompt:Destroy() end

	local LockAttachment = Base.Lock:FindFirstChild("LockAttachment")
	if LockAttachment then LockAttachment:Destroy() end

	local LockAttachment2 = Base.Floors.Floor2.Lock:FindFirstChild("LockAttachment")
	if LockAttachment2 then LockAttachment2:Destroy() end

	local LockAttachment3 = Base.Floors.Floor3.Lock:FindFirstChild("LockAttachment")
	if LockAttachment3 then LockAttachment3:Destroy() end

	local MultiplierAttachment = Base.CollectZone:FindFirstChild("MultiplierAttachment")
	if MultiplierAttachment then MultiplierAttachment:Destroy() end

	local CollectZoneGui = Base.CollectZone:FindFirstChild("CollectZoneGui")
	if CollectZoneGui then CollectZoneGui:Destroy() end

	local OwnerGui = Base.Owner:FindFirstChild("OwnerGui")
	if OwnerGui then OwnerGui:Destroy() end

	local OwnerSurfaceGui = Base.Owner:FindFirstChild("OwnerSurfaceGui")
	if OwnerSurfaceGui then OwnerSurfaceGui:Destroy() end

	local RebirthsAmount = 0
	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local Configuration = Slot:FindFirstChild("Configuration")
		if not Configuration then continue end

		local Thing = Configuration:FindFirstChild("Thing") and Configuration.Thing.Value
		if Thing then
			Thing:Destroy()
		end

		local CollectAttachment = Slot:FindFirstChild("Collect") and Slot.Collect:FindFirstChild("CollectAttachment")
		if CollectAttachment then
			CollectAttachment:Destroy()
		end

		Configuration.Thing.Value = nil
		Configuration.Occupied.Value = false

		local Rebirth = Configuration:FindFirstChild("Rebirth")
		if not Rebirth then continue end

		local IsVisible = (RebirthsAmount >= Rebirth.Value)

		for _, Descendant in ipairs(Slot:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				if Descendant.Name == "Spawn" or Descendant.Name == "Collect" then
					Descendant.Transparency = 1
					Descendant.CanCollide = false
				else
					Descendant.Transparency = IsVisible and 0 or 1
					Descendant.CanCollide = IsVisible
				end
			end
		end
	end

	-- Update MoneyPerSecond after clearing all things
	local Player = Base.Configuration.Player.Value
	if Player then
		UpdateMoneyPerSecondModule.Update(Player)
	end

	local UnlockedFloors = GetUnlockedFloors(Base, RebirthsAmount)
	local UnlockedSet = {}
	for _, Floor in ipairs(UnlockedFloors) do
		UnlockedSet[Floor] = true
	end	

	for _, Floor in ipairs(Base.Floors:GetChildren()) do
		local IsUnlocked = UnlockedSet[Floor] == true

		for _, Child in ipairs(Floor:GetChildren()) do
			if Child.Name == "Hitbox" then
				continue
			elseif Child.Name == "Doors" then
				for _, Door in ipairs(Child:GetChildren()) do
					local DoorProximityPrompt = Door.Hitbox:FindFirstChild("ProximityPrompt")
					if DoorProximityPrompt then DoorProximityPrompt:Destroy() end
				end
			else
				for _, Descendant in ipairs(Child:GetDescendants()) do
					if Descendant:IsA("BasePart") then
						Descendant.Transparency = IsUnlocked and 0 or 1
						Descendant.CanCollide = IsUnlocked
					end
				end
			end
		end

		if not IsUnlocked then
			for _, Descendant in ipairs(Floor:GetDescendants()) do
				if Descendant:IsA("BasePart") and Descendant.Name ~= "Hitbox" then
					Descendant.Transparency = 1
					Descendant.CanCollide = false
				end
			end
		end
	end

	local UnlockedDoors = GetUnlockedDoors(Base, RebirthsAmount)

	for _, Door in ipairs(UnlockedDoors) do
		for _, Descendant in ipairs(Door:GetDescendants()) do
			if not Descendant:IsA("BasePart") then continue end

			Descendant.Transparency = 1
			Descendant.CanCollide = false
		end
	end	

	local OwnerPart = Base:FindFirstChild("Owner")
	if OwnerPart then
		local OwnerGui = OwnerPart:FindFirstChild("OwnerGui")
		local OwnerSurfaceGui

		if not OwnerGui then
			OwnerGui, OwnerSurfaceGui = Insert.Owner(OwnerPart)
		else
			OwnerSurfaceGui = OwnerPart:FindFirstChildWhichIsA("SurfaceGui", true)
		end

		if OwnerSurfaceGui and OwnerSurfaceGui:FindFirstChild("DisplayName") then
			OwnerSurfaceGui.DisplayName.Text = "Empty Base"
		end
	end
	
	Base.Configuration.Player.Value = nil
end

task.spawn(function()
	for _, Base in ipairs(Bases:GetChildren()) do
		task.spawn(ResetBase, Base)
	end
end)

task.spawn(Things.Initialize)

Players.PlayerAdded:Connect(function(Player)
	local LeaderstatsFolder = Instance.new("Folder")
	LeaderstatsFolder.Name = "leaderstats"
	LeaderstatsFolder.Parent = Player

	local StealsValue = Instance.new("IntValue")
	StealsValue.Name = "Steals"
	StealsValue.Value = 0
	StealsValue.Parent = LeaderstatsFolder

	local RebirthsValue = Instance.new("IntValue")
	RebirthsValue.Name = "Rebirths"
	RebirthsValue.Value = 0
	RebirthsValue.Parent = LeaderstatsFolder

	local MoneyValue = Instance.new("IntValue")
	MoneyValue.Name = "Money"
	MoneyValue.Value = 0
	MoneyValue.Parent = LeaderstatsFolder

	local Configuration = Instance.new("Configuration")
	Configuration.Name = "Configuration"
	Configuration.Parent = Player

	local BaseValue = Instance.new("ObjectValue")
	BaseValue.Name = "Base"
	BaseValue.Value = nil
	BaseValue.Parent = Configuration

	local FriendsValue = Instance.new("NumberValue")
	FriendsValue.Name = "Friends"
	FriendsValue.Value = 0
	FriendsValue.Parent = Configuration

	local MultiplierValue = Instance.new("NumberValue")
	MultiplierValue.Name = "Multiplier"
	MultiplierValue.Value = 1
	MultiplierValue.Parent = Configuration

	local IndexMultiplierValue = Instance.new("NumberValue")
	IndexMultiplierValue.Name = "IndexMultiplier"
	IndexMultiplierValue.Value = 0
	IndexMultiplierValue.Parent = Configuration

	local MoneyPerSecondValue = Instance.new("NumberValue")
	MoneyPerSecondValue.Name = "MoneyPerSecond"
	MoneyPerSecondValue.Value = 0
	MoneyPerSecondValue.Parent = Configuration
	
	task.spawn(SetBase, Player)

	local UserId = Player.UserId

	if UserId <= 0 then
		MoneyValue.Value = 550
		return 
	end

	local UserIdString = tostring(UserId)

	local StealsSavedData, RebirthsSavedData, MoneySavedData
	local Success, Error = pcall(function()
		StealsSavedData = StealsOrderedDataStore:GetAsync(UserIdString)
		RebirthsSavedData = RebirthsOrderedDataStore:GetAsync(UserIdString)
		MoneySavedData = MoneyOrderedDataStore:GetAsync(UserIdString)
	end)

	if Success then
		if StealsSavedData then StealsValue.Value = StealsSavedData end
		if RebirthsSavedData then RebirthsValue.Value = RebirthsSavedData end
		if MoneySavedData then
			MoneyValue.Value = MoneySavedData
		else
			MoneyValue.Value = 550
		end
	else
		Player:Kick("Data failed to load. Please rejoin.")
		return
	end

	FriendsValue:GetPropertyChangedSignal("Value"):Connect(function()
		UpdateMultiplier(Player)
		UpdateMoneyPerSecondModule.Update(Player)
	end)

	RebirthsValue:GetPropertyChangedSignal("Value"):Connect(function()
		UpdateMultiplier(Player)
		UpdateBase(Player)
		UpdateMoneyPerSecondModule.Update(Player)
	end)

	IndexMultiplierValue:GetPropertyChangedSignal("Value"):Connect(function()
		UpdateMultiplier(Player)
		UpdateMoneyPerSecondModule.Update(Player)
	end)

	UpdateFriends()
	UpdateMultiplier(Player)
	UpdateBase(Player)
	RefreshFriends()
	UpdateMoneyPerSecondModule.Update(Player)

	Player.CharacterAdded:Once(function()
		UpdateBase(Player)
		RefreshFriends()
	end)
end)

-- PlayerRemoving
Players.PlayerRemoving:Connect(function(Player)
	local UserId = Player.UserId
	if UserId < 1 then return end

	local UserIdString = tostring(UserId)

	-- Save things safely
	local success, err = pcall(SaveThings, Player)
	if not success then
		warn("Failed to save things for "..Player.Name..": "..tostring(err))
	end

	-- Retry queue processing (if SaveThings failed, you can implement it here)
	task.wait(0.25) -- slightly longer wait to ensure UpdateAsync completes

	UpdateFriends()
	RefreshFriends()

	local LeaderstatsFolder = Player:FindFirstChild("leaderstats")
	if LeaderstatsFolder then
		for _, DataStorePair in ipairs({
			{Store = StealsOrderedDataStore, Value = LeaderstatsFolder.Steals.Value},
			{Store = RebirthsOrderedDataStore, Value = LeaderstatsFolder.Rebirths.Value},
			{Store = MoneyOrderedDataStore, Value = LeaderstatsFolder.Money.Value}
			}) do
			local success = false
			for i = 1, 3 do
				success = pcall(function()
					DataStorePair.Store:SetAsync(UserIdString, DataStorePair.Value)
				end)
				if success then break end
				task.wait(1)
			end
		end
	end

	local Configuration = Player:FindFirstChild("Configuration")
	local Base = Configuration and Configuration:FindFirstChild("Base") and Configuration.Base.Value
	if Base then
		ResetBase(Base)
	end
end)

game:BindToClose(function()
	for _, Player in ipairs(Players:GetPlayers()) do
		local UserId = Player.UserId
		if UserId < 1 then continue end

		local UserIdString = tostring(UserId)
		local Configuration = Player:FindFirstChild("Configuration")
		local Base = Configuration and Configuration:FindFirstChild("Base") and Configuration.Base.Value

		if Base then
			local success, err = pcall(SaveThings, Player)
			if not success then
				warn("Failed to save things for "..Player.Name..": "..tostring(err))
			end
			task.wait(0.25)
		end

		local LeaderstatsFolder = Player:FindFirstChild("leaderstats")
		if LeaderstatsFolder then
			for _, DataStorePair in ipairs({
				{Store = StealsOrderedDataStore, Value = LeaderstatsFolder.Steals.Value},
				{Store = RebirthsOrderedDataStore, Value = LeaderstatsFolder.Rebirths.Value},
				{Store = MoneyOrderedDataStore, Value = LeaderstatsFolder.Money.Value}
				}) do
				local success = false
				for i = 1, 3 do
					success = pcall(function()
						DataStorePair.Store:SetAsync(UserIdString, DataStorePair.Value)
					end)
					if success then break end
					task.wait(1)
				end
			end
		end

		if Base then
			ResetBase(Base)
		end
	end
end)

task.spawn(function()
	while true do
		RefreshFriends()
		task.wait(3)
	end
end)