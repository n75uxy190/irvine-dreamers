local Util = require(script.Parent.Parent._Shared.Util)

local SpeedCoil = {}

function SpeedCoil.Attach(ctx)
	local Tool = ctx.Tool
	local Humanoid = ctx.Humanoid
	local cfg = ctx.Configuration

	local speed = tonumber(cfg.Speed)
	if not speed then return end
	local additive = cfg.AdditiveSpeed == true
	local handle = Tool:FindFirstChild("Handle")
	local equipSfx = Util.ensureSound(handle, "EquippedSound", cfg.EquippedSound)

	local original

	local function apply()
		if not Humanoid or Humanoid.Health <= 0 then return end
		if original == nil then original = Humanoid.WalkSpeed end
		Humanoid.WalkSpeed = additive and (original or 30) + speed or speed
		if equipSfx then equipSfx:Play() end
	end

	local function clear()
		if Humanoid and original ~= nil then Humanoid.WalkSpeed = original end
		original = nil
	end

	Tool.Equipped:Connect(apply)
	Tool.Unequipped:Connect(clear)
	if Humanoid then Humanoid.Died:Connect(clear) end
end

return SpeedCoil
