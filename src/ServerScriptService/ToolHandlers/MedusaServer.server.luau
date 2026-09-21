-- MedusaServer (ServerScriptService/ToolHandlers/MedusaServer)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local ToolsConfig = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Tools"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Events = Remotes:WaitForChild("Events")
local MedusaTransform = Events:WaitForChild("MedusaTransform") -- RemoteFunction

local RagdollModule = require(ReplicatedStorage.Modules:WaitForChild("RagdollModule"))

local DEBOUNCE = {} -- player -> last used tick

-- NEW: Return stolen things bindable
local ReturnStolenThingEvent = nil
pcall(function()
	ReturnStolenThingEvent = ServerStorage.Bindables.Events:WaitForChild("ReturnStolenThing")
end)

local function TagHumanoid(humanoid, player)
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = player
	Debris:AddItem(tag, 2)
	tag.Parent = humanoid
end

local function CreateStoneStatue(character)
	local ok, clone = pcall(function() return character:Clone() end)
	if not ok or not clone then return nil end

	clone.Parent = workspace

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local cloneHrp = clone:FindFirstChild("HumanoidRootPart")
	if hrp and cloneHrp then
		cloneHrp.CFrame = hrp.CFrame
	end

	for _, v in ipairs(clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = true
			v.BrickColor = BrickColor.new("Dark stone grey")
			v.Material = Enum.Material.SmoothPlastic
		elseif v:IsA("Humanoid") then
			v:Destroy()
		end
	end

	return clone
end

local function FreezeCharacter(character)
	local anchoredParts = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.Anchored = true
			table.insert(anchoredParts, part)
		end
	end
	return anchoredParts
end

-- Apply temporary clothes + freeze + ragdoll after duration
local function ApplyTemporaryClothes(targetCharacter, shirtTemplate, pantsTemplate, duration)
	if not targetCharacter then return end
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local anchoredParts = FreezeCharacter(targetCharacter)

	local originalShirt = targetCharacter:FindFirstChildWhichIsA("Shirt")
	local originalPants = targetCharacter:FindFirstChildWhichIsA("Pants")
	local origShirtId = originalShirt and originalShirt.ShirtTemplate
	local origPantsId = originalPants and originalPants.PantsTemplate

	if originalShirt then originalShirt:Destroy() end
	if originalPants then originalPants:Destroy() end

	if shirtTemplate then
		local newShirt = Instance.new("Shirt")
		newShirt.ShirtTemplate = shirtTemplate
		newShirt.Parent = targetCharacter
	end
	if pantsTemplate then
		local newPants = Instance.new("Pants")
		newPants.PantsTemplate = pantsTemplate
		newPants.Parent = targetCharacter
	end

	task.delay(duration, function()
		if not targetCharacter or not humanoid or humanoid.Health <= 0 then return end

		local tempShirt = targetCharacter:FindFirstChildWhichIsA("Shirt")
		local tempPants = targetCharacter:FindFirstChildWhichIsA("Pants")
		if tempShirt then tempShirt:Destroy() end
		if tempPants then tempPants:Destroy() end

		if origShirtId then
			local origShirt = Instance.new("Shirt")
			origShirt.ShirtTemplate = origShirtId
			origShirt.Parent = targetCharacter
		end
		if origPantsId then
			local origPants = Instance.new("Pants")
			origPants.PantsTemplate = origPantsId
			origPants.Parent = targetCharacter
		end

		-- Unstone the player but disable movement
		for _, part in ipairs(anchoredParts) do
			if part and part.Parent then
				part.Anchored = false
			end
		end

		local oldWalk = 30
		local oldJump = 7.2

		humanoid.WalkSpeed = 0
		if humanoid.UseJumpPower then
			humanoid.JumpPower = 0
		else
			humanoid.JumpHeight = 0
		end

		-- ✅ Use RagdollModule instead of custom SmoothRagdoll
		RagdollModule.TimedRagdoll(targetCharacter, 2.5)

		-- Restore movement after ragdoll ends
		task.delay(2.5, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = oldWalk
				if humanoid.UseJumpPower then
					humanoid.JumpPower = oldJump
				else
					humanoid.JumpHeight = oldJump
				end
			end
		end)
	end)
end

MedusaTransform.OnServerInvoke = function(player)
	if not player or not player.Character then return 0 end

	local config = ToolsConfig["MedusaHead"] or {}
	local cooldown = tonumber(config.Cooldown) or 25
	local range = tonumber(config.Range) or 15
	local soundId = config.SoundId

	local last = DEBOUNCE[player]
	if last and tick() - last < cooldown then
		return 0
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local head = player.Character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not head then return 0 end

	local origin = head.Position
	local duration = 3

	local tool = player.Backpack:FindFirstChild("MedusaHead") or player.Character:FindFirstChild("MedusaHead")
	local shirtTemplate, pantsTemplate
	if tool then
		local shirtObj = tool:FindFirstChildWhichIsA("Shirt")
		local pantsObj = tool:FindFirstChildWhichIsA("Pants")
		shirtTemplate = shirtObj and shirtObj.ShirtTemplate
		pantsTemplate = pantsObj and pantsObj.PantsTemplate
	end

	local affected = 0
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player and target.Character then
			local tchar = target.Character
			local tHum = tchar:FindFirstChildOfClass("Humanoid")
			local tHRP = tchar:FindFirstChild("HumanoidRootPart")
			if tHum and tHRP and tHum.Health > 0 then
				local dist = (tHRP.Position - origin).Magnitude
				if dist <= range then
					if not tchar:FindFirstChildOfClass("ForceField") then
						TagHumanoid(tHum, player)

						-- ✅ Return stolen things for the affected player if configured
						if config.ReturnStolenThings and ReturnStolenThingEvent then
							pcall(function()
								ReturnStolenThingEvent:Fire(target)
							end)
						end

						ApplyTemporaryClothes(tchar, shirtTemplate, pantsTemplate, duration)
						local stoneClone = CreateStoneStatue(tchar)
						if stoneClone then
							Debris:AddItem(stoneClone, duration)
						end
						affected += 1
					end
				end
			end
		end
	end

	DEBOUNCE[player] = tick()

	if tool then
		local handle = tool:FindFirstChild("Handle")
		local actSound = handle and handle:FindFirstChild("ActivationSound")
		if actSound and actSound:IsA("Sound") then
			pcall(function() actSound:Play() end)
		end
	end

	if soundId and soundId ~= "" then
		local headPart = player.Character:FindFirstChild("Head")
		if headPart then
			local s = Instance.new("Sound")
			s.Name = "MedusaActivationSound"
			s.SoundId = tostring(soundId)
			s.Volume = 2
			s.RollOffMode = Enum.RollOffMode.Linear
			pcall(function() s.MaxDistance = 90 end)
			s.Parent = headPart
			s:Play()
			Debris:AddItem(s, (s.TimeLength > 0 and s.TimeLength) or 2)
		end
	end

	return duration
end