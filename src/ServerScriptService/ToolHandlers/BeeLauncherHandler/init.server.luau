local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BeeAttackRemote = ReplicatedStorage.Remotes.Events:WaitForChild("BeeAttack")

BeeAttackRemote.OnServerEvent:Connect(function(player, targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	local head = targetPlayer.Character:FindFirstChild("Head")
	local tool = player.Backpack:FindFirstChild("BeeLauncher") or player.Character:FindFirstChild("BeeLauncher")
	if not head or not tool then return end

	local particleTemplate = script:FindFirstChild("BeeParticle")
	if particleTemplate then
		local particle = particleTemplate:Clone()
		particle.Enabled = true
		particle.Parent = head

		-- Clean up after 5 seconds
		task.delay(5, function()
			if particle then
				particle.Enabled = false
				particle:Destroy()
			end
		end)
	end

	-- Tell the target player client to apply camera shake, buzzing, color correction, and invert controls
	BeeAttackRemote:FireClient(targetPlayer)
end)
