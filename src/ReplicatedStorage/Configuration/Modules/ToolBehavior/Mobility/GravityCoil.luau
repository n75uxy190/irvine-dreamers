local Util = require(script.Parent.Parent._Shared.Util)
local RunService = game:GetService("RunService")

local GravityCoil = {}

function GravityCoil.Attach(ctx)
	local Tool = ctx.Tool
	local Humanoid = ctx.Humanoid
	local cfg = ctx.Configuration

	local handle = Tool:FindFirstChild("Handle")
	local equipSfx = Util.ensureSound(handle, "EquippedSound", cfg.EquippedSound)

	-- CONFIG INTERPRETATION
	-- Prefer explicit counter percent (0..1). If not present, fall back to "remaining gravity" like Luckymaxer.
	-- Examples:
	--   GravityCounterPercent = 0.75   --> counter 75% of gravity (slow fall)
	--   GravityPercentRemaining = 0.25 --> 25% gravity left => counter 75%  (Luckymaxer style)
	--   Gravity = 25                   --> treat as PercentRemaining if above 1 -> 0.25
	local counterPercent = tonumber(cfg.GravityCounterPercent)
	if not counterPercent then
		local remaining = tonumber(cfg.GravityPercentRemaining)
		if not remaining then
			-- Back-compat with "Gravity" you had earlier; treat as "remaining" if >1 (given as a percent).
			remaining = tonumber(cfg.Gravity)
			if remaining and remaining > 1 then
				remaining = remaining / 100
			end
		end
		remaining = remaining or 0.25 -- default like Luckymaxer
		counterPercent = 1 - remaining
	end
	counterPercent = math.clamp(counterPercent, 0, 0.95) -- avoid near-weightless instability

	-- Optional: JumpMultiplier support (defaults off / 1.0)
	local jumpMul = tonumber(cfg.JumpMultiplier)
	if jumpMul == nil then jumpMul = 1.0 end
	jumpMul = math.max(jumpMul, 0)

	local hrp, vforce, attachment
	local conns = {}
	local hbConn
	local saved = { UseJumpPower = nil, JumpPower = nil, JumpHeight = nil }

	local function disconnectAll()
		for _, c in ipairs(conns) do
			if c and c.Disconnect then c:Disconnect() end
		end
		table.clear(conns)
		if hbConn and hbConn.Disconnect then hbConn:Disconnect() end
		hbConn = nil
	end

	local function removeForces()
		if vforce then vforce:Destroy() vforce = nil end
		if attachment then attachment:Destroy() attachment = nil end
	end

	local function restoreJump()
		if Humanoid and Humanoid.Parent and saved.UseJumpPower ~= nil then
			if saved.UseJumpPower then
				if saved.JumpPower then Humanoid.JumpPower = saved.JumpPower end
				Humanoid.UseJumpPower = true
			else
				if saved.JumpHeight then Humanoid.JumpHeight = saved.JumpHeight end
				Humanoid.UseJumpPower = false
			end
		end
		saved.UseJumpPower, saved.JumpPower, saved.JumpHeight = nil, nil, nil
	end

	local function gentleApplyJumpBoost()
		if jumpMul == 1.0 or saved.UseJumpPower ~= nil then return end
		if not Humanoid then return end
		saved.UseJumpPower = Humanoid.UseJumpPower
		if saved.UseJumpPower then
			saved.JumpPower = Humanoid.JumpPower
			Humanoid.JumpPower = (Humanoid.JumpPower > 0 and Humanoid.JumpPower or 50) * jumpMul
		else
			saved.JumpHeight = Humanoid.JumpHeight
			Humanoid.JumpHeight = (Humanoid.JumpHeight > 0 and Humanoid.JumpHeight or 7.2) * jumpMul
		end
	end

	local function recomputeForce()
		if not (hrp and vforce) then return end
		-- Force = mass * g * counterPercent (World relative, so straight up)
		local mass = hrp.AssemblyMass or hrp:GetMass()
		local g = workspace.Gravity
		vforce.Force = Vector3.new(0, mass * g * counterPercent, 0)
	end

	local function apply()
		if not Humanoid or Humanoid.Health <= 0 then return end
		local character = Humanoid.Parent
		if not character then return end

		hrp = character:FindFirstChild("HumanoidRootPart")
		if not (hrp and hrp:IsA("BasePart")) then return end

		-- Build VectorForce (modern BodyForce), world-relative, constant upward
		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Name = "GravityCoilAttachment"
			attachment.Parent = hrp
		end
		if not vforce then
			vforce = Instance.new("VectorForce")
			vforce.Name = "GravityCoilForce"
			vforce.ApplyAtCenterOfMass = true
			vforce.RelativeTo = Enum.ActuatorRelativeTo.World
			vforce.Attachment0 = attachment
			vforce.Parent = hrp
		end

		gentleApplyJumpBoost()
		recomputeForce()

		if equipSfx then equipSfx:Play() end

		-- Smoothly keep force correct as mass/rig changes (like the old script)
		-- Recompute every Heartbeat (cheap) to get truly continuous behavior.
		if not hbConn then
			hbConn = RunService.Heartbeat:Connect(recomputeForce)
		end

		-- Also recompute on structural changes
		table.insert(conns, character.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") or d:IsA("Accessory") then task.defer(recomputeForce) end
		end))
		table.insert(conns, character.DescendantRemoving:Connect(function(d)
			if d:IsA("BasePart") or d:IsA("Accessory") then task.defer(recomputeForce) end
		end))

		-- Clean on death
		table.insert(conns, Humanoid.Died:Connect(function()
			removeForces()
			restoreJump()
			disconnectAll()
		end))
	end

	local function clear()
		removeForces()
		restoreJump()
		disconnectAll()
	end

	Tool.Equipped:Connect(apply)
	Tool.Unequipped:Connect(clear)
end

return GravityCoil
