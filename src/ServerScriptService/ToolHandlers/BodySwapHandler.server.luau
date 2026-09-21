local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local BodySwapEvent = Remotes.Events:WaitForChild("BodySwapEvent")

-- Reference the tool config for the sound ID
local ToolsConfig = require(game.ReplicatedStorage.Configuration.Modules.Tools)
local SWAP_TOOL_NAME = "BodySwapPotion" -- replace with your tool name

local ServerStorage = game:GetService("ServerStorage")
local ReturnStolenThingEvent = nil
pcall(function()
	ReturnStolenThingEvent = ServerStorage.Bindables.Events:WaitForChild("ReturnStolenThing")
end)

local function SwapPositions(player, targetPlayer)
	if not (player and targetPlayer) then
		return
	end
	if not player.Character or not targetPlayer.Character then
		return
	end

	local root1 = player.Character:FindFirstChild("HumanoidRootPart")
	local root2 = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root1 or not root2 then
		return
	end

	-- Swap positions
	local pos1 = root1.CFrame
	root1.CFrame = root2.CFrame
	root2.CFrame = pos1

	-- Check Config
	local Config = ToolsConfig[SWAP_TOOL_NAME]

	-- PLAY SOUND FROM PLAYER WHO USED THE TOOL
	if Config and Config.SoundId and Config.SoundId ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = Config.SoundId
		sound.Volume = 5
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.RollOffMaxDistance = 90 -- adjust how far players can hear it
		sound.PlaybackSpeed = 1
		sound.Parent = root1 -- plays from the player who used the tool
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.1)
	end

	-- ✅ Return stolen things for the target if configured
	if Config and Config.ReturnStolenThings and ReturnStolenThingEvent then
		pcall(function()
			ReturnStolenThingEvent:Fire(targetPlayer)
		end)
	end
end

BodySwapEvent.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
		SwapPositions(player, targetPlayer)
	end
end)
