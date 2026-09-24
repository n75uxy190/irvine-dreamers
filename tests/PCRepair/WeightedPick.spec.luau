local TestRunner = require("../TestRunner")
local WeightedPick = require("../../src/ServerStorage/Modules/PCRepair/WeightedPick")

TestRunner.test("returns nil for an empty weight table", function()
	TestRunner.expectEqual(WeightedPick.fromWeights({}), nil)
end)

TestRunner.test("returns nil when all weights are zero", function()
	TestRunner.expectEqual(WeightedPick.fromWeights({ A = 0, B = 0 }), nil)
end)

TestRunner.test("a single non-zero key is always picked", function()
	for _ = 1, 20 do
		TestRunner.expectEqual(WeightedPick.fromWeights({ Only = 5 }), "Only")
	end
end)

TestRunner.test("only ever returns keys that were actually given weight", function()
	local weights = { Common = 70, Rare = 25, Epic = 5 }
	for _ = 1, 200 do
		local picked = WeightedPick.fromWeights(weights)
		TestRunner.expectTrue(weights[picked] ~= nil, `unexpected key {tostring(picked)}`)
	end
end)

TestRunner.test("distribution roughly tracks weights over many trials", function()
	local weights = { Common = 90, Rare = 10 }
	local counts = { Common = 0, Rare = 0 }
	local trials = 2000

	for _ = 1, trials do
		local picked = WeightedPick.fromWeights(weights)
		counts[picked] += 1
	end

	local commonRatio = counts.Common / trials
	-- Loose bound (expected ~0.9) — this is a randomness sanity check, not
	-- a precise statistical test. Flaky only in astronomically unlucky runs.
	TestRunner.expectTrue(commonRatio > 0.8 and commonRatio < 1.0, `Common ratio was {commonRatio}`)
end)

TestRunner.finish()
