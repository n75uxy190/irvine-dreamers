--// Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--// Dependencies
local ChestSystem = ReplicatedStorage:WaitForChild("ChestSystem")
local Settings = require(ChestSystem:WaitForChild("Modules"):WaitForChild("Settings"))
local ToolsFolder = ChestSystem:WaitForChild("Tools")
local Remotes = ChestSystem:WaitForChild("Remotes")
local CheckClaimRemote = Remotes:WaitForChild("CheckClaim")
local ClaimFeedbackRemote = Remotes:WaitForChild("ClaimFeedback")
local GetInitialStateRemote = Remotes:WaitForChild("GetInitialState")

--// DataStores
local ClaimDataStore = DataStoreService:GetDataStore("GroupChestClaims")
local PlayTimeDataStore = DataStoreService:GetDataStore("PlayerPlayTime")

--// Variables
local playerPlayTimeCache = {}
local touchCooldowns = {}

--// DataStore Helper Functions
local function getDataStoreAsync(dataStore, key, retries)
	retries = retries or 0
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success then
		return data
	elseif retries < Settings.DataStore.MaxRetries then
		task.wait(Settings.DataStore.RetryDelay)
		return getDataStoreAsync(dataStore, key, retries + 1)
	else
		warn("DataStore failed to retrieve key: " .. key .. " after retries.")
		return nil
	end
end

local function setDataStoreAsync(dataStore, key, value, retries)
	retries = retries or 0
	local success, err = pcall(function()
		dataStore:SetAsync(key, value)
	end)

	if success then
		return true
	elseif retries < Settings.DataStore.MaxRetries then
		task.wait(Settings.DataStore.RetryDelay)
		return setDataStoreAsync(dataStore, key, value, retries + 1)
	else
		warn("DataStore failed to save key: " .. key .. " after retries: " .. tostring(err))
		return false
	end
end

--// Player Tracking & Data Management
Players.PlayerAdded:Connect(function(player)
	local savedPlaytime = getDataStoreAsync(PlayTimeDataStore, player.UserId) or 0
	playerPlayTimeCache[player.UserId] = {
		StartTime = os.time(),
		TotalTime = savedPlaytime,
	}
end)

Players.PlayerRemoving:Connect(function(player)
	if playerPlayTimeCache[player.UserId] then
		local timeInSession = os.time() - playerPlayTimeCache[player.UserId].StartTime
		local newTotalPlaytime = playerPlayTimeCache[player.UserId].TotalTime + timeInSession

		setDataStoreAsync(PlayTimeDataStore, player.UserId, newTotalPlaytime)

		playerPlayTimeCache[player.UserId] = nil
	end

	if touchCooldowns[player.UserId] then
		touchCooldowns[player.UserId] = nil
	end
end)

--// Claim Logic
local function giveCurrencyReward(player)
	local currencyName = Settings.Rewards.Currency.Name
	local currencyAmount = Settings.Rewards.Currency.Amount

	if not currencyName or currencyAmount <= 0 then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local currencyStat = leaderstats and leaderstats:FindFirstChild(currencyName)

	if currencyStat then
		currencyStat.Value = currencyStat.Value + currencyAmount
		return {currency = currencyAmount}
	else
		warn("Failed to give currency reward. Leaderstat '" .. currencyName .. "' not found.")
		return nil
	end
end

local function giveToolReward(player, rewardsTable)
	if not Settings.Rewards.Tool.Paths or #Settings.Rewards.Tool.Paths == 0 then return end

	for _, toolName in pairs(Settings.Rewards.Tool.Paths) do
		local tool = ToolsFolder:FindFirstChild(toolName)
		if tool and tool:IsA("Tool") then
			local toolClone = tool:Clone()
			toolClone.Parent = player.Backpack
			table.insert(rewardsTable, {tool = toolName})
		else
			warn("Tool not found or invalid: " .. toolName)
		end
	end

	return rewardsTable
end

CheckClaimRemote.OnServerInvoke = function(player, chestName)
	if typeof(chestName) ~= "string" or not workspace.Chests:FindFirstChild(chestName) then
		return {success = false, message = "Invalid chest"}
	end

	local touchData = touchCooldowns[player.UserId] or {}
	local lastTouch = touchData[chestName] or 0
	if os.time() - lastTouch < Settings.UI.TouchCooldown then
		touchData[chestName] = os.time()
		touchCooldowns[player.UserId] = touchData
		return {success = false, timeLeft = 0, state = "OnCooldown"}
	end
	touchData[chestName] = os.time()
	touchCooldowns[player.UserId] = touchData

	if Settings.GroupId and not player:IsInGroup(Settings.GroupId) then
		return {success = false, message = "Join Group To Claim"}
	end

	local currentMode = Settings.Claim.Mode
	if currentMode == "Minutely" then
		local playerSessionData = playerPlayTimeCache[player.UserId]
		if not playerSessionData then
			local savedPlaytime = getDataStoreAsync(PlayTimeDataStore, player.UserId) or 0
			playerSessionData = {
				StartTime = os.time(),
				TotalTime = savedPlaytime,
			}
			playerPlayTimeCache[player.UserId] = playerSessionData
		end

		local totalPlaytime = playerSessionData.TotalTime + (os.time() - playerSessionData.StartTime)
		if totalPlaytime < Settings.Claim.MinPlayTime then
			local timeLeft = Settings.Claim.MinPlayTime - totalPlaytime
			return {success = false, message = "Stay in game longer to claim", timeLeft = timeLeft, state = "Playing"}
		end
	end

	local key = "Player_" .. player.UserId .. "_Claim"
	local claimData = getDataStoreAsync(ClaimDataStore, key) or {}

	local modeData = claimData[currentMode] or {CooldownEnd = 0}

	local currentTime = os.time()
	if currentTime < modeData.CooldownEnd then
		local timeLeft = modeData.CooldownEnd - currentTime
		return {success = false, message = "Come back later!", timeLeft = timeLeft, state = "OnCooldown", mode = currentMode}
	end

	local rewardsGiven = {}
	local cooldownDuration = 0

	if currentMode == "Daily" then
		cooldownDuration = Settings.Claim.DailyResetTime
	elseif currentMode == "Minutely" then
		cooldownDuration = Settings.Claim.MinutelyResetTime
	end

	modeData.CooldownEnd = currentTime + cooldownDuration
	claimData[currentMode] = modeData

	local claimSuccess = setDataStoreAsync(ClaimDataStore, key, claimData)
	if not claimSuccess then
		return {success = false, message = "Failed to process claim, try again"}
	end

	local currencyReward = giveCurrencyReward(player)
	if currencyReward then
		rewardsGiven.currency = currencyReward.currency
	end

	giveToolReward(player, rewardsGiven)

	ClaimFeedbackRemote:FireClient(player, {success = true, rewards = rewardsGiven, chestName = chestName, timeLeft = cooldownDuration, mode = currentMode})

	return {success = true, message = "Claimed successfully!", timeLeft = cooldownDuration, state = "OnCooldown", mode = currentMode}
end

GetInitialStateRemote.OnServerInvoke = function(player)
	if not playerPlayTimeCache[player.UserId] then
		return {inGroup = true, state = "Loading"}
	end

	local isInGroup = Settings.GroupId and player:IsInGroup(Settings.GroupId)
	if not isInGroup then
		return {inGroup = false, state = "JoinGroup"}
	end

	local currentMode = Settings.Claim.Mode
	if currentMode == "Minutely" then
		local playerSessionData = playerPlayTimeCache[player.UserId]
		local totalPlaytime = playerSessionData.TotalTime + (os.time() - playerSessionData.StartTime)
		if totalPlaytime < Settings.Claim.MinPlayTime then
			local timeLeft = Settings.Claim.MinPlayTime - totalPlaytime
			return {inGroup = true, state = "Playing", timeLeft = timeLeft}
		end
	end

	local key = "Player_" .. player.UserId .. "_Claim"
	local claimData = getDataStoreAsync(ClaimDataStore, key) or {}

	local modeData = claimData[currentMode] or {CooldownEnd = 0}

	local currentTime = os.time()
	if currentTime < modeData.CooldownEnd then
		local timeLeft = modeData.CooldownEnd - currentTime
		return {inGroup = true, state = "OnCooldown", timeLeft = timeLeft, mode = currentMode}
	end

	return {inGroup = true, state = "ReadyToClaim"}
end
