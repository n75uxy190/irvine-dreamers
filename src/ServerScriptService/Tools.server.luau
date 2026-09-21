local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Tools = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Tools"))
local ToolBehavior = ReplicatedStorage.Configuration.Modules:WaitForChild("ToolBehavior")
local ReturnStolenThingEvent = ServerStorage.Bindables.Events:WaitForChild("ReturnStolenThing")

local ToolEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Tool")

local ToolData = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RagdollModule = require(ReplicatedStorage.Modules:WaitForChild("RagdollModule"))

local function Fling(TargetPlayer, AttackerPlayer, Power)
	local targetChar = TargetPlayer.Character
	local attackerChar = AttackerPlayer.Character
	if not targetChar or not attackerChar then return end

	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not attackerRoot or not targetHum then return end

	-- Apply realistic ragdoll for 2 seconds
	RagdollModule.TimedRagdoll(targetChar, 2)

	-- Add clean physics impulse
	local direction = (targetRoot.Position - attackerRoot.Position).Unit
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = (direction + Vector3.new(0, 0.8, 0)).Unit * (Power or 50)
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.P = 1e4
	bodyVelocity.Parent = targetRoot

	-- Add angular spin for natural effect
	local bodyAngular = Instance.new("BodyAngularVelocity")
	bodyAngular.AngularVelocity = Vector3.new(math.random(), math.random(), math.random()) * math.pi * 2
	bodyAngular.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyAngular.P = 5e3
	bodyAngular.Parent = targetRoot

	-- Cleanup after short delay
	Debris:AddItem(bodyVelocity, 0.4)
	Debris:AddItem(bodyAngular, 0.4)
end

-- Added

local function categorize(cfg)
	if typeof(cfg.Category) == "string" and cfg.Category ~= "" then return cfg.Category end
	if tonumber(cfg.Power) then return "Combat" end
	if tonumber(cfg.Speed) then return "Mobility" end
	return "Generic"
end

local function requireBehavior(category, name)
	local folder = ToolBehavior:FindFirstChild(category)
	if not folder then return nil end
	local mod = folder:FindFirstChild(name) or folder:FindFirstChild("_Default")
	return mod and require(mod) or nil
end

local function GiveTool(Player, Name, Configuration)
	local Backpack = Player:FindFirstChild("Backpack")
	local Character = Player.Character
	if not Character or not Character:IsDescendantOf(workspace) then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	if not Backpack or not Character then return end
	if Backpack:FindFirstChild(Name) or Character:FindFirstChild(Name) then return end

	local ToolTemplate = ServerStorage.Tools:FindFirstChild(Name)
	if not ToolTemplate then return end

	local Tool = ToolTemplate:Clone()
	Tool.Name = Name
	Tool.CanBeDropped = false
	Tool.ToolTip = Configuration.Description or ""
	Tool.TextureId = Configuration.Icon or ""

	local ToolsFolder = Player:FindFirstChild("Tools")
	Tool.Parent = ToolsFolder or Backpack
	ToolData[Player][Name].Owned = true

	-- Animation setup (optional)
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)
	local CharacterConfiguration = Character:FindFirstChildOfClass("Configuration")
	if not CharacterConfiguration then
		CharacterConfiguration = Instance.new("Configuration")
		CharacterConfiguration.Parent = Character
	end
	local AnimationsFolder = CharacterConfiguration:FindFirstChild("Animations")
	if not AnimationsFolder then
		AnimationsFolder = Instance.new("Folder")
		AnimationsFolder.Name = "Animations"
		AnimationsFolder.Parent = CharacterConfiguration
	end

	local ActivationTrack
	if Configuration.ActivationAnimation and Configuration.ActivationAnimation ~= "" then
		local animName = string.format("%sActivationAnimation", Name)
		local ActivationAnimation = AnimationsFolder:FindFirstChild(animName)
		if not ActivationAnimation then
			ActivationAnimation = Instance.new("Animation")
			ActivationAnimation.Name = animName
			ActivationAnimation.Parent = AnimationsFolder
		end
		ActivationAnimation.AnimationId = Configuration.ActivationAnimation
		ActivationTrack = Animator:LoadAnimation(ActivationAnimation)
	end

	local Handle = Tool:FindFirstChild("Handle")
	local ActivationSound
	if Handle then
		-- reuse shared Util if you want, or inline:
		if Configuration.ActivationSound and Configuration.ActivationSound ~= "" then
			ActivationSound = Handle:FindFirstChild("ActivationSound") or Instance.new("Sound")
			ActivationSound.Name = "ActivationSound"
			ActivationSound.SoundId = Configuration.ActivationSound
			ActivationSound.Volume = 2
			ActivationSound.RollOffMode = Enum.RollOffMode.Linear
			ActivationSound.RollOffMaxDistance = 90
			ActivationSound.Parent = Handle
		end
	end

	-- Dispatch to per-tool behavior
	local category = categorize(Configuration)
	local behavior = requireBehavior(category, Name)

	if behavior and behavior.Attach then
		behavior.Attach({
			Player = Player,
			Character = Character,
			Humanoid = Humanoid,
			Tool = Tool,
			Configuration = Configuration,
			ActivationTrack = ActivationTrack,
			ActivationSound = ActivationSound,

			-- pass shared services/utilities a behavior might need:
			Fling = Fling,
			ReturnStolenThingEvent = ReturnStolenThingEvent,
			Players = Players,
		})
	else
		-- Optional safe default: just play activation anim/sound on click
		if ActivationTrack or ActivationSound then
			Tool.Activated:Connect(function()
				if ActivationTrack then ActivationTrack:Play() end
				if ActivationSound then ActivationSound:Play() end
			end)
		end
	end

end


---------------------------

local function GiveAllTools(Player)
	if not ToolData[Player] then return end
	for Name, Data in pairs(ToolData[Player]) do
		if Data.Owned then
			local Configuration = Tools[Name]
			if Configuration then
				GiveTool(Player, Name, Configuration)
			end
		end
	end
end

Players.PlayerAdded:Connect(function(Player)
	ToolData[Player] = {}

	for Name, Configuration in pairs(Tools) do
		if Configuration.Starter then
			ToolData[Player][Name] = {Owned = true}
		else
			ToolData[Player][Name] = {Owned = false}
		end
	end

	Player.CharacterAdded:Connect(function()
		GiveAllTools(Player)
	end)

	if Player.Character then
		GiveAllTools(Player)
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	ToolData[Player] = nil
end)

ToolEvent.OnServerEvent:Connect(function(Player, Name)
	local Configuration = Tools[Name]
	if not Configuration or Configuration.Starter then return end

	local Leaderstats = Player:FindFirstChild("leaderstats")
	if not Leaderstats then return end

	local Money = Leaderstats:FindFirstChild("Money")
	local Rebirths = Leaderstats:FindFirstChild("Rebirths")
	if not Money or not Rebirths then return end

	if Money.Value < (Configuration.Price or 0) then return end
	if Rebirths.Value < (Configuration.Rebirth or 0) then return end

	Money.Value = Money.Value - Configuration.Price

	ToolData[Player][Name].Owned = true
	GiveTool(Player, Name, Configuration)
end)