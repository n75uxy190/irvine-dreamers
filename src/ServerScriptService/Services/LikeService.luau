-- LikeService.server.lua
local LikeService = {}

--// ====== EASY CONFIG ======
local Config = {
	-- How often to poll (seconds)
	PollInterval = 10,

	-- Milestone step (e.g., every +10 likes)
	MilestoneStep = 1,

	-- Optional: set a minimum next milestone if your game is brand new
	MinFirstMilestone = 100,

	-- Rewards:
	-- 1) Exact milestone overrides (e.g., at 100 likes, grant a specific thing)
	--    You can now set RewardText = "Secret" (or any label you want shown).
	-- 2) Fallback "Rolling" weighted pool used when no exact override exists.
	Rewards = {
		[100] = {
			Global = true, Amount = 1, Name = "Cracky4", Traits = {}, Mutation = "Default",
			RewardText = "Secret",      -- <- what to DISPLAY on the sign
		},
		[500] = {
			Global = true, Amount = 1, Name = "Mygame43", Traits = {}, Mutation = "Default",
			RewardText = "Secret",
		},
		[1000] = {
			Global = true, Amount = 1, Name = "Rip_indra", Traits = {}, Mutation = "Default",
			RewardText = "Secret",
		},

		-- Fallback rolling pool (used for all other milestones)
		Rolling = {
			Global = true,               -- default behavior for pool rolls
			Amount = 1,                  -- default amount for pool rolls
			Mutation = "Default",        -- default mutation for pool rolls
			Traits = {},                 -- default traits for pool rolls
			RewardText = "Secret",       -- <- default text to display when using the pool
			Chances = {                  -- weighted options
				["Cracky4"] = 100,
			}
		}
	},
}
--// ====== END CONFIG ======

-- Services
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local Rarities = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Rarities"))

-- EasyVisuals (optional)
local EasyVisuals = nil
pcall(function()
	EasyVisuals = require(ReplicatedStorage.Modules:WaitForChild("EasyVisuals"))
end)

-- UI paths: adjust if yours differs
local LikeBar = workspace:WaitForChild("LikeSign").Main.SurfaceGui.MainFrame.ProgressBar.Bar
local RewardText = LikeBar.Parent.Parent.Message:WaitForChild("RewardText")

-- State
local likeMilestone = Config.MinFirstMilestone
local hasInitialized = false

-- Utils
local function formatWithCommas(num: number): string
	return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function clamp01(x) return math.clamp(x, 0, 1) end

local function nextMultipleOf(step, x)
	if step <= 0 then return x end
	return math.floor(x/step)*step + step
end

local function pickFromWeights(weights: {[string]: number}): string?
	local total = 0
	for _, w in pairs(weights) do
		if w and w > 0 then total += w end
	end
	if total <= 0 then return nil end
	local r, acc = math.random() * total, 0
	for name, w in pairs(weights) do
		if w and w > 0 then
			acc += w
			if r <= acc then return name end
		end
	end
	return nil
end

-- Visuals helper: if label matches a rarity key, use its Colour + VisualsPreset
local function applyRarityVisualsFromLabel(labelText: string)
	local rc = labelText and Rarities[labelText] or nil
	if rc then
		if typeof(rc.Colour) == "Color3" then
			RewardText.TextColor3 = rc.Colour
		else
			RewardText.TextColor3 = Color3.new(1,1,1)
		end
		if EasyVisuals and rc.VisualsPreset then
			pcall(function()
				task.wait(0.5)
				EasyVisuals.new(RewardText, rc.VisualsPreset, 0.35)
			end)
		end
	else
		RewardText.TextColor3 = Color3.new(1,1,1)
	end
end

-- Decide what text to show for the upcoming milestone
local function resolveDisplayTextForMilestone(nextMilestone: number): string
	local exact = Config.Rewards[nextMilestone]
	if exact and exact.RewardText and exact.RewardText ~= "" then
		return exact.RewardText
	end

	local pool = Config.Rewards.Rolling
	if pool and pool.RewardText and pool.RewardText ~= "" then
		return pool.RewardText
	end

	-- Fallback if nothing configured
	return "-"
end

local function updateRewardTextForNextMilestone()
	local label = resolveDisplayTextForMilestone(likeMilestone)
	RewardText.Text = label
	applyRarityVisualsFromLabel(label)
end

-- Turn a milestone into a concrete reward data table:
-- { Global=bool, Amount=number, Name=string, Traits=table, Mutation=string }
local function resolveRewardForMilestone(milestoneLikes: number)
	local exact = Config.Rewards[milestoneLikes]
	if exact then
		return {
			Global = exact.Global == true,
			Amount = exact.Amount or 1,
			Name = exact.Name,
			Traits = exact.Traits or {},
			Mutation = exact.Mutation or "Default",
		}
	end

	-- Use Rolling fallback
	local pool = Config.Rewards.Rolling
	if not pool then return nil end

	local pickedName = pickFromWeights(pool.Chances or {})
	if not pickedName then return nil end

	return {
		Global = pool.Global == true,
		Amount = pool.Amount or 1,
		Name = pickedName,
		Traits = pool.Traits or {},
		Mutation = pool.Mutation or "Default",
	}
end

-- Actually grant the reward, either globally (publish) or locally (queue)
local function grantLikeReward(data)
	if not data or not data.Name or not data.Amount or not data.Mutation then return end

	if data.Global then
		MessagingService:PublishAsync("GlobalThing", {
			Amount = data.Amount,
			Name = data.Name,
			Traits = data.Traits or {},
			Mutation = data.Mutation,
		})
	else
		Things.Queue(data.Amount, data.Name, data.Traits or {}, data.Mutation)
	end
end

function LikeService.Get()
	local success, response = pcall(function()
		local url = ("https://games.roproxy.com/v1/games/%s/votes"):format(game.GameId)
		local raw = HttpService:GetAsync(url)
		return HttpService:JSONDecode(raw)
	end)

	if not (success and typeof(response) == "table" and response.upVotes) then
		return
	end

	local currentLikes = tonumber(response.upVotes) or 0

	-- First run: set the next milestone cleanly
	if not hasInitialized then
		likeMilestone = math.max(
			Config.MinFirstMilestone or 0,
			nextMultipleOf(Config.MilestoneStep, currentLikes)
		)
		hasInitialized = true
		updateRewardTextForNextMilestone()
	end

	-- Fire rewards for any milestones crossed since last poll
	while currentLikes >= likeMilestone do
		local reward = resolveRewardForMilestone(likeMilestone)
		if reward then
			grantLikeReward(reward)
		end
		likeMilestone += (Config.MilestoneStep > 0 and Config.MilestoneStep or 10)
	end

	-- Refresh label for the *next* milestone
	updateRewardTextForNextMilestone()

	-- UI: progress within current segment
	local prevMilestone = likeMilestone - (Config.MilestoneStep > 0 and Config.MilestoneStep or 10)
	local progressInSegment = currentLikes - prevMilestone
	local progressScale = clamp01(progressInSegment / (Config.MilestoneStep > 0 and Config.MilestoneStep or 10))

	LikeBar.ProgressText.Text = string.format(
		"%s / %s",
		formatWithCommas(currentLikes),
		formatWithCommas(likeMilestone)
	)
	LikeBar.Parent.Parent.Message.RequiredLikes.Text = string.format(
		"%s LIKES!",
		formatWithCommas(likeMilestone)
	)
	LikeBar.Progress.Size = UDim2.new(progressScale, 0, 1, 0)
end

function LikeService:Start()
	
	if game.PrivateServerId ~= "" then
		LikeBar.Parent.Parent.Message.Visible = false
		LikeBar.Parent.Parent.ProgressBar.Visible = false
		LikeBar.Parent.Parent.PrivateServerMessage.Visible = true
		return
	end
	
	while not hasInitialized do
		LikeService.Get()
		task.wait(1.5)
	end

	
	while true do
		task.wait(Config.PollInterval)
		LikeService.Get()
	end
end

return LikeService
