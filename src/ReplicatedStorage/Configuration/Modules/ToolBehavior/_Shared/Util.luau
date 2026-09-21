local Util = {}

function Util.ensureSound(parent, name, id)
	if not parent or not id or id == "" then return nil end
	local s = parent:FindFirstChild(name)
	if not s then s = Instance.new("Sound"); s.Name = name; s.Volume = 2; s.RollOffMode = Enum.RollOffMode.Linear; s.RollOffMaxDistance = 90; s.Parent = parent end
	s.SoundId = id
	return s
end

return Util
