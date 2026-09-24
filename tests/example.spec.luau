--[[
	Example test — demonstrates the pattern for tests/README.md.
	Safe to delete once real PCRepair spec files exist.
]]

local TestRunner = require("./TestRunner")

local function add(a: number, b: number): number
	return a + b
end

TestRunner.test("add(2, 3) equals 5", function()
	TestRunner.expectEqual(add(2, 3), 5)
end)

TestRunner.test("add(-1, 1) equals 0", function()
	TestRunner.expectEqual(add(-1, 1), 0)
end)

TestRunner.test("this one is written to fail, on purpose, to show what that looks like", function()
	TestRunner.expectEqual(add(1, 1), 3)
end)

TestRunner.finish()
