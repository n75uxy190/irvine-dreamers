local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- Replace this with your existing Ragdoll module
local RagdollModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RagdollModule"))

local Tool = script.Parent
local Player = nil

-- ==== CONFIGURATION ====
local HITBOX_SIZE = 9              -- size of the hitbox cube
local POWER = 80                   -- fling force
local RAGDOLL_DURATION = 3         -- seconds
local COOLDOWN = 0.3               -- seconds between hits
local HIT_SOUND_ID = "rbxassetid://146163534"                 -- optional sound asset id (rbxassetid://...)
local ACTIVATION_ANIMATION_ID = "rbxassetid://99236704955736"      -- optional animation id (rbxassetid://...)
local ACTIVATION_SOUND_ID = "rbxassetid://9113305311"          -- optional activation sound (rbxassetid://...)
local RETURN_STOLEN = true         -- fire ReturnStolenThing event
-- ======================

-- Optional bindable event for ReturnStolenThing
local ReturnStolenThingEvent
pcall(function()
	local b = ServerStorage:WaitForChild("Bindables")
	local e = b:WaitForChild("Events")
	ReturnStolenThingEvent = e:FindFirstChild("ReturnStolenThing")
end)

local Equipped = false
local Swinging = false
local CooldownActive = false

-- Optional hit sound
local HitSound
local handle = Tool:FindFirstChild("Handle")
if handle and HIT_SOUND_ID ~= "" then
	HitSound = Instance.new("Sound")
	HitSound.Name = "HitSound"
	HitSound.SoundId = HIT_SOUND_ID
	HitSound.Volume = 2
	HitSound.RollOffMode = Enum.RollOffMode.Linear
	HitSound.RollOffMaxDistance = 90
	HitSound.Parent = handle
end

-- Optional activation sound
local ActivationSound
if handle and ACTIVATION_SOUND_ID ~= "" then
	ActivationSound = Instance.new("Sound")
	ActivationSound.Name = "ActivationSound"
	ActivationSound.SoundId = ACTIVATION_SOUND_ID
	ActivationSound.Volume = 2
	ActivationSound.RollOffMode = Enum.RollOffMode.Linear
	ActivationSound.RollOffMaxDistance = 90
	ActivationSound.Parent = handle
end

-- Optional activation animation
local ActivationAnimation
local AnimationTrack
if ACTIVATION_ANIMATION_ID ~= "" then
	ActivationAnimation = Instance.new("Animation")
	ActivationAnimation.AnimationId = ACTIVATION_ANIMATION_ID
end

-- Improved fling function
local function Fling(TargetPlayer, AttackerPlayer, Power)
	local targetChar = TargetPlayer.Character
	local attackerChar = AttackerPlayer.Character
	if not targetChar or not attackerChar then return end

	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not attackerRoot or not targetHum then return end

	-- Apply ragdoll
	RagdollModule.TimedRagdoll(targetChar, RAGDOLL_DURATION)

	-- Directional impulse
	local direction = (targetRoot.Position - attackerRoot.Position).Unit
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = (direction + Vector3.new(0, 0.8, 0)).Unit * (Power or 50)
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.P = 1e4
	bodyVelocity.Parent = targetRoot

	-- Angular spin for realism
	local bodyAngular = Instance.new("BodyAngularVelocity")
	bodyAngular.AngularVelocity = Vector3.new(math.random(), math.random(), math.random()) * math.pi * 2
	bodyAngular.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyAngular.P = 5e3
	bodyAngular.Parent = targetRoot

	-- Cleanup
	Debris:AddItem(bodyVelocity, 0.4)
	Debris:AddItem(bodyAngular, 0.4)
end

-- Detect targets in hitbox
local function GetTargets(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return {} end

	local hitboxCF = root.CFrame * CFrame.new(0,0,-(HITBOX_SIZE/2))
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, Tool}

	local parts = workspace:GetPartBoundsInBox(hitboxCF, Vector3.new(HITBOX_SIZE,HITBOX_SIZE,HITBOX_SIZE), params)
	local targets = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not targets[model] then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				targets[model] = hum
			end
		end
	end

	return targets
end

-- Handle a hit
local function OnHit(targetChar)
	if not targetChar then return end
	local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
	if not targetPlayer or targetPlayer == Player then return end

	if targetChar:GetAttribute("Ragdolled") == true then return end

	if HitSound then HitSound:Play() end

	Fling(targetPlayer, Player, POWER)

	if RETURN_STOLEN and ReturnStolenThingEvent then
		pcall(function() ReturnStolenThingEvent:Fire(targetPlayer) end)
	end
end

-- Equip/Unequip
Tool.Equipped:Connect(function()
	Equipped = true
	Player = Players:GetPlayerFromCharacter(Tool.Parent)

	if Player and ActivationAnimation then
		local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			AnimationTrack = humanoid:LoadAnimation(ActivationAnimation)
		end
	end
end)

Tool.Unequipped:Connect(function()
	Equipped = false
	Swinging = false
	Player = nil
	if AnimationTrack then
		AnimationTrack:Stop()
		AnimationTrack = nil
	end
end)

-- Tool activation
Tool.Activated:Connect(function()
	if not Equipped or CooldownActive then return end
	if not Player or not Player.Character then return end

	CooldownActive = true
	Swinging = true

	if AnimationTrack then AnimationTrack:Play() end
	if ActivationSound then ActivationSound:Play() end

	local animLen = tonumber(AnimationTrack and AnimationTrack.Length) or 0.4

	task.delay(0.1, function()
		if not Swinging then return end
		local char = Player.Character
		for targetChar in pairs(GetTargets(char)) do
			OnHit(targetChar)
		end
	end)

	task.delay(animLen, function()
		Swinging = false
		task.delay(COOLDOWN, function()
			CooldownActive = false
		end)
	end)
end)
