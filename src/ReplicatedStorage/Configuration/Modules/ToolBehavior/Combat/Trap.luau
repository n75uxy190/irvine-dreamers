local Trap = {}

-- Helper: ensure the owner’s folder exists under Debris/Traps
local function getOwnerFolder(ownerUserId: number)
	local DebrisFolder = workspace:FindFirstChild("Debris") or Instance.new("Folder", workspace)
	DebrisFolder.Name = "Debris"

	local trapsRoot = DebrisFolder:FindFirstChild("Traps") or Instance.new("Folder")
	trapsRoot.Name = "Traps"
	trapsRoot.Parent = DebrisFolder

	local ownerFolder = trapsRoot:FindFirstChild(tostring(ownerUserId)) or Instance.new("Folder")
	ownerFolder.Name = tostring(ownerUserId)
	ownerFolder.Parent = trapsRoot

	return ownerFolder
end

-- Count current active traps for this owner
local function countActiveTraps(ownerFolder: Folder)
	local n = 0
	for _, m in ipairs(ownerFolder:GetChildren()) do
		if m:IsA("Model") then
			n += 1
		end
	end
	return n
end

-- Find or build a trap model template (robust fallback)
local function getTrapTemplate(cfg)
	local ServerStorage = game:GetService("ServerStorage")
	local assets = ServerStorage:FindFirstChild("Assets")
	local trapsFolder = assets and assets:FindFirstChild("Traps")
	local basic = trapsFolder and trapsFolder:FindFirstChild("BasicTrap")

	local function buildFallback()
		local m = Instance.new("Model")
		m.Name = "BasicTrap"

		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored = true
		base.Size = Vector3.new(4, 1, 4)
		base.TopSurface = Enum.SurfaceType.Smooth
		base.BottomSurface = Enum.SurfaceType.Smooth
		base.Parent = m
		m.PrimaryPart = base

		local trigger = Instance.new("Part")
		trigger.Name = "Trigger"
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.CanQuery = false
		trigger.CanTouch = true
		trigger.Transparency = 1
		trigger.Size = Vector3.new(4.25, 5, 4.25)
		trigger.CFrame = base.CFrame
		trigger.Parent = m

		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = base, trigger
		weld.Parent = base

		if typeof(cfg.TrapSound) == "string" and cfg.TrapSound ~= "" then
			local s = Instance.new("Sound")
			s.Name = "TrapSound"
			s.SoundId = cfg.TrapSound
			s.RollOffMode = Enum.RollOffMode.Linear
			s.RollOffMaxDistance = 90
			s.Parent = base
		end

		return m
	end

	if basic and basic:IsA("Model") then
		-- Ensure PrimaryPart
		if not basic.PrimaryPart then
			local base = basic:FindFirstChild("Base")
			if base and base:IsA("BasePart") then
				basic.PrimaryPart = base
			end
		end
		-- Ensure Trigger exists & is touchable
		local trig = basic:FindFirstChild("Trigger")
		if not trig or not trig:IsA("BasePart") then
			return buildFallback()
		else
			trig.CanCollide = false
			trig.CanQuery = false
			trig.CanTouch = true
		end
		if not basic.PrimaryPart then
			return buildFallback()
		end
		return basic
	end

	return buildFallback()
end

-- Compute a CFrame so the player's FEET rest on top of the trap's Base.
-- Uses the character's bounding box height so it works across rigs/accessories.
local function getStandCFOnTrap(trap: Model, char: Model, standOffsetY: number?)
	local base = trap.PrimaryPart
	if not base then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return nil end

	local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()

	-- Character bounding box and size
	local bbCF, bbSize = char:GetBoundingBox()

	-- Top surface of the trap base
	local topY = base.Position.Y + (base.Size.Y * 0.5)

	-- We want the bounding-box MIN Y to sit exactly on top of the base.
	-- bbMinY = bbCF.Position.Y - bbSize.Y/2
	-- So set desired bbCenterY = topY + bbSize.Y/2 (+ small offset)
	local offset = standOffsetY or 0.05
	local desiredBBCenterY = topY + (bbSize.Y * 0.5) + offset
	local deltaY = desiredBBCenterY - bbCF.Position.Y

	-- Keep X/Z at trap center so they snap to "middle of trap"
	local targetPos = Vector3.new(base.Position.X, hrp.Position.Y + deltaY, base.Position.Z)

	return CFrame.new(targetPos) * CFrame.Angles(0, yaw, 0)
end

-- Anchor-based freeze (no welds)
local function freezeCharacterAnchored(char: Model)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return nil end
	if char:GetAttribute("IsTrapped") then return nil end

	char:SetAttribute("IsTrapped", true)

	local saved = {
		WalkSpeed = hum.WalkSpeed,
		JumpPower = hum.UseJumpPower and hum.JumpPower or nil,
		JumpHeight = (not hum.UseJumpPower) and hum.JumpHeight or nil,
		AutoRotate = hum.AutoRotate,
		PlatformStand = hum.PlatformStand,
		Anchored = hrp.Anchored,
	}

	-- zero out motion + hard-freeze
	hum.AutoRotate = false
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	hum.PlatformStand = true
	hum.WalkSpeed = 0
	if hum.UseJumpPower then hum.JumpPower = 0 else hum.JumpHeight = 0 end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Anchored = true

	return saved
end

local function unfreezeCharacterAnchored(char: Model, saved)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then
		char:SetAttribute("IsTrapped", false)
		return
	end

	hrp.Anchored = saved.Anchored
	hum.AutoRotate = saved.AutoRotate
	hum.PlatformStand = saved.PlatformStand
	hum:ChangeState(Enum.HumanoidStateType.Running)
	hum.WalkSpeed = saved.WalkSpeed
	if hum.UseJumpPower and saved.JumpPower then
		hum.JumpPower = saved.JumpPower
	elseif (not hum.UseJumpPower) and saved.JumpHeight then
		hum.JumpHeight = saved.JumpHeight
	end

	char:SetAttribute("IsTrapped", false)
end

-- Attach behavior to tool
function Trap.Attach(ctx)
	local Tool      = ctx.Tool
	local Player    = ctx.Player
	local cfg       = ctx.Configuration
	local Players   = ctx.Players

	local ownerUserId = Player.UserId
	local TrapTime     = tonumber(cfg.TrapTime) or 7
	local TrapMaxPlace = math.max(1, tonumber(cfg.TrapMaxPlace) or 1)
	local TrapMaxUses  = math.max(1, tonumber(cfg.TrapMaxUses) or 1)
	local TrapLifetime = tonumber(cfg.TrapLifetime) or 420
	local ToolCooldown = tonumber(cfg.TrapCooldown) or 0
	local TrapDelay    = tonumber(cfg.TrapDelay) or 1
	local StandOffset  = tonumber(cfg.StandOffset) or 0.05 -- small lift to avoid clipping

	local ownerFolder = getOwnerFolder(ownerUserId)
	local placing = false
	local equipped = false

	Tool.Equipped:Connect(function() equipped = true end)
	Tool.Unequipped:Connect(function() equipped = false end)

	local now = os.clock
	-- cooldown tracking on the folder (persists across re-equip)
	local function getNextPlaceAt(folder: Folder)
		return folder:GetAttribute("NextPlaceAt") or 0
	end
	local function setNextPlaceAt(folder: Folder, t: number)
		folder:SetAttribute("NextPlaceAt", t)
	end

	local function placeTrap()
		if placing or not equipped then return end

		-- placement cooldown
		if TrapDelay > 0 then
			local tNow = now()
			if tNow < getNextPlaceAt(ownerFolder) then
				return
			end
		end

		-- hard cap: if already at max, do nothing
		if countActiveTraps(ownerFolder) >= TrapMaxPlace then
			return
		end

		placing = true

		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then placing = false return end

		-- raycast to floor
		local origin = hrp.Position
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {char}
		local ray = workspace:Raycast(origin, Vector3.new(0, -50, 0), rayParams)
		local placeCFrame
		if ray and ray.Position then
			placeCFrame = CFrame.new(Vector3.new(ray.Position.X, ray.Position.Y + 0.5, ray.Position.Z))
		else
			placeCFrame = CFrame.new(origin + Vector3.new(0, -2, 0))
		end

		-- create trap
		local template = getTrapTemplate(cfg)
		local trap = template:Clone()
		trap.Name = "Trap_" .. ownerUserId .. "_" .. string.format("%.2f", os.clock())
		trap:SetAttribute("OwnerUserId", ownerUserId)
		trap:SetAttribute("UsesLeft", TrapMaxUses)
		trap:SetAttribute("PlacedAt", os.clock())
		trap:PivotTo(placeCFrame)
		trap.Parent = ownerFolder

		-- server owns physics for reliable touches
		local base = trap.PrimaryPart
		local trigger = trap:FindFirstChild("Trigger")
		--if base and base:IsA("BasePart") then base:SetNetworkOwner(nil) end
		if trigger and trigger:IsA("BasePart") then
			trigger.CanTouch = true
			trigger.CanCollide = false
			trigger.CanQuery = false
			--trigger:SetNetworkOwner(nil)
		end

		-- set next allowed placement time
		if TrapDelay > 0 then
			setNextPlaceAt(ownerFolder, now() + TrapDelay)
		end

		-- optional lifetime cleanup
		if TrapLifetime and TrapLifetime > 0 then
			task.delay(TrapLifetime, function()
				if trap.Parent then trap:Destroy() end
			end)
		end

		-- validate parts
		if not (trigger and trigger:IsA("BasePart") and base) then
			trap:Destroy()
			placing = false
			return
		end

		trigger.Touched:Connect(function(hit)
			if not trap.Parent then return end
			local usesLeft = trap:GetAttribute("UsesLeft")
			if not usesLeft or usesLeft <= 0 then return end

			-- who touched?
			local charTouched = hit and hit.Parent
			if not charTouched then return end
			local p2 = Players:GetPlayerFromCharacter(charTouched)
			if not p2 or p2.UserId == ownerUserId then return end  -- owner immune

			-- prevent retrap
			if charTouched:GetAttribute("IsTrapped") then return end

			-- put their FEET on top center of base, then anchor
			local standCF = getStandCFOnTrap(trap, charTouched, StandOffset)
			if standCF then
				local hrp2 = charTouched:FindFirstChild("HumanoidRootPart")
				if hrp2 then
					hrp2.AssemblyLinearVelocity = Vector3.zero
					hrp2.AssemblyAngularVelocity = Vector3.zero
				end
				charTouched:PivotTo(standCF)
			end

			local saved = freezeCharacterAnchored(charTouched)
			if not saved then return end

			-- play trap sound
			local snd = (base:FindFirstChild("TrapSound") or trap:FindFirstChild("TrapSound"))
			if snd and snd:IsA("Sound") then
				snd:Play()
			elseif typeof(cfg.TrapSound) == "string" and cfg.TrapSound ~= "" then
				local s = Instance.new("Sound")
				s.Name = "TrapSound"
				s.SoundId = cfg.TrapSound
				s.Parent = base
				s.RollOffMode = Enum.RollOffMode.Linear
				s.RollOffMaxDistance = 90
				s.Volume = 5
				s:Play()
			end

			-- release after TrapTime (or on death)
			local hum = charTouched:FindFirstChildOfClass("Humanoid")
			local released = false
			local function releaseNow()
				if released then return end
				released = true
				unfreezeCharacterAnchored(charTouched, saved)
			end

			local diedConn
			if hum then
				diedConn = hum.Died:Connect(releaseNow)
			end

			task.delay(TrapTime, function()
				releaseNow()
				if diedConn then diedConn:Disconnect() end

				-- consume a use and maybe destroy the trap
				local left = (trap:GetAttribute("UsesLeft") or 1) - 1
				trap:SetAttribute("UsesLeft", left)
				if left <= 0 and trap.Parent then
					trap:Destroy()
				end
			end)
		end)

		-- small debounce to prevent spam-clicks
		if ToolCooldown and ToolCooldown > 0 then
			task.delay(ToolCooldown, function() placing = false end)
		else
			placing = false
		end
	end

	Tool.Activated:Connect(placeTrap)

	-- Clean up the owner’s traps on respawn (optional)
	Player.CharacterAdded:Connect(function()
		for _, m in ipairs(ownerFolder:GetChildren()) do
			if m:IsA("Model") then m:Destroy() end
		end
	end)
end

return Trap
