local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BeeAttackRemote = ReplicatedStorage.Remotes.Events:WaitForChild("BeeAttack")

local module = {}

function module.Attach(data)
	local Tool = data.Tool
	local Player = data.Player

	BeeAttackRemote.OnServerEvent:Connect(function(p, target)
		if p ~= Player then return end
		if not target or not target.Character then return end
		if not Player.Character then return end

		BeeAttackRemote:FireClient(target)
	end)
end

return module
