return function(player)
	local tool = script.Parent.Parent;
	local players = game:GetService("Players");
	local main = script:WaitForChild("Rainbow"):Clone();
	
	local localScript = main:WaitForChild("RainbowClient");
	localScript.Player.Value = player;
	localScript.Tool.Value = tool;
	
	local inject = function(player)
		local try = main:Clone();
		try.RainbowClient.Disabled = false;
		try.Parent = player.PlayerGui;
	end
	
	for _,player in pairs(players:GetPlayers()) do
		inject(player);
	end
	players.PlayerAdded:Connect(function(player)
		inject(player);
	end)
end