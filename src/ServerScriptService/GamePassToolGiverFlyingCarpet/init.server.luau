local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local AssetIds = require(game.ReplicatedStorage.Configuration.Modules:WaitForChild("AssetIds"))

local GAMEPASS_ID = AssetIds.GamePasses.FlyingCarpet
local Tool = script.FlyingCarpet

-- Function to give tool safely
local function giveTool(player)
	if not player:FindFirstChildOfClass("Backpack") then return end
	if not player.Backpack:FindFirstChild(Tool.Name) then
		local toolClone = Tool:Clone()
		toolClone.Parent = player.Backpack
	end
end

-- Give tool on spawn if they own the gamepass
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID) then
			giveTool(player)
		end
	end)
end)

-- Give tool instantly after purchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassId, purchaseSuccess)
	if purchaseSuccess and purchasedPassId == GAMEPASS_ID then
		giveTool(player)
	end
end)
