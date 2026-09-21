-- LocalScript inside ServerStorage.Tools.MedusaHead (cloned to player)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Events = Remotes:WaitForChild("Events")
local MedusaTransform = Events:WaitForChild("MedusaTransform")

local ToolsConfig = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Tools"))
local Tool = script.Parent
local Config = ToolsConfig[Tool.Name] or ToolsConfig["MedusaHead"] or {}

local MAX_DISTANCE = tonumber(Config.Range) or 15
local Equipped = false
local Cooldown = tonumber(Config.Cooldown) or 25
local lastUse = 0

local CooldownGui = Tool:FindFirstChild("CooldownGui")
local CooldownLabel = CooldownGui and CooldownGui:FindFirstChild("CooldownLabel")

local function StartCooldownDisplay(time)
	if not CooldownGui or not CooldownLabel then return end
	CooldownGui.Enabled = true
	for i = time, 1, -1 do -- ✅ stop at 1 (not 0)
		if not Equipped then CooldownGui.Enabled = false return end
		CooldownLabel.Text = i
		task.wait(1)
	end
	CooldownGui.Enabled = false
end

local EDGE_COUNT = 36
local EDGE_THICKNESS = 0.2
local EDGE_HEIGHT = 0.05
local edges = {}

for i = 1, EDGE_COUNT do
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(EDGE_THICKNESS, EDGE_HEIGHT, EDGE_THICKNESS)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255,0,0)
	part.Parent = workspace
	table.insert(edges, part)
end

local function updateEdgePositions()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local hrpPos = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,0.1,0)
	for i, part in ipairs(edges) do
		local angle = (i/EDGE_COUNT) * math.pi * 2
		local x = math.cos(angle) * MAX_DISTANCE
		local z = math.sin(angle) * MAX_DISTANCE
		part.Position = hrpPos + Vector3.new(x,0,z)
	end
end

RunService.RenderStepped:Connect(function()
	if not Equipped then return end
	updateEdgePositions()
end)

Tool.Equipped:Connect(function()
	Equipped = true
	local elapsed = tick() - lastUse
	if elapsed < Cooldown then
		local remaining = math.ceil(Cooldown - elapsed)
		task.spawn(StartCooldownDisplay, remaining)
	end
	RunService:BindToRenderStep("MedusaEdgeCircle", Enum.RenderPriority.Camera.Value, updateEdgePositions)
end)

Tool.Unequipped:Connect(function()
	Equipped = false
	if CooldownGui then CooldownGui.Enabled = false end
	RunService:UnbindFromRenderStep("MedusaEdgeCircle")
	for _, part in ipairs(edges) do
		part.Position = Vector3.new(0,-9999,0)
	end
end)

Tool.Activated:Connect(function()
	if tick() - lastUse < Cooldown then return end -- ✅ proper cooldown lock

	local ok, result = pcall(function()
		return MedusaTransform:InvokeServer()
	end)

	if not ok then
		warn("[MedusaLocal] MedusaTransform invoke failed:", result)
		return
	end

	if type(result) == "number" and result > 0 then
		lastUse = tick()
		task.spawn(StartCooldownDisplay, Cooldown)
	end
end)
