--[[
	Plain-data PCUnit record + the functions that mutate it. No metatables,
	no OOP — matches the rest of this codebase's style and the handoff's
	own "data, not classes" instruction. Every function here takes the unit
	as an explicit first argument and mutates it in place.

	Must stay Lune-testable: no game:GetService, no Instance.new, no
	Roblox-only globals anywhere in this file.
]]

local TransitionTable = require("./TransitionTable")
local generateId = require("./GenerateId")

export type PartInstance = {
	defId: string,
	tier: string,
}

export type IssueStatus = "Open" | "Fixed"

export type Issue = {
	id: string,
	faultDefId: string,
	zoneId: string,
	slotIdx: number,
	status: IssueStatus,
}

export type PCState = "OnConveyor" | "Claimed" | "InRepair" | "Repaired" | "Placed"

export type PartsMap = { [string]: { [number]: PartInstance } }

export type PCUnit = {
	id: string,
	state: PCState,
	parts: PartsMap,
	issues: { Issue },
	incomeRate: number?,
}

local PCUnit = {}

function PCUnit.new(parts: PartsMap, issues: { Issue }): PCUnit
	return {
		id = generateId("pc-"),
		state = "OnConveyor" :: PCState,
		parts = parts,
		issues = issues,
		incomeRate = nil,
	}
end

-- The only legal way to change .state. Never assign unit.state directly.
function PCUnit.transitionTo(unit: PCUnit, newState: PCState): (boolean, string?)
	if not TransitionTable.isLegal(unit.state, newState) then
		return false, `illegal transition: {unit.state} -> {newState}`
	end
	unit.state = newState
	return true
end

function PCUnit.fixIssue(unit: PCUnit, issueId: string): (boolean, string?)
	for _, issue in unit.issues do
		if issue.id == issueId then
			if issue.status == "Fixed" then
				return false, "issue already fixed"
			end
			issue.status = "Fixed"
			return true
		end
	end
	return false, "issue not found"
end

function PCUnit.isFullyRepaired(unit: PCUnit): boolean
	for _, issue in unit.issues do
		if issue.status ~= "Fixed" then
			return false
		end
	end
	return true
end

-- Same id, same parts, same issues — only issue status resets. Never
-- re-rolls anything; that's the "sabotage steals labor" invariant.
function PCUnit.applySabotage(unit: PCUnit): (boolean, string?)
	if unit.state ~= "InRepair" then
		return false, `cannot sabotage from state {unit.state}`
	end
	for _, issue in unit.issues do
		issue.status = "Open"
	end
	return PCUnit.transitionTo(unit, "OnConveyor")
end

-- Validates all issues are fixed, transitions InRepair -> Repaired, and
-- freezes incomeRate — all atomically, so this invariant can't be broken
-- by calling the pieces out of order or twice.
function PCUnit.completeRepair(
	unit: PCUnit,
	incomeMultipliers: { [string]: number },
	baseIncomePerPart: number
): (boolean, string?)
	if unit.state ~= "InRepair" then
		return false, `cannot complete repair from state {unit.state}`
	end
	if not PCUnit.isFullyRepaired(unit) then
		return false, "issues remain open"
	end
	if unit.incomeRate ~= nil then
		return false, "income already frozen"
	end

	local ok, err = PCUnit.transitionTo(unit, "Repaired")
	if not ok then
		return false, err
	end

	local total = 0
	for _, slots in unit.parts do
		for _, part in slots do
			total += baseIncomePerPart * (incomeMultipliers[part.tier] or 1)
		end
	end
	unit.incomeRate = total

	return true
end

return PCUnit
