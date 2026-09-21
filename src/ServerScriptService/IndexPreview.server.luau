local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local srcThings = ServerStorage:WaitForChild("Things")
local previewRoot = ReplicatedStorage:FindFirstChild("ThingPreviews") or Instance.new("Folder")
previewRoot.Name = "ThingPreviews"
previewRoot.Parent = ReplicatedStorage

previewRoot:ClearAllChildren()

for _, mutationFolder in ipairs(srcThings:GetChildren()) do
	if not mutationFolder:IsA("Folder") then continue end
	local newMutationFolder = Instance.new("Folder")
	newMutationFolder.Name = mutationFolder.Name
	newMutationFolder.Parent = previewRoot

	for _, rarityFolder in ipairs(mutationFolder:GetChildren()) do
		if not rarityFolder:IsA("Folder") then continue end
		local newRarityFolder = Instance.new("Folder")
		newRarityFolder.Name = rarityFolder.Name
		newRarityFolder.Parent = newMutationFolder

		for _, thing in ipairs(rarityFolder:GetChildren()) do
			thing:Clone().Parent = newRarityFolder
		end
	end
end
