local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local AssetIds = require(ReplicatedStorage.Configuration.Modules:WaitForChild("AssetIds"))

local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local ServerLuck = require(ReplicatedStorage.Configuration.Modules:WaitForChild("ServerLuck"))

local ServerLuckEvent = ReplicatedStorage.Remotes.Events:WaitForChild("ServerLuck")
local MoneyDevProductEvent = ReplicatedStorage.Remotes.Events:WaitForChild("MoneyDevProduct")

-- ServerLuckState folder
local ServerLuckState = ReplicatedStorage:WaitForChild("ServerLuckState")
local LuckValue = ServerLuckState:WaitForChild("Luck")
local LuckTimeValue = ServerLuckState:WaitForChild("LuckTime")

-- Dev Products configuration
local DeveloperProducts = {
	[AssetIds.DeveloperProducts.Money10k] = 10000,
	[AssetIds.DeveloperProducts.Money50k] = 50000,
	[AssetIds.DeveloperProducts.Money250k] = 250000,
	[AssetIds.DeveloperProducts.Money500k] = 500000,
	[AssetIds.DeveloperProducts.Money1m500k] = 1500000,
}

ServerLuckEvent.OnServerEvent:Connect(function(Player, Luck)
	Things.ServerLuck(Luck)
end)

MarketplaceService.ProcessReceipt = function(ReceiptInfo)
	local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
	if not Player then 
		return Enum.ProductPurchaseDecision.NotProcessedYet 
	end

	-- 1️⃣ Server Luck purchase
	for Luck, Configuration in pairs(ServerLuck) do
		if Configuration.DeveloperProductId == ReceiptInfo.ProductId then
			Things.ServerLuck(Luck)

			-- Ensure we always send an absolute timestamp
			if Things.LuckTime then
				ServerLuckEvent:FireAllClients(Things.Luck, Things.LuckTime)
			end

			-- Update ServerLuckState
			LuckValue.Value = Things.Luck
			LuckTimeValue.Value = Things.LuckTime

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- 2️⃣ Money purchases
	local moneyToAdd = DeveloperProducts[ReceiptInfo.ProductId]
	if moneyToAdd then
		local leaderstats = Player:FindFirstChild("leaderstats")
		if leaderstats then
			local money = leaderstats:FindFirstChild("Money")
			if money and money:IsA("IntValue") then
				money.Value += moneyToAdd
			end
		end

		MoneyDevProductEvent:FireClient(Player, moneyToAdd)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 3️⃣ Donation logic (unchanged)
	if _G.DonationsDS and _G.refreshLeaderboard then
		local DonationsDS = _G.DonationsDS
		local refreshLeaderboard = _G.refreshLeaderboard

		local productDonations = {
			[AssetIds.DeveloperProducts.DonationBoard5] = 5,
			[AssetIds.DeveloperProducts.DonationBoard10] = 10,
			[AssetIds.DeveloperProducts.DonationBoard25] = 25,
			[AssetIds.DeveloperProducts.DonationBoard50] = 50,
			[AssetIds.DeveloperProducts.DonationBoard100] = 100,
			[AssetIds.DeveloperProducts.DonationBoard250] = 250,
			[AssetIds.DeveloperProducts.DonationBoard500] = 500,
			[AssetIds.DeveloperProducts.DonationBoard1k] = 1000,
			[AssetIds.DeveloperProducts.DonationBoard5k] = 5000,
			[AssetIds.DeveloperProducts.DonationBoard10k] = 10000,
			[AssetIds.DeveloperProducts.DonationBoard25k] = 25000,
			[AssetIds.DeveloperProducts.DonationBoard50k] = 50000,
			[AssetIds.DeveloperProducts.DonationBoard100k] = 100000,
			[AssetIds.DeveloperProducts.DonationBoard250k] = 250000,
			[AssetIds.DeveloperProducts.DonationBoard500k] = 500000,
			[AssetIds.DeveloperProducts.DonationBoard1m] = 1000000,
		}

		local donationAmount = productDonations[ReceiptInfo.ProductId]
		if donationAmount then
			local success, currentDonated = pcall(function()
				return DonationsDS:GetAsync(tostring(ReceiptInfo.PlayerId)) or 0
			end)

			if success then
				local newTotal = currentDonated + donationAmount
				pcall(function()
					DonationsDS:SetAsync(tostring(ReceiptInfo.PlayerId), newTotal)
				end)
			end

			if refreshLeaderboard then
				refreshLeaderboard()
			end
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(function(Player)
	if LuckTimeValue.Value <= workspace:GetServerTimeNow() then
		LuckValue.Value = 1
		LuckTimeValue.Value = 0
	end

	ServerLuckEvent:FireClient(Player, LuckValue.Value, LuckTimeValue.Value)
end)