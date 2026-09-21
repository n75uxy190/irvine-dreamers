local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ActivateEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Activate")
local DeactivateEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Deactivate")

local ToolsConfig = require(ReplicatedStorage.Configuration.Modules.Tools)
local Config = ToolsConfig["InvisibilityCloak"]

local CLOAK_SPEED = 60
local NORMAL_SPEED = 30
local STEAL_PENALTY_SPEED = 20
local STEAL_PENALTY_SECONDS = 8
local FADE_TIME = 0.5

-- Tween fade for parts
local function fadeCharacter(char, enabled)
	if not char then return end
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			TweenService:Create(obj, TweenInfo.new(FADE_TIME), {Transparency = enabled and 1 or 0}):Play()
		elseif obj:IsA("Decal") then
			TweenService:Create(obj, TweenInfo.new(FADE_TIME), {Transparency = enabled and 1 or 0}):Play()
		end
	end
end

-- Instant transparency set (silent)
local function setTransparencyInstant(char, enabled)
	if not char then return end
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			obj.Transparency = enabled and 1 or 0
		elseif obj:IsA("Decal") then
			obj.Transparency = enabled and 1 or 0
		end
	end
end

-- Ensure tool visuals visible on server
local function setToolVisible(player)
	if not player then return end
	local tool = player.Backpack and player.Backpack:FindFirstChild("InvisibilityCloak") 
		or (player.Character and player.Character:FindFirstChild("InvisibilityCloak"))
	if not tool then return end
	for _, obj in ipairs(tool:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Decal") then
			obj.Transparency = 0
		end
	end
end

-- Play sound for everyone
local function playSound(char, enabled)
	local soundId = enabled and Config.SoundIdStart or Config.SoundIdEnd
	if not soundId or soundId == "" then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 2
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = 90
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, (sound.TimeLength > 0 and sound.TimeLength or 1) + 0.2)
end

-- Helper: get current penalty expire time (number) or nil
local function getStealPenaltyExpire(player)
	if not player then return nil end
	local v = player:GetAttribute("StealPenaltyExpire")
	if type(v) == "number" then return v end
	return nil
end

-- Apply invisibility
-- customSpeed: optional speed to set when disabling (overrides NORMAL_SPEED and penalty logic)
local function setInvisible(player, enabled, showEffects, customSpeed)
	showEffects = (showEffects == nil) and true or showEffects
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if enabled then
			humanoid.WalkSpeed = CLOAK_SPEED
		else
			-- disabling invisibility: choose speed
			-- priority: customSpeed -> active steal penalty -> NORMAL_SPEED
			if customSpeed and type(customSpeed) == "number" then
				humanoid.WalkSpeed = customSpeed
			else
				local expire = getStealPenaltyExpire(player)
				if expire and os.time() < expire then
					humanoid.WalkSpeed = STEAL_PENALTY_SPEED
				else
					humanoid.WalkSpeed = NORMAL_SPEED
				end
			end
		end
		humanoid.NameDisplayDistance = enabled and 0 or 100
	end

	if showEffects then
		fadeCharacter(player.Character, enabled)
		playSound(player.Character, enabled)
	else
		setTransparencyInstant(player.Character, enabled)
	end

	if not enabled then
		setToolVisible(player)
	end
end

-- Normal activation handler (client fired)
ActivateEvent.OnServerEvent:Connect(function(player)
	if not player then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.WalkSpeed == CLOAK_SPEED then
		-- toggle off
		setInvisible(player, false, true)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				DeactivateEvent:FireClient(plr, player)
			end
		end
	else
		-- toggle on
		setInvisible(player, true, true)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				ActivateEvent:FireClient(plr, player)
			end
		end
	end
end)

-- Deactivate (client fired). Accepts optional silent boolean.
DeactivateEvent.OnServerEvent:Connect(function(player, silent)
	if not player then return end
	local showEffects = not silent
	-- Respect penalty logic inside setInvisible
	setInvisible(player, false, showEffects)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			DeactivateEvent:FireClient(plr, player, silent)
		end
	end
end)

-- Force reset (callable by modules like module.add)
-- player: Player instance
-- silent: boolean (true = instant no sound/fade)
-- penaltySeconds (optional): how many seconds to apply the steal penalty (defaults to STEAL_PENALTY_SECONDS)
_G.ForceResetPlayer = function(player, silent, penaltySeconds)
	if not player then return end
	local showEffects = not silent
	penaltySeconds = tonumber(penaltySeconds) or STEAL_PENALTY_SECONDS

	-- set penalty expire time (so server-side code uses the penalty speed)
	player:SetAttribute("StealPenaltyExpire", os.time() + penaltySeconds)

	-- Immediately make the player visible and apply penalty speed
	-- pass customSpeed so setInvisible doesn't override it
	setInvisible(player, false, showEffects, STEAL_PENALTY_SPEED)
end
