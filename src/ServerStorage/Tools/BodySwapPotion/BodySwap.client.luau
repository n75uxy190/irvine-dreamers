local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BodySwapEvent = Remotes.Events:WaitForChild("BodySwapEvent")

-- Reference Tools module for configuration
local ToolsConfig = require(ReplicatedStorage.Configuration.Modules.Tools)
local Config = ToolsConfig[script.Parent.Name]

local MAX_DISTANCE = Config.Range or 40
local HighlightedChar = nil
local Equipped = false -- Track if the player is holding the tool

-- Cooldown
local Cooldown = Config.Cooldown or 30
local lastUse = 0

-- GUI references
local Tool = script.Parent
local CooldownGui = Tool:FindFirstChild("CooldownGui")
local CooldownLabel = CooldownGui and CooldownGui:FindFirstChild("CooldownLabel")

-- Function to highlight enemy
local function HighlightTarget(character)
	if HighlightedChar == character then return end

	if HighlightedChar then
		for _, v in ipairs(HighlightedChar:GetChildren()) do
			if v:IsA("Highlight") then v:Destroy() end
		end
	end

	HighlightedChar = character

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 200, 200)
	highlight.Parent = character
end

local function RemoveHighlight()
	if HighlightedChar then
		for _, v in ipairs(HighlightedChar:GetChildren()) do
			if v:IsA("Highlight") then v:Destroy() end
		end
		HighlightedChar = nil
	end
end

-- Track nearest player only when tool is equipped
RunService.RenderStepped:Connect(function()
	if not Equipped then
		RemoveHighlight()
		return
	end

	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local target = nil
	local mouseTarget = Mouse.Target

	if mouseTarget then
		local char = mouseTarget:FindFirstAncestorWhichIsA("Model")

		if char then
			local targetPlayer = Players:GetPlayerFromCharacter(char)

			if targetPlayer and targetPlayer ~= LocalPlayer then
				local distance = (LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
				if distance <= MAX_DISTANCE then
					target = char
				end
			end
		end
	end

	if target then
		HighlightTarget(target)
	else
		RemoveHighlight()
	end
end)

-- Cooldown GUI function
local function StartCooldown()
	if not CooldownGui or not CooldownLabel then return end
	CooldownGui.Enabled = true
	for i = Cooldown, 1, -1 do -- ✅ stops at 1 instead of 0
		if not Equipped then CooldownGui.Enabled = false return end -- hides if unequipped
		CooldownLabel.Text = i
		task.wait(1)
	end
	CooldownGui.Enabled = false
end

-- Tool events
Tool.Equipped:Connect(function()
	Equipped = true
	if tick() - lastUse < Cooldown then
		local remaining = math.ceil(Cooldown - (tick() - lastUse))
		task.spawn(function()
			if not CooldownGui or not CooldownLabel then return end
			CooldownGui.Enabled = true
			for i = remaining, 1, -1 do -- ✅ stops at 1
				if not Equipped then CooldownGui.Enabled = false return end
				CooldownLabel.Text = i
				task.wait(1)
			end
			CooldownGui.Enabled = false
		end)
	end
end)

Tool.Unequipped:Connect(function()
	Equipped = false
	RemoveHighlight()
	if CooldownGui then
		CooldownGui.Enabled = false
	end
end)

-- Tool activation with cooldown only on successful swap
Tool.Activated:Connect(function()
	if not HighlightedChar then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(HighlightedChar)
	if not targetPlayer then
		return
	end

	local now = tick()
	if now - lastUse < Cooldown then
		return -- ✅ strict cooldown
	end

	BodySwapEvent:FireServer(targetPlayer)
	lastUse = now
	task.spawn(StartCooldown)
end)
