local TestRunner = require("../TestRunner")
local TransitionTable = require("../../src/ServerStorage/Modules/PCRepair/TransitionTable")

TestRunner.test("full lifecycle path is legal, step by step", function()
	TestRunner.expectTrue(TransitionTable.isLegal("OnConveyor", "Claimed"))
	TestRunner.expectTrue(TransitionTable.isLegal("Claimed", "InRepair"))
	TestRunner.expectTrue(TransitionTable.isLegal("InRepair", "Repaired"))
	TestRunner.expectTrue(TransitionTable.isLegal("Repaired", "Placed"))
end)

TestRunner.test("sabotage escape hatch: InRepair -> OnConveyor is legal", function()
	TestRunner.expectTrue(TransitionTable.isLegal("InRepair", "OnConveyor"))
end)

TestRunner.test("skipping a step is illegal", function()
	TestRunner.expectEqual(TransitionTable.isLegal("OnConveyor", "InRepair"), false)
	TestRunner.expectEqual(TransitionTable.isLegal("OnConveyor", "Repaired"), false)
	TestRunner.expectEqual(TransitionTable.isLegal("Claimed", "Placed"), false)
end)

TestRunner.test("going backwards outside the sabotage edge is illegal", function()
	TestRunner.expectEqual(TransitionTable.isLegal("Repaired", "InRepair"), false)
	TestRunner.expectEqual(TransitionTable.isLegal("Claimed", "OnConveyor"), false)
end)

TestRunner.test("Placed is terminal — no outgoing edges", function()
	TestRunner.expectEqual(TransitionTable.isLegal("Placed", "OnConveyor"), false)
	TestRunner.expectEqual(TransitionTable.isLegal("Placed", "Claimed"), false)
end)

TestRunner.test("unknown states are illegal, not errors", function()
	TestRunner.expectEqual(TransitionTable.isLegal("NotARealState", "OnConveyor"), false)
end)

TestRunner.finish()
