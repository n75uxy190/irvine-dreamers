local Util = require(script.Parent.Parent._Shared.Util)
local RunService = game:GetService("RunService")

local CoilCombo = {}

function CoilCombo.Attach(ctx)
	local Tool = ctx.Tool
	local Humanoid = ctx.Humanoid
	local cfg = ctx.Configuration

	-- Shared Handle + Sound
	local handle = Tool:FindFirstChild("Handle")
	local equipSfx1 = Util.ensureSound(handle, "EquippedSound", cfg.EquippedSound)
	local equipSfx2 = Util.ensureSound(handle, "EquippedSound2", cfg.EquippedSound2)


	----------------------------------------------------------------------
	-- SPEED BOOST LOGIC (same as SpeedCoil)
	----------------------------------------------------------------------
	local speed = tonumber(cfg.Speed)
	local additive = cfg.AdditiveSpeed == true
	local originalSpeed

	local function applySpeed()
		if not Humanoid or Humanoid.Health <= 0 then return end
		if originalSpeed == nil then
			originalSpeed = Humanoid.WalkSpeed
		end
		Humanoid.WalkSpeed = additive and originalSpeed + speed or speed
	end

	local function clearSpeed()
		if Humanoid and originalSpeed then
			Humanoid.WalkSpeed = originalSpeed
		end
		originalSpeed = nil
	end

	----------------------------------------------------------------------
	-- GRAVITY / JUMP BOOST LOGIC (from GravityCoil + optimized)
	----------------------------------------------------------------------
	local counterPercent = tonumber(cfg.GravityCounterPercent)
	if not counterPercent then
		local remaining = tonumber(cfg.GravityPercentRemaining)
		if not remaining then
			remaining = tonumber(cfg.Gravity)
			if remaining and remaining > 1 then
				remaining = remaining / 100
			end
		end
		remaining = remaining or 0.25
		counterPercent = 1 - remaining
	end
	counterPercent = math.clamp(counterPercent, 0, 0.95)

	local jumpMul = tonumber(cfg.JumpMultiplier)
	if jumpMul == nil then jumpMul = 1 end
	jumpMul = math.max(jumpMul, 0)

	local hrp, vforce, attachment
	local saved = { UseJumpPower=nil, JumpPower=nil, JumpHeight=nil }
	local hbConn
	local conns = {}

	local function restoreJump()
		if Humanoid and saved.UseJumpPower ~= nil then
			if saved.UseJumpPower then
				Humanoid.JumpPower = saved.JumpPower
				Humanoid.UseJumpPower = true
			else
				Humanoid.JumpHeight = saved.JumpHeight
				Humanoid.UseJumpPower = false
			end
		end
		saved.UseJumpPower, saved.JumpPower, saved.JumpHeight = nil, nil, nil
	end

	local function removeForce()
		if vforce then vforce:Destroy() vforce = nil end
		if attachment then attachment:Destroy() attachment = nil end
	end

	local function disconnectAll()
		for _, c in ipairs(conns) do if c then c:Disconnect() end end
		conns = {}
		if hbConn then hbConn:Disconnect() end
		hbConn = nil
	end

	local function applyJumpBoost()
		if saved.UseJumpPower ~= nil or jumpMul == 1 then return end
		saved.UseJumpPower = Humanoid.UseJumpPower
		if Humanoid.UseJumpPower then
			saved.JumpPower = Humanoid.JumpPower
			Humanoid.JumpPower = Humanoid.JumpPower * jumpMul
		else
			saved.JumpHeight = Humanoid.JumpHeight
			Humanoid.JumpHeight = Humanoid.JumpHeight * jumpMul
		end
	end

	local function recomputeForce()
		if not (hrp and vforce) then return end
		local mass = hrp.AssemblyMass or hrp:GetMass()
		local g = workspace.Gravity
		vforce.Force = Vector3.new(0, mass * g * counterPercent, 0)
	end

	local function applyGravity()
		if not Humanoid or Humanoid.Health <= 0 then return end

		local char = Humanoid.Parent
		if not char then return end

		hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Parent = hrp
		end
		if not vforce then
			vforce = Instance.new("VectorForce")
			vforce.ApplyAtCenterOfMass = true
			vforce.RelativeTo = Enum.ActuatorRelativeTo.World
			vforce.Attachment0 = attachment
			vforce.Parent = hrp
		end

		applyJumpBoost()
		recomputeForce()

		if not hbConn then
			hbConn = RunService.Heartbeat:Connect(recomputeForce)
		end

		table.insert(conns, char.DescendantAdded:Connect(function()
			task.defer(recomputeForce)
		end))
		table.insert(conns, char.DescendantRemoving:Connect(function()
			task.defer(recomputeForce)
		end))

		table.insert(conns, Humanoid.Died:Connect(function()
			removeForce()
			restoreJump()
			disconnectAll()
		end))
	end

	----------------------------------------------------------------------
	-- FINAL EQUIP / UNEQUIP HANDLERS
	----------------------------------------------------------------------
	local function applyBoth()
		applySpeed()
		applyGravity()
		if equipSfx1 then equipSfx1:Play() end
		if equipSfx2 then equipSfx2:Play() end

	end

	local function clearBoth()
		clearSpeed()
		restoreJump()
		removeForce()
		disconnectAll()
	end

	Tool.Equipped:Connect(applyBoth)
	Tool.Unequipped:Connect(clearBoth)
end

return CoilCombo
