local Util = require(script.Parent.Parent._Shared.Util)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RagdollModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RagdollModule"))

local CelestialSlap = {}

function CelestialSlap.Attach(ctx)
	local Tool = ctx.Tool
	local Player = ctx.Player
	local cfg = ctx.Configuration
	local ActivationTrack = ctx.ActivationTrack
	local ActivationSound = ctx.ActivationSound
	local Fling = ctx.Fling
	local ReturnStolenThingEvent = ctx.ReturnStolenThingEvent

	local Equipped, Cooldown, Swinging = false, false, false

	-- ✅ Configurable hitbox size (from config)
	local Hitbox = tonumber(cfg.Hitbox) or 7
	local HitboxSize = Vector3.new(Hitbox, Hitbox, Hitbox)
	local HitboxOffset = CFrame.new(0, 0, -(Hitbox / 2))

	-- ✅ Optional hit sound
	local HitSound
	local handle = Tool:FindFirstChild("Handle")
	if handle and cfg.HitSound and cfg.HitSound ~= "" then
		HitSound = Instance.new("Sound")
		HitSound.Name = "HitSound"
		HitSound.SoundId = cfg.HitSound
		HitSound.Volume = 2
		HitSound.RollOffMode = Enum.RollOffMode.Linear
		HitSound.RollOffMaxDistance = 90
		HitSound.Parent = handle
	end

	-- ✅ Hitbox detection
	local function GetTargets(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return {} end

		local hitboxCF = root.CFrame * HitboxOffset
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character, Tool}

		local parts = workspace:GetPartBoundsInBox(hitboxCF, HitboxSize, params)
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

	-- ✅ Handle hit logic
	local function OnHit(targetChar)
		if not targetChar then return end
		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		if not targetPlayer or targetPlayer == Player then return end

		-- 🚫 Skip if already ragdolled
		if targetChar:GetAttribute("Ragdolled") == true then
			return
		end

		if HitSound then HitSound:Play() end

		local power = tonumber(cfg.Power) or 80
		if power > 0 then
			Fling(targetPlayer, Player, power)
		end

		local ragdollTime = 2
		RagdollModule.TimedRagdoll(targetChar, ragdollTime)

		if cfg.ReturnStolenThings then
			ReturnStolenThingEvent:Fire(targetPlayer)
		end
	end

	-- ✅ Equip/unequip handling
	Tool.Equipped:Connect(function()
		Equipped = true
		Swinging = false
	end)

	Tool.Unequipped:Connect(function()
		Equipped = false
		Swinging = false
	end)

	-- ✅ Main activation handler
	Tool.Activated:Connect(function()
		if not Equipped or Cooldown then return end

		Cooldown = true
		Swinging = true

		if ActivationTrack then ActivationTrack:Play() end
		if ActivationSound then ActivationSound:Play() end

		local animLen = tonumber(ActivationTrack and ActivationTrack.Length) or 0.4

		task.delay(0.1, function()
			if not Swinging then return end
			local char = Player.Character
			if not char then return end

			for targetChar in pairs(GetTargets(char)) do
				OnHit(targetChar)
			end
		end)

		task.delay(animLen, function()
			Swinging = false
			task.delay(tonumber(cfg.Cooldown) or 0.3, function()
				Cooldown = false
			end)
		end)
	end)
end

return CelestialSlap
