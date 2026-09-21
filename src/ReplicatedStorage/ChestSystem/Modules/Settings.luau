--// Settings Module
local Settings = {

	--// Group Settings
	GroupId = 16290076, -- The Roblox group ID required to claim chests. Set to 0 to disable.

	--// Claim Logic
	Claim = {
		Mode = "Daily", -- The mode for chest resets ("Daily" or "Minutely").
		DailyResetTime = 86400, -- Cooldown time for daily claims in seconds (24 hours).
		MinutelyResetTime = 600, -- Cooldown time for minutely claims in seconds (10 minutes).
		MinPlayTime = 1, -- Minimum time in seconds a player must be in-game to claim.
	},

	--// Rewards
	Rewards = {
		Currency = {
			DataStoreName = "Money", -- DataStore name for player currency.
			Name = "Money", -- The name of the currency's leaderstat.
			Amount = 15000 -- The amount of currency to give on claim.
		},
		Tool = {
			Paths = {
			}
		}
	},

	--// User Interface (UI)
	UI = {
		WarningDuration = 3.5, -- The time in seconds a warning message is visible.
		TouchCooldown = 1, -- The minimum time a player must wait between touches.
	},

	--// DataStore Configuration
	DataStore = {
		MaxRetries = 3, -- Maximum number of retries for a failed DataStore operation.
		RetryDelay = 5, -- The delay in seconds between failed retries.
	}
}

return Settings
