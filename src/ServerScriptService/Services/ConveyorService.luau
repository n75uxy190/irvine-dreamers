--[[
	Temporary debug spawner — NOT the real conveyor integration. Rolls a
	PCUnit on a timer and renders it as colored boxes so the container
	logic is visible in an actual playtest, without wiring the real
	Waypoints/Base pipeline yet (that's a deliberately separate, later
	step — see journal/003 and journal/005).

	This is the sanctioned front door for "make a visible PC appear."
	Nothing else should call PCFactory.roll() or PCUnitDebugView.render()
	directly once this exists.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local PCFactory = require(ServerStorage.Modules.PCRepair.PCFactory)
local PCUnitDebugView = require(ServerStorage.Modules.PCRepair.PCUnitDebugView)

local ConveyorService = {}

local SPAWN_INTERVAL_SECONDS = 15
local SPAWN_DISTANCE_STUDS = 10

-- Places it in front of wherever the player is currently facing, recomputed
-- fresh each tick (not baked in once) since the player moves between ticks.
local function spawnInFrontOf(player: Player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return -- player hasn't spawned in yet this tick; just skip, don't error
	end

	local anchorCFrame = rootPart.CFrame * CFrame.new(0, 0, -SPAWN_DISTANCE_STUDS)
	local pcUnit = PCFactory.roll()
	local model = PCUnitDebugView.render(pcUnit, anchorCFrame)
	model.Parent = workspace
end

function ConveyorService:Start()
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL_SECONDS)

			for _, player in Players:GetPlayers() do
				spawnInFrontOf(player)
			end
		end
	end)
end

return ConveyorService
