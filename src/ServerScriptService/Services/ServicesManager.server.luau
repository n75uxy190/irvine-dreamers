local Services = game:GetService("ServerScriptService").Services

local LikeService = require(Services.LikeService)

task.spawn(function()
	LikeService:Start()
end)