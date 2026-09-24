local TestRunner = require("../TestRunner")
local PCUnit = require("../../src/ServerStorage/Modules/PCRepair/PCUnit")

local function freshUnit()
	local parts = {
		Cooling = {
			[1] = { defId = "StockCooler", tier = "Common" },
		},
	}
	local issues = {
		{ id = "issue-1", faultDefId = "DriedPaste", zoneId = "Cooling", slotIdx = 1, status = "Open" },
		{ id = "issue-2", faultDefId = "DustyFan", zoneId = "Cooling", slotIdx = 1, status = "Open" },
		{ id = "issue-3", faultDefId = "DriedPaste", zoneId = "Cooling", slotIdx = 1, status = "Open" },
	}
	return PCUnit.new(parts, issues)
end

TestRunner.test("new() starts OnConveyor with no frozen income", function()
	local unit = freshUnit()
	TestRunner.expectEqual(unit.state, "OnConveyor")
	TestRunner.expectEqual(unit.incomeRate, nil)
	TestRunner.expectTrue(type(unit.id) == "string" and #unit.id > 0)
end)

TestRunner.test("transitionTo follows the legal lifecycle", function()
	local unit = freshUnit()
	local ok1 = PCUnit.transitionTo(unit, "Claimed")
	local ok2 = PCUnit.transitionTo(unit, "InRepair")
	TestRunner.expectTrue(ok1)
	TestRunner.expectTrue(ok2)
	TestRunner.expectEqual(unit.state, "InRepair")
end)

TestRunner.test("transitionTo rejects illegal jumps and leaves state unchanged", function()
	local unit = freshUnit()
	local ok, err = PCUnit.transitionTo(unit, "Repaired")
	TestRunner.expectEqual(ok, false)
	TestRunner.expectTrue(err ~= nil)
	TestRunner.expectEqual(unit.state, "OnConveyor")
end)

TestRunner.test("fixIssue fixes an open issue", function()
	local unit = freshUnit()
	local ok = PCUnit.fixIssue(unit, "issue-1")
	TestRunner.expectTrue(ok)
	TestRunner.expectEqual(unit.issues[1].status, "Fixed")
end)

TestRunner.test("fixIssue refuses an already-fixed issue", function()
	local unit = freshUnit()
	PCUnit.fixIssue(unit, "issue-1")
	local ok = PCUnit.fixIssue(unit, "issue-1")
	TestRunner.expectEqual(ok, false)
end)

TestRunner.test("fixIssue refuses an unknown id", function()
	local unit = freshUnit()
	local ok = PCUnit.fixIssue(unit, "does-not-exist")
	TestRunner.expectEqual(ok, false)
end)

TestRunner.test("isFullyRepaired is false until every issue is fixed", function()
	local unit = freshUnit()
	TestRunner.expectEqual(PCUnit.isFullyRepaired(unit), false)
	PCUnit.fixIssue(unit, "issue-1")
	PCUnit.fixIssue(unit, "issue-2")
	TestRunner.expectEqual(PCUnit.isFullyRepaired(unit), false)
	PCUnit.fixIssue(unit, "issue-3")
	TestRunner.expectTrue(PCUnit.isFullyRepaired(unit))
end)

TestRunner.test("applySabotage only works from InRepair", function()
	local unit = freshUnit()
	local ok = PCUnit.applySabotage(unit)
	TestRunner.expectEqual(ok, false)
end)

TestRunner.test("applySabotage resets every issue to Open and returns to OnConveyor, preserving id/parts/issues", function()
	local unit = freshUnit()
	local originalId = unit.id
	PCUnit.transitionTo(unit, "Claimed")
	PCUnit.transitionTo(unit, "InRepair")
	PCUnit.fixIssue(unit, "issue-1")
	PCUnit.fixIssue(unit, "issue-2")

	local ok = PCUnit.applySabotage(unit)

	TestRunner.expectTrue(ok)
	TestRunner.expectEqual(unit.state, "OnConveyor")
	TestRunner.expectEqual(unit.id, originalId)
	TestRunner.expectEqual(#unit.issues, 3)
	for _, issue in unit.issues do
		TestRunner.expectEqual(issue.status, "Open")
	end
end)

TestRunner.test("completeRepair freezes income exactly once and rejects a second call", function()
	local unit = freshUnit()
	PCUnit.transitionTo(unit, "Claimed")
	PCUnit.transitionTo(unit, "InRepair")
	PCUnit.fixIssue(unit, "issue-1")
	PCUnit.fixIssue(unit, "issue-2")
	PCUnit.fixIssue(unit, "issue-3")

	local incomeMultipliers = { Common = 1.0 }
	local ok = PCUnit.completeRepair(unit, incomeMultipliers, 10)

	TestRunner.expectTrue(ok)
	TestRunner.expectEqual(unit.state, "Repaired")
	TestRunner.expectEqual(unit.incomeRate, 10) -- one Common part * base 10 * mult 1.0

	local ok2 = PCUnit.completeRepair(unit, incomeMultipliers, 10)
	TestRunner.expectEqual(ok2, false)
	TestRunner.expectEqual(unit.incomeRate, 10) -- unchanged by the rejected second call
end)

TestRunner.test("completeRepair refuses while issues remain open", function()
	local unit = freshUnit()
	PCUnit.transitionTo(unit, "Claimed")
	PCUnit.transitionTo(unit, "InRepair")
	PCUnit.fixIssue(unit, "issue-1")
	-- issue-2 and issue-3 still Open

	local ok = PCUnit.completeRepair(unit, { Common = 1.0 }, 10)
	TestRunner.expectEqual(ok, false)
	TestRunner.expectEqual(unit.state, "InRepair")
	TestRunner.expectEqual(unit.incomeRate, nil)
end)

TestRunner.finish()
