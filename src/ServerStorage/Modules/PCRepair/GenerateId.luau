--[[
	Portable unique-enough id generator. Deliberately avoids
	HttpService:GenerateGUID so this stays usable under Lune (no `game`
	there). Not cryptographically unique — fine for in-server object ids
	that never leave a single server's lifetime.

	Uses os.time() rather than os.clock(): Roblox's sandboxed `os` library
	doesn't expose os.clock(), and this needs to run identically under both
	Roblox and Lune.
]]

local counter = 0

local function generateId(prefix: string?): string
	counter += 1
	local salt = math.random(0, 0xFFFFFF)
	return string.format("%s%d-%x-%x", prefix or "", counter, os.time(), salt)
end

return generateId
