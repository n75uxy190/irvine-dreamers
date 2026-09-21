--[[
	  _____                                          _     _____                      _   
	 |  __ \                                        | |   / ____|                    | |  
	 | |__) |_____   ____ _ _ __ ___  _ __   ___  __| |  | |     __ _ _ __ _ __   ___| |_ 
	 |  _  // _ \ \ / / _` | '_ ` _ \| '_ \ / _ \/ _` |  | |    / _` | '__| '_ \ / _ \ __|
	 | | \ \  __/\ V / (_| | | | | | | |_) |  __/ (_| |  | |___| (_| | |  | |_) |  __/ |_ 
	 |_|  \_\___| \_/ \__,_|_| |_| |_| .__/ \___|\__,_|   \_____\__,_|_|  | .__/ \___|\__|
	                                 | |                                  | |             
	                                 |_|                                  |_|             

	Rewritten by: @Jumpathy
	Description: A more functional rainbow carpet with some changes for ease.
	Post: https://devforum.roblox.com/t/revamped-rainbow-carpet-r15-r6/1523705
	
]]

local replicateToClients = require(script:WaitForChild("Replicate"));

Tool = script.Parent
Handle = Tool:WaitForChild("Handle")

Players = game:GetService("Players")
Debris = game:GetService("Debris")

Animations = {
	Sit = {Animation = Tool:WaitForChild("Sit"), FadeTime = nil, Weight = nil, Speed = nil, Duration = nil},
}

Grips = {
	Normal = CFrame.new(-1.5, 0, 0, 0, 0, -1, -1, 8.90154915e-005, 0, 8.90154915e-005, 1, 0),
	Flying = {
		R15 = CFrame.new( -1.46242523, 0.488422394, -2.75067139, -0.999812543, -0.0134475874, -0.0139287189, -0.0165850967, 0.223699123, 0.974517226, -0.00998906139, 0.974565566, -0.223880216),
		R6 =  CFrame.new(-1.5, 0.5, -0.75, -1, 0, -8.99756625e-009, -8.99756625e-009, 8.10000031e-008, 1, 7.28802977e-016, 0.99999994, -8.10000103e-008)
	}
}

Flying = false
ToolEquipped = false

ServerControl = (Tool:FindFirstChild("ServerControl") or Instance.new("RemoteFunction"))
ServerControl.Name = "ServerControl"
ServerControl.Parent = Tool

ClientControl = (Tool:FindFirstChild("ClientControl") or Instance.new("RemoteFunction"))
ClientControl.Name = "ClientControl"
ClientControl.Parent = Tool

Handle.Transparency = 0
Tool.Grip = Grips.Normal
Tool.Enabled = true

function CheckIfAlive()
	return (((Character and Character.Parent and Humanoid and Humanoid.Parent and Humanoid.Health > 0 and Torso and Torso.Parent and Player and Player.Parent) and true) or false)
end

local lastTrack;
local StopLastAnimation = function()
	if(lastTrack) then
		lastTrack:Stop();
		lastTrack = nil;
	end
end

local PlayAnimation = function(character,animation)
	local humanoid = character:FindFirstChildOfClass("Humanoid");
	if(humanoid) then
		local animator = humanoid:FindFirstChildOfClass("Animator");
		if(animator) then
			local animationTrack = animator:LoadAnimation(animation);
			animationTrack:Play();
			lastTrack = animationTrack;
		end
	end
end

function Activated()
	if not Tool.Enabled then
		return
	end
	Tool.Enabled = false
	Flying = not Flying
	if Flying then
		spawn(function()
			local isR15 = Player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15
			local rigType = (isR15 and "R15" or "R6");
			PlayAnimation(Player.Character,Animations.Sit.Animation);
			Tool.Grip = Grips.Flying[rigType]
		end)

		Torso.Anchored = true
		delay(.2,function()
			Torso.Anchored = false
			Torso.Velocity = Vector3.new(0,0,0)
			Torso.RotVelocity = Vector3.new(0,0,0)
		end)

		FlightSpin = Instance.new("BodyGyro")
		FlightSpin.Name = "FlightSpin"
		FlightSpin.P = 10000
		FlightSpin.MaxTorque = Vector3.new(FlightSpin.P, FlightSpin.P, FlightSpin.P)*100
		FlightSpin.CFrame = Torso.CFrame

		FlightPower = Instance.new("BodyVelocity")
		FlightPower.Name = "FlightPower"
		FlightPower.Velocity = Vector3.new(0, 0, 0)
		FlightPower.MaxForce = Vector3.new(0, 0, 0)	--Vector3.new(1,1,1)*1000000
		FlightPower.P = 1000

		FlightHold = Instance.new("BodyPosition")
		FlightHold.Name = "FlightHold"
		FlightHold.P = 100000
		FlightHold.MaxForce = Vector3.new(0, 0, 0)
		FlightHold.Position = Torso.Position

		FlightSpin.Parent = Torso
		FlightPower.Parent = Torso
		FlightHold.Parent = Torso

		spawn(function()
			local LastPlace = nil
			while Flying and ToolEquipped and CheckIfAlive() do
				game:GetService("RunService").Heartbeat:Wait();
				Tool:SetAttribute("IsGoing",true);
			end
			Tool:SetAttribute("IsGoing",false);
		end)
	elseif not Flying then
		Torso.Velocity = Vector3.new(0, 0, 0)
		Torso.RotVelocity = Vector3.new(0, 0, 0)

		for i, v in pairs({FlightSpin, FlightPower, FlightHold}) do
			if v and v.Parent then
				v:Destroy()
			end
		end
		spawn(function()
			Tool.Grip = Grips.Normal
			StopLastAnimation();
		end)
	end

	wait(2)

	Tool.Enabled = true
end

local linked = {};
function Equipped(Mouse)
	Tool:SetAttribute("Equipped",true);
	Character = Tool.Parent
	Humanoid = Character:FindFirstChild("Humanoid")
	Torso = Character:FindFirstChild("HumanoidRootPart")
	Player = Players:GetPlayerFromCharacter(Character)
	if(not linked[Player]) then
		replicateToClients(Player);
		linked[Player] = true;
	end
	if not CheckIfAlive() then
		return
	end
	if Humanoid then
		if Humanoid.RigType == Enum.HumanoidRigType.R15 then
			Animations = {
				Sit = {Animation = Tool:WaitForChild("SitR15"), FadeTime = nil, Weight = nil, Speed = nil, Duration = nil},
			}
		else
			Animations = {
				Sit = {Animation = Tool:WaitForChild("Sit"), FadeTime = nil, Weight = nil, Speed = nil, Duration = nil},
			}
		end
	end
	Tool.Grip = Grips.Normal
	ToolEquipped = true
end

function Unequipped()
	Tool:SetAttribute("Equipped",false);
	Flying = false
	for i, v in pairs({FlightSpin, FlightPower, FlightHold}) do
		if v and v.Parent then
			v:Destroy()
		end
	end
	ToolEquipped = false
	StopLastAnimation();
end

function OnServerInvoke(player, mode, value)
	if player ~= Player or not ToolEquipped or not value or not CheckIfAlive() then
		return
	end
end

function InvokeClient(Mode, Value)
	local ClientReturn = nil
	pcall(function()
		ClientReturn = ClientControl:InvokeClient(Player, Mode, Value)
	end)
	return ClientReturn
end

ServerControl.OnServerInvoke = OnServerInvoke
Tool.Activated:Connect(Activated)
Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)