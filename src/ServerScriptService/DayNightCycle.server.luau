local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
local DAY_DURATION = 900     -- seconds for sun to go horizon->top->horizon
local NIGHT_DURATION = 900  -- seconds for moon to go horizon->top->horizon
local TRANSITION_DURATION = 1 -- seconds for fast switch at horizon

local phase = "day" -- "day" or "night"
local elapsed = 0

-- ⚡ PAUSE LOGIC
local paused = false
local forcedClockTime = nil

-- ⚡ BindableEvent listener
local DayNightToggle = ReplicatedStorage:WaitForChild("Bindables"):WaitForChild("DayNightTraitToggle")
DayNightToggle.Event:Connect(function(shouldPause, clockTime)
	paused = shouldPause or false
	forcedClockTime = shouldPause and clockTime or nil
	if forcedClockTime then
		Lighting.ClockTime = forcedClockTime
	end
end)

-- Helper function to map progress 0->1 to half-circle ClockTime
local function getClockTime(progress, startTime, isNight)
	if not isNight then
		-- Day: 6 -> 18
		return startTime + progress * 12
	else
		-- Night: 18 -> 24 -> 6
		if progress < 0.5 then
			return 18 + (progress / 0.5) * 6    -- 18 -> 24
		else
			return (progress - 0.5) / 0.5 * 6   -- 0 -> 6
		end
	end
end

-- Main loop
RunService.Heartbeat:Connect(function(dt)
	-- ⚡ Skip time updates if paused
	if paused then return end

	elapsed = elapsed + dt

	if phase == "day" then
		local progress = math.min(elapsed / DAY_DURATION, 1)
		Lighting.ClockTime = getClockTime(progress, 6, false)

		if progress >= 1 then
			-- Fast transition to night start
			TweenService:Create(Lighting, TweenInfo.new(TRANSITION_DURATION), {
				ClockTime = 18
			}):Play()
			phase = "night"
			elapsed = 0
		end

	elseif phase == "night" then
		local progress = math.min(elapsed / NIGHT_DURATION, 1)
		Lighting.ClockTime = getClockTime(progress, 18, true)

		if progress >= 1 then
			-- Fast transition to day start
			TweenService:Create(Lighting, TweenInfo.new(TRANSITION_DURATION), {
				ClockTime = 6
			}):Play()
			phase = "day"
			elapsed = 0
		end
	end
end)
