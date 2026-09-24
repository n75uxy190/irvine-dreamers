--[[
	Stub. Registered so the service-layer shape exists before the logic
	does — deliberately not built this pass, since seeing the container
	rendered doesn't require fixing anything yet. Real job, once built:
	own the Claimed -> InRepair transition and RepairSession lifecycle,
	and be the only caller of PCUnit.fixIssue/completeRepair.
]]

local RepairService = {}

function RepairService:Start() end

return RepairService
