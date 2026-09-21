local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Traits = require(ServerStorage:WaitForChild("Configuration"):WaitForChild("Modules"):WaitForChild("Traits"))
local Events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")

local function SendActiveTraits(player)
	for traitName, endTime in pairs(Traits.ActiveTraits or {}) do
		local remainingTime = math.max(0, endTime - os.time())
		if remainingTime > 0 then
			local traitData = Traits[traitName]
			if traitData then
				Events.EventHandler:FireClient(player, "Start", {
					Name = traitName,
					Icon = traitData.Icon,
					Time = remainingTime
				})
			end
		end
	end
end

local function SetupPlayer(player)
	SendActiveTraits(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		SendActiveTraits(player)
	end)
end

Players.PlayerAdded:Connect(SetupPlayer)

for _, player in pairs(Players:GetPlayers()) do
	SetupPlayer(player)
end
