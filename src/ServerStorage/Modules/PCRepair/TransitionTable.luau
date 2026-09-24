--[[
	One transition table, validated server-side — per the handoff, illegal
	transitions get logged as suspected exploits by the caller (this module
	only judges legality, it doesn't log; keeps it Lune-testable with no
	side effects).

	Only encodes the edges the handoff's diagram actually draws:
	OnConveyor -> Claimed -> InRepair -> Repaired -> Placed, plus
	InRepair -> OnConveyor for sabotage/disconnect. There is deliberately no
	Claimed -> OnConveyor edge (e.g. a player claims but disconnects before
	ever entering repair) — the handoff doesn't specify one, so this doesn't
	invent one. Flagged as an open gap in journal/005.
]]

local TransitionTable = {}

local Allowed: { [string]: { [string]: boolean } } = {
	OnConveyor = { Claimed = true },
	Claimed = { InRepair = true },
	InRepair = { Repaired = true, OnConveyor = true },
	Repaired = { Placed = true },
	Placed = {},
}

function TransitionTable.isLegal(from: string, to: string): boolean
	local edges = Allowed[from]
	return edges ~= nil and edges[to] == true
end

return TransitionTable
