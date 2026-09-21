-- ReplicatedStorage.Modules.UpdateMoneyPerSecond
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Require the modules needed
local Things = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Things"))
local Traits = require(ServerStorage.Configuration.Modules:WaitForChild("Traits"))
local Mutations = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Mutations"))

local UpdateMoneyPerSecondModule = {}

function UpdateMoneyPerSecondModule.Update(Player)
	if not Player then return end

	local Configuration = Player:FindFirstChild("Configuration")
	if not Configuration then return end

	local Base = Configuration:FindFirstChild("Base") and Configuration.Base.Value
	if not Base then return end

	local TotalMPS = 0
	local PlayerMultiplier = Configuration:FindFirstChild("Multiplier") and Configuration.Multiplier.Value or 1

	-- Iterate over all slots in the base
	for _, Slot in ipairs(Base.Slots:GetChildren()) do
		local SlotConfig = Slot:FindFirstChild("Configuration")
		if SlotConfig then
			local ThingValue = SlotConfig:FindFirstChild("Thing")
			if ThingValue and ThingValue.Value then
				local ThingInstance = nil
				local ThingName = nil

				-- Check if the stored value is an Instance or a string
				if typeof(ThingValue.Value) == "Instance" then
					ThingInstance = ThingValue.Value
					ThingName = ThingInstance.Name
				else
					ThingName = tostring(ThingValue.Value)
					ThingInstance = Slot:FindFirstChild(ThingName)
				end

				local ThingModule = Things.Things[ThingName]
				local ThingConfig = ThingInstance and ThingInstance:FindFirstChild("Configuration")

				if ThingModule and ThingConfig then
					local BaseMPS = ThingModule.MoneyPerSecond or 0

					-- Mutation multiplier
					local MutationValue = ThingConfig:FindFirstChild("Mutation")
					local MutationMultiplier = 1
					if MutationValue and MutationValue.Value ~= "" then
						local MutationModule = Mutations[MutationValue.Value]
						if MutationModule and MutationModule.Multiplier then
							MutationMultiplier = MutationModule.Multiplier
						end
					end

					-- Traits multiplier
					local TraitsValue = ThingConfig:FindFirstChild("Traits")
					local TraitsMultiplier = 1
					if TraitsValue and TraitsValue.Value ~= "" then
						for TraitName in string.gmatch(TraitsValue.Value, "([^,]+)") do
							local TraitModule = Traits[TraitName]
							if TraitModule and TraitModule.Multiplier then
								TraitsMultiplier = TraitsMultiplier * TraitModule.Multiplier
							end
						end
					end

					-- Apply all multipliers
					local TotalThingMPS = BaseMPS * MutationMultiplier * TraitsMultiplier * PlayerMultiplier
					TotalMPS = TotalMPS + TotalThingMPS
				end
			end
		end
	end

	-- Update player's MoneyPerSecond NumberValue
	local MoneyPerSecondValue = Configuration:FindFirstChild("MoneyPerSecond")
	if MoneyPerSecondValue then
		MoneyPerSecondValue.Value = TotalMPS
	end
end

return UpdateMoneyPerSecondModule
