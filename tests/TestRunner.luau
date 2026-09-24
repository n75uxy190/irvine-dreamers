--[[
	Minimal test harness for Lune. No external dependencies — this file is
	the whole framework. See tests/README.md for how to use it.
]]

local process = require("@lune/process")

local TestRunner = {}

local passed = 0
local failed = 0

function TestRunner.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print(`  ok   - {name}`)
	else
		failed += 1
		print(`  FAIL - {name}`)
		print(`         {tostring(err)}`)
	end
end

function TestRunner.expectEqual(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(
			`{message or "expected values to match"}\n`
				.. `    got:      {tostring(actual)}\n`
				.. `    expected: {tostring(expected)}`,
			2
		)
	end
end

function TestRunner.expectTrue(value: boolean, message: string?)
	if value ~= true then
		error(message or `expected true, got {tostring(value)}`, 2)
	end
end

-- Call once at the end of a *.spec.luau file. Exits with a non-zero code
-- if anything failed, so this plugs straight into CI later without changes.
function TestRunner.finish()
	print(`\n{passed} passed, {failed} failed`)
	if failed > 0 then
		process.exit(1)
	end
end

return TestRunner
