local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local StealsDS = DataStoreService:GetOrderedDataStore("Steals")
local RebirthsDS = DataStoreService:GetOrderedDataStore("Rebirths")
local MoneyDS = DataStoreService:GetOrderedDataStore("Money")
local ThingsDS = DataStoreService:GetDataStore("Things")
local PlayerThingsDataStore = DataStoreService:GetDataStore("PlayersThings")

local userId = 123

Players.PlayerAdded:Connect(function(player)
	if player.UserId == userId then
		pcall(function()
			StealsDS:RemoveAsync(userId)
			RebirthsDS:RemoveAsync(userId)
			MoneyDS:RemoveAsync(userId)
			ThingsDS:RemoveAsync(userId)
			PlayerThingsDataStore:RemoveAsync(userId)
		end)

		local leaderstats = player:WaitForChild("leaderstats")
		if leaderstats:FindFirstChild("Rebirths") then
			leaderstats.Rebirths.Value = 0
		end
		if leaderstats:FindFirstChild("Money") then
			leaderstats.Money.Value = 0
		end
		if leaderstats:FindFirstChild("Steal") then
			leaderstats.Steal.Value = 0
		end

		local config = player:FindFirstChild("Configuration")
		if config then
			if config:FindFirstChild("Base") then
				config.Base.Value = nil
			end
			if config:FindFirstChild("Multiplier") then
				config.Multiplier.Value = 1
			end
		end

		print("Player data reset in memory and DataStore.")
	end
end)
