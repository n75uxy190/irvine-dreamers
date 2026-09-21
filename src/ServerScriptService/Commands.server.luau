local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local Commands = require(ServerStorage.Configuration.Modules:WaitForChild("Commands"))

local Events = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Events"))
local ServerLuck = require(ReplicatedStorage.Configuration.Modules:WaitForChild("ServerLuck"))
local Traits = require(ServerStorage.Configuration.Modules:WaitForChild("Traits"))

local StealsOrderedDataStore = DataStoreService:GetOrderedDataStore("Steals")
local RebirthsOrderedDataStore = DataStoreService:GetOrderedDataStore("Rebirths")
local MoneyOrderedDataStore = DataStoreService:GetOrderedDataStore("Money")

local AnnouncementEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Announcement")

local Prefix = Commands.Prefix
if not Prefix then return end

local function SplitArguments(Text)
	local Arguments = {}
	local Position = 1

	while Position <= #Text do
		local Character = Text:sub(Position, Position)

		if Character == '"' then
			local ClosingPosition = Text:find('"', Position + 1)
			if not ClosingPosition then break end

			table.insert(Arguments, Text:sub(Position + 1, ClosingPosition - 1))
			Position = ClosingPosition + 1

		elseif Character == "'" then
			local ClosingPosition = Text:find("'", Position + 1)
			if not ClosingPosition then break end

			table.insert(Arguments, Text:sub(Position + 1, ClosingPosition - 1))
			Position = ClosingPosition + 1

		elseif Character == " " then
			Position = Position + 1

		else
			local NextSpace = Text:find(" ", Position) or (#Text + 1)
			table.insert(Arguments, Text:sub(Position, NextSpace - 1))
			Position = NextSpace
		end
	end

	return Arguments
end

Players.PlayerAdded:Connect(function(Player)
	local IsWhitelisted

	for _, UserId in ipairs(Commands.Whitelist) do
		if UserId == Player.UserId then
			IsWhitelisted = true
		end
	end

	if not IsWhitelisted then return end

	Player.Chatted:Connect(function(Message)
		if Message:sub(1, #Prefix) ~= Prefix then return end

		local MessageWithoutPrefix = Message:sub(#Prefix + 1)
		local Arguments = SplitArguments(MessageWithoutPrefix)

		local Command = Arguments[1] and Arguments[1]:lower()
		if not Command then return end

		if (Command == "thing" or Command == "globalthing") and Arguments[2] and Arguments[3] and Arguments[4] then
			local Amount = tonumber(Arguments[2])
			local AppliedTraits = Arguments[3]
			local Mutation = Arguments[4]
			local Name = Arguments[5]

			if not Amount or not Mutation or not Name then return end

			local ValidTraits
			if AppliedTraits and AppliedTraits ~= "nil" then
				ValidTraits = {}

				for TraitName in string.gmatch(AppliedTraits, "([^,]+)") do
					TraitName = TraitName:gsub("^%s*(.-)%s*$", "%1")

					table.insert(ValidTraits, TraitName)
				end
			end

			if Command == "thing" then
				Things.Queue(Amount, Name, ValidTraits, Mutation)
			else
				MessagingService:PublishAsync("GlobalThing", {
					Amount = Amount,
					Name = Name,
					Traits = ValidTraits,
					Mutation = Mutation,
				})
			end
		elseif (Command == "trait" or Command == "globaltrait") and Arguments[2] and Arguments[3] then
			local TraitNameInput = Arguments[2]
			local ActiveInput = Arguments[3]:lower()
			local FoundTrait = nil

			for TraitName in pairs(Traits) do
				if TraitName:lower() == TraitNameInput:lower() then
					FoundTrait = TraitName
					break
				end
			end

			if not FoundTrait then return end

			local Active = (ActiveInput == "true")

			if Command == "trait" then
				Things.Trait(FoundTrait, Active)
			else
				MessagingService:PublishAsync("GlobalTrait", {
					Trait = FoundTrait,
					Active = Active,
				})
			end
		elseif (Command == "event" or Command == "globalevent") and Arguments[2] then
			local Event = Arguments[2]
			local Time = Arguments[3] and tonumber(Arguments[3]) or nil

			for EventKey in pairs(Events) do
				if EventKey:lower() == tostring(Event):lower() then
					Event = EventKey
				end
			end

			if not Events[Event] then return end

			if Command == "event" then
				Things.Event(Event, Time)
			else
				MessagingService:PublishAsync("GlobalEvent", {Event = Event, Time = Time})
			end
		elseif (Command == "serverluck" or Command == "globalserverluck") and Arguments[2] then
			local LuckValue = tonumber(Arguments[2])
			if not LuckValue then return end

			local TimeValue = Arguments[3]

			if Command == "serverluck" then
				Things.ServerLuck(LuckValue, TimeValue)
			else
				MessagingService:PublishAsync("GlobalServerLuck", {
					Luck = LuckValue,
					Time = TimeValue,
				})
			end
		elseif Command == "stopserverluck" or Command == "stopglobalserverluck" then
			if Command == "stopserverluck" then
				Things.ServerLuck(1, 0)
			else
				MessagingService:PublishAsync("GlobalServerLuck", {Luck = 1, Time = 0})
			end
		elseif Command == "leaderstat" and Arguments[2] and Arguments[3] and Arguments[4] then
			local Username = Arguments[2]
			local LeaderstatName = Arguments[3]:lower()
			local Value = tonumber(Arguments[4])

			local Success, UserId = pcall(function()
				return Players:GetUserIdFromNameAsync(Username)
			end)

			if Success and UserId then
				MessagingService:PublishAsync("Leaderstat", {
					UserId = UserId,
					Leaderstat = LeaderstatName,
					Value = Value,
				})

				local DataStore

				if LeaderstatName == "steals" then
					DataStore = StealsOrderedDataStore
				elseif LeaderstatName == "rebirths" then
					DataStore = RebirthsOrderedDataStore
				elseif LeaderstatName == "money" then
					DataStore = MoneyOrderedDataStore
				else
					return
				end

				pcall(function()
					DataStore:SetAsync(tostring(UserId), Value)
				end)
			end
		elseif Command == "announcement" or Command == "globalannouncement" then
			local AnnouncementText = MessageWithoutPrefix:sub(#Command + 2)
			if AnnouncementText and AnnouncementText ~= "" then
				if Command == "announcement" then
					AnnouncementEvent:FireAllClients(AnnouncementText)
				else
					MessagingService:PublishAsync("GlobalAnnouncement", AnnouncementText)
				end
			end
		end
	end)
end)

MessagingService:SubscribeAsync("GlobalThing", function(Message)
	local Data = Message.Data

	if typeof(Data) ~= "table" then return end

	local Amount = Data.Amount
	local Name = Data.Name
	local AppliedList = Data.Traits
	local Mutation = Data.Mutation

	if Amount and Name and Mutation then
		Things.Queue(Amount, Name, AppliedList, Mutation)
	end
end)

MessagingService:SubscribeAsync("GlobalTrait", function(Message)
	local Data = Message.Data

	if typeof(Data) ~= "table" then return end

	local Trait = Data.Trait
	local Active = Data.Active

	if Trait and type(Active) == "boolean" then
		Things.Trait(Trait, Active)
	end
end)

MessagingService:SubscribeAsync("GlobalEvent", function(Message)
	local Data = Message.Data
	if typeof(Data) ~= "table" then return end

	local Event = Data.Event
	local Time = tonumber(Data.Time)

	if not Event then return end

	Things.Event(Event, Time)
end)

MessagingService:SubscribeAsync("GlobalServerLuck", function(Message)
	local Data = Message.Data

	if typeof(Data) ~= "table" then return end

	local LuckValue = tonumber(Data.Luck)
	local TimeValue = Data.Time

	if LuckValue then
		Things.ServerLuck(LuckValue, TimeValue)
	end
end)

MessagingService:SubscribeAsync("Leaderstat", function(Message)
	local Data = Message.Data

	if typeof(Data) ~= "table" then return end

	local UserId = Data.UserId
	local LeaderstatName = Data.Leaderstat
	local Value = Data.Value

	if UserId and LeaderstatName and Value then
		for _, Player in ipairs(Players:GetPlayers()) do
			if Player.UserId == UserId then
				local Leaderstats = Player:FindFirstChild("leaderstats")
				if Leaderstats then
					for _, Child in ipairs(Leaderstats:GetChildren()) do
						if Child.Name:lower() == LeaderstatName and Child:IsA("IntValue") then
							Child.Value = Value
							break
						end
					end
				end
			end
		end
	end
end)

MessagingService:SubscribeAsync("GlobalAnnouncement", function(Message)
	local AnnouncementText = Message.Data

	if not AnnouncementText or AnnouncementText == "" then return end
	if typeof(AnnouncementText) ~= "string" then return end

	AnnouncementEvent:FireAllClients(AnnouncementText)
end)