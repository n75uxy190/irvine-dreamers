local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage.Remotes.Events:WaitForChild("BodySwapEvent")

local BodySwap = {}

function BodySwap.Attach(data)
	local tool = data.Tool
	local player = data.Player

	event.OnServerEvent:Connect(function(p, target)
		if p ~= player then return end
		if not target or not target.Character then return end
		if not player.Character then return end

		local root1 = player.Character:FindFirstChild("HumanoidRootPart")
		local root2 = target.Character:FindFirstChild("HumanoidRootPart")
		if not root1 or not root2 then return end

		local pos1 = root1.CFrame
		root1.CFrame = root2.CFrame
		root2.CFrame = pos1
	end)
end

return BodySwap
