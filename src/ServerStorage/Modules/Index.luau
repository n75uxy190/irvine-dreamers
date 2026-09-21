local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Mutations = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Mutations"))
local Things = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Things"))

local PlayerThingsDataStore = DataStoreService:GetDataStore("PlayersThings")

local GetPlayerThingsFunction = ReplicatedStorage.Remotes.Functions:WaitForChild("GetPlayerThings")

local PlayersThingsData = {}

local function CreateEmptyMatrix()
	local Data = {}
	for Mutation, _ in pairs(Mutations) do
		Data[Mutation] = {}
		for Name, _ in pairs(Things.Things) do
			Data[Mutation][Name] = false
		end
	end
	return Data
end

local function MergeWithTemplate(Loaded)
	for Mutation, ThingStatusTable in pairs(CreateEmptyMatrix()) do
		Loaded[Mutation] = Loaded[Mutation] or {}
		for Name, _ in pairs(ThingStatusTable) do
			if Loaded[Mutation][Name] == nil then
				Loaded[Mutation][Name] = false
			end
		end
	end
	return Loaded
end

local function UpdateIndexMultiplier(Player)
	local Configuration = Player:WaitForChild("Configuration")
	local IndexMultiplierValue = Configuration:WaitForChild("IndexMultiplier")

	local UserId = Player.UserId
	local Data = PlayersThingsData[UserId]
	if not Data then return end

	local IndexMultiplier = 0

	for Mutation, MutationConfiguration in pairs(Mutations) do
		local AllOwned = true
		for Name, _ in pairs(Things.Things) do
			if Data[Mutation] and Data[Mutation][Name] == false then
				AllOwned = false
				break
			end
		end
		if AllOwned and MutationConfiguration.IndexMultiplier then
			IndexMultiplier += MutationConfiguration.IndexMultiplier
		end
	end

	IndexMultiplierValue.Value = IndexMultiplier
end

Players.PlayerAdded:Connect(function(Player)
	local UserId = Player.UserId
	local UserIdString = tostring(UserId)

	local Success, Data = pcall(function()
		return PlayerThingsDataStore:GetAsync(UserIdString)
	end)

	if not Success or type(Data) ~= "table" then
		Data = CreateEmptyMatrix()
	else
		Data = MergeWithTemplate(Data)
	end

	PlayersThingsData[UserId] = Data
	UpdateIndexMultiplier(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	local UserId = Player.UserId
	local UserIdString = tostring(UserId)

	local Data = PlayersThingsData[UserId]
	if type(Data) == "table" then
		pcall(function()
			PlayerThingsDataStore:SetAsync(UserIdString, Data)
		end)
	end

	PlayersThingsData[UserId] = nil
end)

GetPlayerThingsFunction.OnServerInvoke = function(Player)
	local UserId = Player.UserId
	local Data = PlayersThingsData[UserId]
	if type(Data) == "table" then
		return Data
	else
		return CreateEmptyMatrix()
	end
end

local Index = {}

function Index.PlayerThing(Player, Name, Mutation)
	if not Player or not Name or not Mutation then return end

	local UserId = Player.UserId
	local UserIdString = tostring(UserId)

	local Data = PlayersThingsData[UserId]
	if not Data then
		local Success, Loaded = pcall(function()
			return PlayerThingsDataStore:GetAsync(UserIdString)
		end)
		if not Success or type(Loaded) ~= "table" then
			Data = CreateEmptyMatrix()
		else
			Data = MergeWithTemplate(Loaded)
		end
		PlayersThingsData[UserId] = Data
	end

	if Data[Mutation] and Data[Mutation][Name] ~= nil then
		Data[Mutation][Name] = true
	end

	pcall(function()
		PlayerThingsDataStore:SetAsync(UserIdString, Data)
	end)

	UpdateIndexMultiplier(Player)
end

return Index