--[[
	Rolls a new PCUnit from config. Two independent roll passes, in order:
	parts first (per ZoneDefs/PartDefs), then 3-4 issues layered on top
	(per FaultDefs, filtered to the part type actually in each rolled
	slot). See journal/002 and journal/003 for why this shape.

	Cross-tree requires below (../../../ReplicatedStorage/...) mirror the
	real folder nesting under src/, so they resolve identically whether
	this runs under Lune (filesystem-relative) or in live Roblox (assuming
	Luau require-by-string is enabled for this experience — flagged as
	unverified in journal/005, confirm in Studio before relying on this).
]]

local WeightedPick = require("./WeightedPick")
local generateId = require("./GenerateId")
local PCUnit = require("./PCUnit")

local ZoneDefs = require("../../../ReplicatedStorage/Configuration/Modules/PCRepair/ZoneDefs")
local PartDefs = require("../../../ReplicatedStorage/Configuration/Modules/PCRepair/PartDefs")
local FaultDefs = require("../../../ReplicatedStorage/Configuration/Modules/PCRepair/FaultDefs")

type PartInstance = PCUnit.PartInstance
type Issue = PCUnit.Issue

local MIN_ISSUES = 3
local MAX_ISSUES = 4

local PCFactory = {}

local function candidatesForPartType(partType: string): { string }
	local candidates = {}
	for defId, def in PartDefs do
		if def.partType == partType then
			table.insert(candidates, defId)
		end
	end
	return candidates
end

local function rollPart(partType: string): PartInstance?
	local candidates = candidatesForPartType(partType)
	if #candidates == 0 then
		return nil
	end

	local defId = candidates[math.random(1, #candidates)]
	local def = PartDefs[defId]
	local tier = WeightedPick.fromWeights(def.tierWeights)
	if tier == nil then
		return nil
	end

	return { defId = defId, tier = tier }
end

local function rollParts(): { [string]: { [number]: PartInstance } }
	local parts = {}

	for zoneId, zoneDef in ZoneDefs do
		local slots = {}
		local slotIdx = 0

		for _, slotDef in zoneDef.slots do
			local count = 1
			if slotDef.count then
				count = math.random(slotDef.count.min, slotDef.count.max)
			end

			for _ = 1, count do
				local part = rollPart(slotDef.partType)
				if part then
					slotIdx += 1
					slots[slotIdx] = part
				end
			end
		end

		parts[zoneId] = slots
	end

	return parts
end

-- Picks distinct (zoneId, slotIdx) targets so issues don't stack multiple
-- faults on the exact same part instance.
local function pickIssueTargets(parts: { [string]: { [number]: PartInstance } }, count: number)
	local allSlots = {}
	for zoneId, slots in parts do
		for slotIdx in slots do
			table.insert(allSlots, { zoneId = zoneId, slotIdx = slotIdx })
		end
	end

	-- Fisher-Yates shuffle, then take the first `count`.
	for i = #allSlots, 2, -1 do
		local j = math.random(1, i)
		allSlots[i], allSlots[j] = allSlots[j], allSlots[i]
	end

	local targets = {}
	for i = 1, math.min(count, #allSlots) do
		table.insert(targets, allSlots[i])
	end
	return targets
end

local function faultDefsFor(partType: string): { string }
	local ids = {}
	for faultId, def in FaultDefs do
		for _, appliesToType in def.appliesTo do
			if appliesToType == partType then
				table.insert(ids, faultId)
				break
			end
		end
	end
	return ids
end

local function rollIssues(parts: { [string]: { [number]: PartInstance } }): { Issue }
	local issueCount = math.random(MIN_ISSUES, MAX_ISSUES)
	local targets = pickIssueTargets(parts, issueCount)

	local issues = {}
	for _, target in targets do
		local part = parts[target.zoneId][target.slotIdx]
		local partType = PartDefs[part.defId].partType
		local candidateFaults = faultDefsFor(partType)

		if #candidateFaults > 0 then
			local faultDefId = candidateFaults[math.random(1, #candidateFaults)]
			table.insert(issues, {
				id = generateId("issue-"),
				faultDefId = faultDefId,
				zoneId = target.zoneId,
				slotIdx = target.slotIdx,
				status = "Open" :: PCUnit.IssueStatus,
			})
		end
	end

	return issues
end

function PCFactory.roll(): PCUnit.PCUnit
	local parts = rollParts()
	local issues = rollIssues(parts)
	return PCUnit.new(parts, issues)
end

return PCFactory
