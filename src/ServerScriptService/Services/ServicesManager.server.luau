local Services = game:GetService("ServerScriptService").Services

local LikeService = require(Services.LikeService)
local ConveyorService = require(Services.ConveyorService)
local RepairService = require(Services.RepairService)
local SabotageService = require(Services.SabotageService)

task.spawn(function()
	LikeService:Start()
end)

task.spawn(function()
	ConveyorService:Start()
end)

task.spawn(function()
	RepairService:Start()
end)

task.spawn(function()
	SabotageService:Start()
end)