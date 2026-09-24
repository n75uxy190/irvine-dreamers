local TestRunner = require("../TestRunner")
local PCFactory = require("../../src/ServerStorage/Modules/PCRepair/PCFactory")
local PartDefs = require("../../src/ReplicatedStorage/Configuration/Modules/PCRepair/PartDefs")
local FaultDefs = require("../../src/ReplicatedStorage/Configuration/Modules/PCRepair/FaultDefs")

local ZONE_IDS = { "Cooling", "MainboardCompute", "ExpansionGraphics", "Storage", "Power" }

local function contains(list: { string }, value: string): boolean
	for _, v in list do
		if v == value then
			return true
		end
	end
	return false
end

TestRunner.test("roll() produces a unit with all five zones present", function()
	local unit = PCFactory.roll()
	for _, zoneId in ZONE_IDS do
		TestRunner.expectTrue(unit.parts[zoneId] ~= nil, `missing zone {zoneId}`)
	end
end)

TestRunner.test("roll() always produces 3 or 4 issues", function()
	for _ = 1, 200 do
		local unit = PCFactory.roll()
		local count = #unit.issues
		TestRunner.expectTrue(count == 3 or count == 4, `got {count} issues`)
	end
end)

TestRunner.test("every issue's fault actually applies to the part type it's rolled onto", function()
	for _ = 1, 200 do
		local unit = PCFactory.roll()
		for _, issue in unit.issues do
			local part = unit.parts[issue.zoneId][issue.slotIdx]
			local partType = PartDefs[part.defId].partType
			local faultDef = FaultDefs[issue.faultDefId]
			TestRunner.expectTrue(
				contains(faultDef.appliesTo, partType),
				`fault {issue.faultDefId} does not apply to {partType}`
			)
		end
	end
end)

TestRunner.test("issues never stack on the same (zoneId, slotIdx)", function()
	for _ = 1, 200 do
		local unit = PCFactory.roll()
		local seen = {}
		for _, issue in unit.issues do
			local key = `{issue.zoneId}:{issue.slotIdx}`
			TestRunner.expectTrue(seen[key] == nil, `duplicate issue target {key}`)
			seen[key] = true
		end
	end
end)

TestRunner.test("RAM slot count always lands in the configured 2-4 range", function()
	for _ = 1, 200 do
		local unit = PCFactory.roll()
		local ramCount = 0
		for _, part in unit.parts.MainboardCompute do
			if PartDefs[part.defId].partType == "RAM" then
				ramCount += 1
			end
		end
		TestRunner.expectTrue(ramCount >= 2 and ramCount <= 4, `got {ramCount} RAM sticks`)
	end
end)

TestRunner.test("ExpansionCard slot count can be 0 and never exceeds 2", function()
	local sawZero = false
	for _ = 1, 200 do
		local unit = PCFactory.roll()
		local cardCount = 0
		for _, part in unit.parts.ExpansionGraphics do
			if PartDefs[part.defId].partType == "ExpansionCard" then
				cardCount += 1
			end
		end
		TestRunner.expectTrue(cardCount >= 0 and cardCount <= 2, `got {cardCount} expansion cards`)
		if cardCount == 0 then
			sawZero = true
		end
	end
	TestRunner.expectTrue(sawZero, "expected at least one roll with zero expansion cards over 200 tries")
end)

TestRunner.test("every rolled part's tier is one that part actually defines a weight for", function()
	for _ = 1, 50 do
		local unit = PCFactory.roll()
		for _, slots in unit.parts do
			for _, part in slots do
				local def = PartDefs[part.defId]
				TestRunner.expectTrue(def.tierWeights[part.tier] ~= nil, `{part.defId} rolled unknown tier {part.tier}`)
			end
		end
	end
end)

TestRunner.test("consecutive rolls get distinct ids", function()
	local unitA = PCFactory.roll()
	local unitB = PCFactory.roll()
	TestRunner.expectTrue(unitA.id ~= unitB.id)
end)

TestRunner.finish()
