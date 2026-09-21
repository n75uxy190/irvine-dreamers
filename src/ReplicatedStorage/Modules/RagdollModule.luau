-- Ragdoll Module (clean + realistic)
-- Uses smooth ragdoll system similar to the other game but matches your original API

local RagdollModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent (create this in ReplicatedStorage.Remotes.Events)
local RagdollEvent = ReplicatedStorage:WaitForChild("Remotes")
	:WaitForChild("Events")
	:FindFirstChild("RagdollEvent")

-- fallback if not present
if not RagdollEvent then
	RagdollEvent = Instance.new("RemoteEvent")
	RagdollEvent.Name = "RagdollEvent"
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
	folder.Name = "Remotes"
	local events = folder:FindFirstChild("Events") or Instance.new("Folder", folder)
	events.Name = "Events"
	RagdollEvent.Parent = events
end

-- Create joint constraints like in the other game's ragdoll
local function ConvertToRagdoll(character)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid:GetState() == Enum.HumanoidStateType.Physics then
		return humanoid
	end

	-- Prevent unwanted deaths
	humanoid.BreakJointsOnDeath = false

	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local part0, part1 = joint.Part0, joint.Part1
			if part0 and part1 then
				-- attachments for ragdoll
				local att0 = Instance.new("Attachment")
				att0.Name = joint.Name .. "_Att0"
				att0.CFrame = joint.C0
				att0.Parent = part0

				local att1 = Instance.new("Attachment")
				att1.Name = joint.Name .. "_Att1"
				att1.CFrame = joint.C1
				att1.Parent = part1

				local constraint
				if joint.Name == "Root" or joint.Name == "Neck" then
					constraint = Instance.new("HingeConstraint")
				else
					constraint = Instance.new("BallSocketConstraint")
					constraint.LimitsEnabled = true
					constraint.TwistLimitsEnabled = true
				end

				constraint.Attachment0 = att0
				constraint.Attachment1 = att1
				constraint.Parent = part0
				joint.Enabled = false
			end
		end
	end

	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	return humanoid
end

-- Remove ragdoll constraints and restore motors
local function Unragdoll(character)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local p0, p1 = joint.Part0, joint.Part1
			if p0 and p1 then
				local att0 = p0:FindFirstChild(joint.Name .. "_Att0")
				local att1 = p1:FindFirstChild(joint.Name .. "_Att1")
				if att0 then att0:Destroy() end
				if att1 then att1:Destroy() end
			end
			joint.Enabled = true
		end
	end

	for _, constraint in ipairs(character:GetDescendants()) do
		if constraint:IsA("BallSocketConstraint") or constraint:IsA("HingeConstraint") then
			constraint:Destroy()
		end
	end

	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Timed ragdoll
function RagdollModule.TimedRagdoll(character, duration)
	local humanoid = ConvertToRagdoll(character)
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if player and RagdollEvent then
		RagdollEvent:FireClient(player, "Start", duration)
	end

	task.delay(duration or 2, function()
		Unragdoll(character)
		if player and RagdollEvent then
			RagdollEvent:FireClient(player, "End")
		end
	end)
end

RagdollModule.Ragdoll = ConvertToRagdoll
RagdollModule.Unragdoll = Unragdoll

return RagdollModule
