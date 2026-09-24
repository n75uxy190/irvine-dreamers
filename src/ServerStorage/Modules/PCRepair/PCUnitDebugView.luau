--[[
	Playtest-only visualization: no real assets exist yet, so a PCUnit
	renders as 5 semi-transparent colored boxes, one per zone, positioned
	roughly per the physical layout in the handoff (cooling top, mainboard
	upper, graphics lower, storage left, power bottom). Box color reflects
	that zone's issue state so a rolled PCUnit's internals are visible at a
	glance during a playtest, without console output.

	Uses Instance.new/CFrame/Color3 — Roblox-only, NOT Lune-testable. Verify
	this by eye in Studio, not by running it here.

	Not wired to any in-game trigger yet (deliberately out of scope for this
	pass — see journal/005). To try it from the Studio command bar:

		local PCFactory = require(game.ServerStorage.Modules.PCRepair.PCFactory)
		local DebugView = require(game.ServerStorage.Modules.PCRepair.PCUnitDebugView)
		DebugView.render(PCFactory.roll(), workspace.Baseplate.CFrame + Vector3.new(0, 5, 0))
]]

local PCUnit = require("./PCUnit")

type PCUnit = PCUnit.PCUnit

local ZONE_LAYOUT: { [string]: Vector3 } = {
	Cooling = Vector3.new(0, 8, -4),
	MainboardCompute = Vector3.new(0, 4, -2),
	ExpansionGraphics = Vector3.new(0, 4, 2),
	Storage = Vector3.new(-4, 4, 0),
	Power = Vector3.new(0, 0, 0),
}

local BOX_SIZE = Vector3.new(3, 3, 3)

local COLOR_NO_ISSUES = Color3.fromRGB(140, 140, 140) -- grey: zone rolled clean
local COLOR_OPEN_ISSUE = Color3.fromRGB(200, 40, 40) -- red: at least one open issue
local COLOR_ALL_FIXED = Color3.fromRGB(40, 180, 70) -- green: had issues, all fixed

local PCUnitDebugView = {}

local function zoneStatusColor(pcUnit: PCUnit, zoneId: string): Color3
	local hasIssue = false
	local hasOpenIssue = false

	for _, issue in pcUnit.issues do
		if issue.zoneId == zoneId then
			hasIssue = true
			if issue.status == "Open" then
				hasOpenIssue = true
			end
		end
	end

	if not hasIssue then
		return COLOR_NO_ISSUES
	elseif hasOpenIssue then
		return COLOR_OPEN_ISSUE
	else
		return COLOR_ALL_FIXED
	end
end

function PCUnitDebugView.render(pcUnit: PCUnit, anchorCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = `PCUnitDebug_{pcUnit.id}`

	for zoneId, offset in ZONE_LAYOUT do
		local box = Instance.new("Part")
		box.Name = zoneId
		box.Shape = Enum.PartType.Block
		box.Size = BOX_SIZE
		box.Anchored = true
		box.CanCollide = false
		box.CanQuery = false
		box.Transparency = 0.45
		box.Color = zoneStatusColor(pcUnit, zoneId)
		box.CFrame = anchorCFrame + offset

		local label = Instance.new("BillboardGui")
		label.Name = "ZoneLabel"
		label.Size = UDim2.fromOffset(120, 30)
		label.StudsOffset = Vector3.new(0, 2.2, 0)
		label.AlwaysOnTop = true

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.SourceSansBold
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.Text = zoneId
		text.Parent = label

		label.Parent = box
		box.Parent = model
	end

	model.PrimaryPart = model:FindFirstChild("Power") :: BasePart
	return model
end

return PCUnitDebugView
