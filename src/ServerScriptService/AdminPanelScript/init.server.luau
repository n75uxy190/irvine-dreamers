local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")

local Things = require(ServerStorage.Modules:WaitForChild("Things"))
local Things2 = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Things"))
local Events = require(ReplicatedStorage.Configuration.Modules:WaitForChild("Events"))
local SetProperties = require(ServerStorage.Modules:WaitForChild("SetProperties"))
local Insert = require(ServerStorage.Modules:WaitForChild("Insert"))

local Traits = ServerStorage:WaitForChild("Configuration"):WaitForChild("Modules"):WaitForChild("Traits", 3)
local clone = Traits:Clone()
clone.Parent = ReplicatedStorage

local AdminAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("AdminAction") or ReplicatedStorage:WaitForChild("AdminAction") or ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AdminAction")
local BanDataStore = DataStoreService:GetDataStore("BannedPlayers")
local BanListStore = DataStoreService:GetDataStore("BanList")

local function FindPlayerByNameIgnoreCase3(player, maybeName)
	local sender, name

	if maybeName == nil then
		sender = nil
		name = player
	else
		sender = player
		name = maybeName
	end

	name = name:lower()

	if name == "me" and sender then
		return {sender}
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == name then
			return {plr}
		end
	end

	return {}
end

local function FindPlayerByNameIgnoreCase(player, maybeName)
    local sender, name

    if maybeName == nil then
        sender = nil
        name = player
    else
        sender = player
        name = maybeName
    end

    name = name:lower()

    if name == "me" and sender then
        return {sender}
    end

    if name == "all" then
        return Players:GetPlayers()
    end

    if name == "others" and sender then
        local result = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= sender then
                table.insert(result, plr)
            end
        end
        return result
    end

    if name == "random" then
        local allPlayers = Players:GetPlayers()
        if #allPlayers > 0 then
            local randomPlayer = allPlayers[math.random(1, #allPlayers)]
            return {randomPlayer}
        end
        return {}
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == name then
            return {plr}
        end
    end

    return {}
end

local function FindPlayerByNameIgnoreCase2(name)
    name = name:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == name then
            return plr 
        end
    end
    return nil
end


local function IsPlayerWhitelisted(player)
    local whitelist = require(ServerStorage.Configuration.Modules:WaitForChild("Commands")).Whitelist
    for _, userId in ipairs(whitelist) do
        if userId == player.UserId then
            return true
        end
    end
    return false
end

local function unlockPlayerBase(base)
    if not base then return false end

    local lockAttachment = base.Lock:FindFirstChild("LockAttachment")
    if not lockAttachment then return false end

    local lockGui = lockAttachment:FindFirstChild("LockGui")
    if not lockGui then return false end

    local lockLabel = lockGui:FindFirstChild("Lock")
    local timeLabel = lockGui:FindFirstChild("Time")

    if lockLabel then
        lockLabel.Text = "Lock"
        lockLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
    if timeLabel then
        timeLabel.Visible = false
    end

    local baseOwner = base.Configuration and base.Configuration.Player and base.Configuration.Player.Value
    local unlockedDoors = {}

    if baseOwner then
        local rebirths = baseOwner:FindFirstChild("leaderstats") and baseOwner.leaderstats:FindFirstChild("Rebirths")
        local rebirthsAmount = rebirths and rebirths.Value or 0

        local unlockedFloors = {base.Floors:FindFirstChild("Floor1")}
        for i = 1, rebirthsAmount do
            local floorName = "Floor" .. (i + 1)
            local floor = base.Floors:FindFirstChild(floorName)
            if floor then table.insert(unlockedFloors, floor) end
        end

        for _, floor in ipairs(unlockedFloors) do
            local doors = floor:FindFirstChild("Doors")
            if doors then
                for _, door in ipairs(doors:GetChildren()) do
                    table.insert(unlockedDoors, door)
                end
            end
        end
    end

    for _, door in ipairs(unlockedDoors) do
        for _, descendant in ipairs(door:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = false
                if descendant.Name ~= "Hitbox" then
                    descendant.Transparency = 1
                end
            end
        end

        local proximityPrompt = door:FindFirstChild("Hitbox") and door.Hitbox:FindFirstChild("ProximityPrompt")
        if proximityPrompt then
            SetProperties.AllClients(proximityPrompt, {Enabled = false})
        end
    end

    return true
end

local function lockPlayerBase(base, duration)
    if not base then return false end

    local lockAttachment = base.Lock:FindFirstChild("LockAttachment")
    if not lockAttachment then
        lockAttachment = Instance.new("Attachment")
        lockAttachment.Name = "LockAttachment"
        lockAttachment.Parent = base.Lock
    end

    local lockGui = lockAttachment:FindFirstChild("LockGui")
    if not lockGui then
        lockGui = Instance.new("BillboardGui")
        lockGui.Name = "LockGui"
        lockGui.Size = UDim2.new(0, 200, 0, 50)
        lockGui.Parent = lockAttachment

        local lockLabel = Instance.new("TextLabel")
        lockLabel.Name = "Lock"
        lockLabel.Size = UDim2.new(1, 0, 0.5, 0)
        lockLabel.Position = UDim2.new(0, 0, 0, 0)
        lockLabel.BackgroundTransparency = 1
        lockLabel.Font = Enum.Font.GothamBold
        lockLabel.TextSize = 18
        lockLabel.TextStrokeTransparency = 0
        lockLabel.Parent = lockGui

        local timeLabel = Instance.new("TextLabel")
        timeLabel.Name = "Time"
        timeLabel.Size = UDim2.new(1, 0, 0.5, 0)
        timeLabel.Position = UDim2.new(0, 0, 0.5, 0)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.TextSize = 16
        timeLabel.TextStrokeTransparency = 0
        timeLabel.Parent = lockGui
    end

    local lockLabel = lockGui:FindFirstChild("Lock")
    local timeLabel = lockGui:FindFirstChild("Time")

    if lockLabel then
        lockLabel.Text = "Locked"
        lockLabel.TextColor3 = Color3.fromRGB(250, 0, 0)
    end
    if timeLabel then timeLabel.Visible = true end

    local baseOwner = base.Configuration and base.Configuration.Player and base.Configuration.Player.Value
    local unlockedDoors = {}

    if baseOwner then
        local rebirths = baseOwner:FindFirstChild("leaderstats") and baseOwner.leaderstats:FindFirstChild("Rebirths")
        local rebirthsAmount = rebirths and rebirths.Value or 0

        local unlockedFloors = {base.Floors:FindFirstChild("Floor1")}
        for i = 1, rebirthsAmount do
            local floorName = "Floor" .. (i + 1)
            local floor = base.Floors:FindFirstChild(floorName)
            if floor then table.insert(unlockedFloors, floor) end
        end

        for _, floor in ipairs(unlockedFloors) do
            local doors = floor:FindFirstChild("Doors")
            if doors then
                for _, door in ipairs(doors:GetChildren()) do
                    table.insert(unlockedDoors, door)
                end
            end
        end
    end

    for _, door in ipairs(unlockedDoors) do
        for _, descendant in ipairs(door:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = true
                if baseOwner then
                    SetProperties.Client(baseOwner, descendant, {CanCollide = false})
                end
                if descendant.Name ~= "Hitbox" then
                    descendant.Transparency = 0
                end
            end
        end

        local proximityPrompt = door:FindFirstChild("Hitbox") and door.Hitbox:FindFirstChild("ProximityPrompt")
        if proximityPrompt then
            SetProperties.AllClients(proximityPrompt, {Enabled = true})
            if baseOwner then
                SetProperties.Client(baseOwner, proximityPrompt, {Enabled = false})
            end
        end
    end

    local timeRemaining = tonumber(duration) or 0
    task.spawn(function()
        while timeRemaining > 0 and lockLabel and lockLabel.Text == "Locked" do
            local minutes = math.floor(timeRemaining / 60)
            local seconds = timeRemaining % 60
            if minutes > 0 then
                if timeLabel then timeLabel.Text = string.format("%d:%02d", minutes, seconds) end
            else
                if timeLabel then timeLabel.Text = tostring(seconds) end
            end
            timeRemaining = timeRemaining - 1
            task.wait(1)
        end

        if lockLabel and lockLabel.Text == "Locked" then
            unlockPlayerBase(base)
        end
    end)

    return true
end

local function UpdateBanList(player)
    if not game:GetService("RunService"):IsStudio() then
        local banList = {}
        local list = BanListStore:GetAsync("BanList") or {}

        for _, userId in ipairs(list) do
            local banData = BanDataStore:GetAsync(tostring(userId))
            if banData and banData.Banned then
                local username = "Unknown"
                pcall(function()
                    username = Players:GetNameFromUserIdAsync(userId)
                end)

                table.insert(banList, {
                    Username = username,
                    BannedBy = banData.BannedBy,
                    Reason = banData.Reason,
                    BannedAt = banData.BannedAt
                })
            end
        end

        local action = "UpdateBanList"
        if player then
            AdminAction:FireClient(player,action, banList)
        else
            AdminAction:FireAllClients(action, banList)
        end
    else
        warn("BanList update is disabled in Studio for security reasons.")
    end
end

local function HandleFunCommand(player, target, command)
    if not IsPlayerWhitelisted(player) then
        warn(player.Name .. " tried to use admin panel without permission!")
        return
    end
    
    local character = target.Character
    if not character then return end

    local characterYOU = player.Character
    if not characterYOU then return end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    local humanoidYOU = characterYOU:FindFirstChild("Humanoid")
    local rootPartYOU = characterYOU:FindFirstChild("HumanoidRootPart")

    if command == "Fling Player" then
        if rootPart then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(
                math.random(-100, 100),
                100,
                math.random(-100, 100)
            )
            bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVelocity.Parent = rootPart
            Debris:AddItem(bodyVelocity, 0.5)
        end

    elseif command == "Freeze Player" then
        if rootPart then
            rootPart.Anchored = true
        end

    elseif command == "UnFreeze Player" then
        if rootPart then
            rootPart.Anchored = false
        end

    elseif command == "Make Giant" then
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            local character = humanoid.Parent
            if character then
                local targetScale = 3

                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local defaultSizes = {
                            Head = Vector3.new(2, 1, 1),
                            Torso = Vector3.new(2, 2, 1),
                            ["Left Arm"] = Vector3.new(1, 2, 1),
                            ["Right Arm"] = Vector3.new(1, 2, 1),
                            ["Left Leg"] = Vector3.new(1, 2, 1),
                            ["Right Leg"] = Vector3.new(1, 2, 1),
                            HumanoidRootPart = Vector3.new(2, 2, 1),
                        }

                        if defaultSizes[part.Name] then
                            part.Size = defaultSizes[part.Name] * targetScale
                        end

                        if part.Name == "Head" then
                            local mesh = part:FindFirstChildOfClass("SpecialMesh")
                            if mesh then
                                mesh.Scale = Vector3.new(1, 1, 1) * targetScale
                            end
                        end
                    end
                end
            end
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            local bodyDepthScale = humanoid:FindFirstChild("BodyDepthScale")
            local bodyHeightScale = humanoid:FindFirstChild("BodyHeightScale")
            local bodyWidthScale = humanoid:FindFirstChild("BodyWidthScale")
            local headScale = humanoid:FindFirstChild("HeadScale")

            if bodyDepthScale and bodyHeightScale and bodyWidthScale and headScale then
                bodyDepthScale.Value = 3
                bodyHeightScale.Value = 3
                bodyWidthScale.Value = 3
                headScale.Value = 3
            end
        end

    elseif command == "Make Normal" then
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            local character = humanoid.Parent
            if character then
                local targetScale = 1

                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local defaultSizes = {
                            Head = Vector3.new(2, 1, 1),
                            Torso = Vector3.new(2, 2, 1),
                            ["Left Arm"] = Vector3.new(1, 2, 1),
                            ["Right Arm"] = Vector3.new(1, 2, 1),
                            ["Left Leg"] = Vector3.new(1, 2, 1),
                            ["Right Leg"] = Vector3.new(1, 2, 1),
                            HumanoidRootPart = Vector3.new(2, 2, 1),
                        }

                        if defaultSizes[part.Name] then
                            part.Size = defaultSizes[part.Name] * targetScale
                        end

                        if part.Name == "Head" then
                            local mesh = part:FindFirstChildOfClass("SpecialMesh")
                            if mesh then
                                mesh.Scale = Vector3.new(1, 1, 1) * targetScale
                            end
                        end
                    end
                end
            end
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            local bodyDepthScale = humanoid:FindFirstChild("BodyDepthScale")
            local bodyHeightScale = humanoid:FindFirstChild("BodyHeightScale")
            local bodyWidthScale = humanoid:FindFirstChild("BodyWidthScale")
            local headScale = humanoid:FindFirstChild("HeadScale")

            if bodyDepthScale and bodyHeightScale and bodyWidthScale and headScale then
                bodyDepthScale.Value = 1
                bodyHeightScale.Value = 1
                bodyWidthScale.Value = 1
                headScale.Value = 1
            end
        end

    elseif command == "Make Tiny" then
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            local character = humanoid.Parent
            if character then
                local targetScale = 0.5

                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local defaultSizes = {
                            Head = Vector3.new(2, 1, 1),
                            Torso = Vector3.new(2, 2, 1),
                            ["Left Arm"] = Vector3.new(1, 2, 1),
                            ["Right Arm"] = Vector3.new(1, 2, 1),
                            ["Left Leg"] = Vector3.new(1, 2, 1),
                            ["Right Leg"] = Vector3.new(1, 2, 1),
                            HumanoidRootPart = Vector3.new(2, 2, 1),
                        }

                        if defaultSizes[part.Name] then
                            part.Size = defaultSizes[part.Name] * targetScale
                        end

                        if part.Name == "Head" then
                            local mesh = part:FindFirstChildOfClass("SpecialMesh")
                            if mesh then
                                mesh.Scale = Vector3.new(1, 1, 1) * targetScale
                            end
                        end
                    end
                end
            end
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            local bodyDepthScale = humanoid:FindFirstChild("BodyDepthScale")
            local bodyHeightScale = humanoid:FindFirstChild("BodyHeightScale")
            local bodyWidthScale = humanoid:FindFirstChild("BodyWidthScale")
            local headScale = humanoid:FindFirstChild("HeadScale")

            if bodyDepthScale and bodyHeightScale and bodyWidthScale and headScale then
                bodyDepthScale.Value = 0.5
                bodyHeightScale.Value = 0.5
                bodyWidthScale.Value = 0.5
                headScale.Value = 0.5
            end
        end

    elseif command == "Teleport to Player" then
        if rootPart and rootPartYOU then
            rootPartYOU.CFrame = rootPart.CFrame
        end

    elseif command == "Spin Player" then
        if rootPart then
            local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
            bodyAngularVelocity.AngularVelocity = Vector3.new(0, 50, 0)
            bodyAngularVelocity.MaxTorque = Vector3.new(0, 1e5, 0)
            bodyAngularVelocity.Parent = rootPart
            Debris:AddItem(bodyAngularVelocity, 3)
        end

    elseif command == "Spin Player FAST" then
        if rootPart then
            local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
            bodyAngularVelocity.AngularVelocity = Vector3.new(0, 1000, 0)
            bodyAngularVelocity.MaxTorque = Vector3.new(0, 1e8, 0)
            bodyAngularVelocity.Parent = rootPart
            Debris:AddItem(bodyAngularVelocity, 5)
        end

    elseif command == "Speed Boost" then
        if humanoid then
            local originalSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 50
            task.wait(10)
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
        end

    elseif command == "Slow Boost" then
        if humanoid then
            local originalSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 5
            task.wait(10)
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = originalSpeed
            end
        end

    elseif command == "Jump Boost" then
        if humanoid then
            if humanoid.UseJumpPower then
                local originalPower = humanoid.JumpPower
                humanoid.JumpPower = 150
                task.wait(10)
                if humanoid and humanoid.Parent then
                    humanoid.JumpPower = originalPower
                end
            else
                local originalHeight = humanoid.JumpHeight
                humanoid.JumpHeight = 20
                task.wait(10)
                if humanoid and humanoid.Parent then
                    humanoid.JumpHeight = originalHeight
                end
            end
        end

    elseif command == "Invisible" then
        local function setTransparency(char, value)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = value
                elseif part:IsA("Decal") then
                    part.Transparency = value
                end
            end
        end

        setTransparency(character, 1)
    elseif command == "Visible" then
        local function setTransparency(char, value)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = value
                elseif part:IsA("Decal") then
                    part.Transparency = value
                end
            end
        end
        setTransparency(character, 0)
    elseif command == "Jumpscare" then
        local action = "Jumpscare"
        AdminAction:FireClient(target, action, {})
    elseif command == "Random" then
        local actions = {
            "Fling Player",
            "Freeze Player",
            "UnFreeze Player",
            "Make Giant",
            "Make Normal",
            "Make Tiny",
            "Teleport to Player",
            "Spin Player",
            "Spin Player FAST",
            "Speed Boost",
            "Slow Boost",
            "Jump Boost",
            "Invisible",
            "Visible",
            "Jumpscare"
        }

        local randomCommand = actions[math.random(1, #actions)]
        print("Random command chosen: " .. randomCommand)

        HandleFunCommand(player, target, randomCommand)
    end
end

AdminAction.OnServerEvent:Connect(function(player, action, data)
    if action == "CheckWhitelistStatus" then
        AdminAction:FireClient(player, "WhitelistStatus", {
            IsWhitelisted = IsPlayerWhitelisted(player)
        })
        return
    end

    if not IsPlayerWhitelisted(player) then
        warn(player.Name .. " tried to use admin panel without permission!")
        return
    end

    if action == "SpawnThing" then
        local traits = data.Trait
        if type(traits) == "string" then
            local splitTraits = {}
            for trait in string.gmatch(traits, "[^,]+") do
                local cleaned = trait:match("^%s*(.-)%s*$")
                if cleaned ~= "" then
                    local alreadyExists = false
                    for _, existing in ipairs(splitTraits) do
                        if string.lower(existing) == string.lower(cleaned) then
                            alreadyExists = true
                            break
                        end
                    end

                    if not alreadyExists then
                        table.insert(splitTraits, cleaned)
                    end
                end
            end
            traits = splitTraits
        end

        if data.Global then
            MessagingService:PublishAsync("GlobalThing", {
                Amount = data.Amount,
                Name = data.Name,
                Traits = traits,
                Mutation = data.Mutation
            })
        else
            Things.Queue(data.Amount, data.Name, traits, data.Mutation)
        end
        
    elseif action == "SpawnInside" then
        local traits = data.Trait
        local username = data.Username

        if type(traits) == "string" then
            local splitTraits = {}
            for trait in string.gmatch(traits, "[^,]+") do
                local cleaned = trait:match("^%s*(.-)%s*$")
                if cleaned ~= "" then
                    local alreadyExists = false
                    for _, existing in ipairs(splitTraits) do
                        if string.lower(existing) == string.lower(cleaned) then
                            alreadyExists = true
                            break
                        end
                    end

                    if not alreadyExists then
                        table.insert(splitTraits, cleaned)
                    end
                end
            end
            traits = splitTraits
        end
        
        local players = FindPlayerByNameIgnoreCase(player, username)
        local targetPlayer = players[1]

        if not targetPlayer then
            warn("Player " .. username .. " not found in server.")
            return
        end

        local displayName = targetPlayer.DisplayName

        local basesFolder = workspace:FindFirstChild("Bases")
        if not basesFolder then
            warn("Folder 'Bases' not found.")
            return
        end

        local correctBase
        for _, baseModel in ipairs(basesFolder:GetChildren()) do
            local ownerPart = baseModel:FindFirstChild("Owner", true)
            if ownerPart and ownerPart:FindFirstChild("OwnerSurfaceGui") then
                local gui = ownerPart.OwnerSurfaceGui:FindFirstChildOfClass("TextLabel")
                if gui and string.find(gui.Text, displayName) then
                    correctBase = baseModel
                    break
                end
            end
        end

        if not correctBase then
            warn("No base found for " .. displayName)
            return
        end

        local slotsFolder = correctBase:FindFirstChild("Slots")
        if not slotsFolder then
            warn("Slots folder not found in base of " .. displayName)
            return
        end

        local chosenSlot
        for _, slot in ipairs(slotsFolder:GetChildren()) do
            if slot:IsA("Model") and slot:FindFirstChild("Configuration") then
                local config = slot.Configuration
                local rebirthValue = config:FindFirstChild("Rebirth")
                local thingValue = config:FindFirstChild("Thing")
                local occuValue = config:FindFirstChild("Occupied")

                local leaderstats = targetPlayer:FindFirstChild("leaderstats")
                local playerRebirth = leaderstats and leaderstats:FindFirstChild("Rebirths")

                if thingValue and thingValue.Value == nil and occuValue and occuValue.Value == false and playerRebirth.Value >= rebirthValue.Value then
                    chosenSlot = slot
                    break
                end
            end
        end

        if not chosenSlot then
            warn("No free slot found for " .. displayName)
            return
        end
        
        print("SpawnInside for " .. displayName .. " in slot " .. chosenSlot.Name)
        Things.Add(targetPlayer, correctBase, chosenSlot, data.Name, traits, data.Mutation, os.time())
        
    elseif action == "LockBase" then
        local durations = data.Duration
        local username = data.Username

        local players = FindPlayerByNameIgnoreCase(player, username)
        local targetPlayer = players[1]

        if not targetPlayer then
            warn("Player " .. username .. " not found in server.")
            return
        end

        local displayName = targetPlayer.DisplayName

        local basesFolder = workspace:FindFirstChild("Bases")
        if not basesFolder then
            warn("Folder 'Bases' not found.")
            return
        end

        local correctBase
        for _, baseModel in ipairs(basesFolder:GetChildren()) do
            local ownerPart = baseModel:FindFirstChild("Owner", true)
            if ownerPart and ownerPart:FindFirstChild("OwnerSurfaceGui") then
                local gui = ownerPart.OwnerSurfaceGui:FindFirstChildOfClass("TextLabel")
                if gui and string.find(gui.Text, displayName) then
                    correctBase = baseModel
                    break
                end
            end
        end

        if not correctBase then
            warn("No base found for " .. displayName)
            return
        end
        
        lockPlayerBase(correctBase, durations)
        
    elseif action == "UnlockBase" then
        local username = data.Username

        local players = FindPlayerByNameIgnoreCase(player, username)
        local targetPlayer = players[1]

        if not targetPlayer then
            warn("Player " .. username .. " not found in server.")
            return
        end

        local displayName = targetPlayer.DisplayName

        local basesFolder = workspace:FindFirstChild("Bases")
        if not basesFolder then
            warn("Folder 'Bases' not found.")
            return
        end

        local correctBase
        for _, baseModel in ipairs(basesFolder:GetChildren()) do
            local ownerPart = baseModel:FindFirstChild("Owner", true)
            if ownerPart and ownerPart:FindFirstChild("OwnerSurfaceGui") then
                local gui = ownerPart.OwnerSurfaceGui:FindFirstChildOfClass("TextLabel")
                if gui and string.find(gui.Text, displayName) then
                    correctBase = baseModel
                    break
                end
            end
        end

        if not correctBase then
            warn("No base found for " .. displayName)
            return
        end

        unlockPlayerBase(correctBase)

    elseif action == "Trait" then
        if data.Global then
            MessagingService:PublishAsync("GlobalTrait", {
                Trait = data.Trait,
                Active = data.Active
            })
        else
            Things.Trait(data.Trait, data.Active)
        end

    elseif action == "ServerLuck" then
        if data.Global then
            MessagingService:PublishAsync("GlobalServerLuck", {
                Luck = data.Luck,
                Time = data.Time
            })
        else
            Things.ServerLuck(data.Luck, data.Time)
        end

    elseif action == "Announcement" then
        if data.Global then
            MessagingService:PublishAsync("GlobalAnnouncement", data.Text)
        else
            local AnnouncementEvent = ReplicatedStorage.Remotes.Events:WaitForChild("Announcement")
            AnnouncementEvent:FireAllClients(data.Text)
        end

    elseif action == "Event" then
        if data.Global then

            local Event = data.EventName
            local Configuration = Events[Event]
            if not Configuration then return end

            local Time = tonumber(Configuration.Time)
            if not Time or Time <= 0 then return end

            MessagingService:PublishAsync("GlobalEvent", {Event = Event, Time = Time})
        else
            local Event = data.EventName
            local Configuration = Events[Event]
            if not Configuration then return end

            local Time = tonumber(Configuration.Time)
            if not Time or Time <= 0 then return end

            local PreviousEvent = Events[Things.CurrentEvent]
            if Things.CurrentEvent ~= Event and Things.CurrentEvent and PreviousEvent and PreviousEvent.Stop then
                PreviousEvent.Stop()
            end

            Things.CurrentEvent = Event

            if Configuration.Start then
                Configuration.Start()
            end

            task.delay(Time, function()
                if Things.CurrentEvent == Event then
                    if Configuration.Stop then
                        Configuration.Stop()
                    end
                    Things.CurrentEvent = nil
                end
            end)
        end

    elseif action == "FunCommand" then
        local targetName = data.Target
        local command = data.Command

        local targetPlayers = FindPlayerByNameIgnoreCase(player, targetName)
        for _, targetPlayer in ipairs(targetPlayers) do
            if targetPlayer and targetPlayer.Character then
                task.spawn(function()
                    HandleFunCommand(player, targetPlayer, command)
                end)
            end
		end
		
    elseif action == "Morph" then
        local targetName = data.Target
        local thingName = data.Thing
        local mutationName = data.Mutation
        local traits = data.Traits
        
        if type(traits) == "string" then
            local splitTraits = {}
            for trait in string.gmatch(traits, "[^,]+") do
                local cleaned = trait:match("^%s*(.-)%s*$")
                if cleaned ~= "" then
                    local alreadyExists = false
                    for _, existing in ipairs(splitTraits) do
                        if string.lower(existing) == string.lower(cleaned) then
                            alreadyExists = true
                            break
                        end
                    end

                    if not alreadyExists then
                        local capitalized = cleaned:sub(1,1):upper() .. cleaned:sub(2):lower()
                        table.insert(splitTraits, capitalized)
                    end
                end
            end
            traits = splitTraits
        end

        local targetPlayers = FindPlayerByNameIgnoreCase3(player, targetName)
        local plr = targetPlayers[1]

        if not plr then
            warn("Target player not found.")
            return
        end

        local thingsFolder = ServerStorage:FindFirstChild("Things")
        if not thingsFolder then
            warn("Folder 'Things' not found in ServerStorage.")
            return
        end

        local mutationFolder = thingsFolder:FindFirstChild(mutationName)
        if not mutationFolder then
            warn("Mutation '" .. tostring(mutationName) .. "' not found inside 'Things'.")
            return
        end

        local foundThing = nil
        for _, descendant in ipairs(mutationFolder:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == thingName then
                foundThing = descendant
                break
            end
        end

        if not foundThing then
            warn("Thing '" .. tostring(thingName) .. "' not found inside mutation '" .. tostring(mutationName) .. "'.")
            return
        end

        local oldChar = plr.Character
        if not oldChar then
            warn("Player has no character to morph from.")
            return
        end

        local charClone = foundThing:Clone()
        charClone.Name = thingName

        local oldHumanoid = oldChar:FindFirstChildOfClass("Humanoid")
        if not oldHumanoid then
            warn("Old character has no Humanoid.")
            return
        end

        local newHumanoid = charClone:FindFirstChildOfClass("Humanoid")
        if not newHumanoid then
            newHumanoid = Instance.new("Humanoid")
            newHumanoid.Parent = charClone
            newHumanoid.HipHeight = 2
            newHumanoid.Parent = charClone
            print("No Humanoid found in Thing → created new Humanoid.")
        end

        local propertiesToCopy = {
            "Health","MaxHealth","WalkSpeed","JumpPower","JumpHeight","UseJumpPower","RigType","DisplayDistanceType",
            "NameDisplayDistance","NameOcclusion"
        }

        for _, prop in ipairs(propertiesToCopy) do
            if oldHumanoid[prop] ~= nil and newHumanoid[prop] ~= nil then
                newHumanoid[prop] = oldHumanoid[prop]
            end
        end

        local newRoot = charClone:FindFirstChild("HumanoidRootPart") or charClone:FindFirstChild("Torso")
        local oldRoot = oldChar:FindFirstChild("HumanoidRootPart") or oldChar:FindFirstChild("Torso")

        -- 🔥 Eigene Animationen laden aus Things2
        local thingData = Things2.Things[thingName]
        if thingData then
            local morphAnimateTemplate = script:WaitForChild("MorphAnimateTemplate")
            local morphAnimate = morphAnimateTemplate:Clone()
            morphAnimate:SetAttribute("IdleAnim", thingData.IdleAnimation or "")
            morphAnimate:SetAttribute("WalkAnim", thingData.RunAnimation or thingData.WalkAnimation or "")
            morphAnimate:SetAttribute("RunAnim", thingData.RunAnimation or thingData.WalkAnimation or "")
            morphAnimate.Parent = charClone
        end

        plr.Character = charClone
        charClone.Parent = workspace

        for _, descendant in ipairs(charClone:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Massless = true
            end
        end

        task.spawn(function()
            task.wait(1)
            if newRoot then
                newRoot.Anchored = false
                newRoot.CFrame = oldRoot.CFrame + Vector3.new(0, 3, 0)
            end
        end)

        if oldChar then oldChar:Destroy() end
        
        Insert.Thing(charClone, thingData, traits, mutationName)
		
	elseif action == "ResetMorph" then
		local targetName = data.Target

		local targetPlayers = FindPlayerByNameIgnoreCase3(player, targetName)
		local plr = targetPlayers[1]

		if not plr then
			warn("Target player not found for ResetMorph.")
			return
		end

		local oldChar = plr.Character
		if not oldChar then
			warn("Player has no character to reset.")
			return
		end

		local oldRoot = oldChar:FindFirstChild("HumanoidRootPart") or oldChar:FindFirstChild("Torso")
		local lastCFrame = oldRoot and oldRoot.CFrame

		plr:LoadCharacter()

		local newChar = plr.Character
		if newChar then
			spawn(function()
				local newRoot = newChar:WaitForChild("HumanoidRootPart", 5) or newChar:FindFirstChild("Torso")
				if newRoot and lastCFrame then
					newRoot.Anchored = false
					newRoot.CFrame = lastCFrame
					print("Player " .. plr.Name .. " character position restored after reset.")
				else
					warn("Failed to restore position: HumanoidRootPart not found.")
				end
			end)
		end
		
    elseif action == "UpdateStats" then
        local targetName = data.Target
        local stat = data.Stat
        local amount = data.Amount

        local targetPlayers = FindPlayerByNameIgnoreCase(player, targetName)
        for _, targetPlayer in ipairs(targetPlayers) do
            local leaderstats = targetPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local statValue = leaderstats:FindFirstChild(stat)
                if statValue and statValue:IsA("IntValue") then
                    statValue.Value = statValue.Value + amount
                end
            end
        end
        
    elseif action == "ResetStats" then
        local targetName = data.Target
        local stat = data.Stat

        local targetPlayers = FindPlayerByNameIgnoreCase(player, targetName)
        for _, targetPlayer in ipairs(targetPlayers) do
            local leaderstats = targetPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local statValue = leaderstats:FindFirstChild(stat)
                if statValue and statValue:IsA("IntValue") then
                    statValue.Value = 0
                end
            end
        end

    elseif action == "ModeratePlayer" then
        local targetName = data.Target
        local moderationType = data.Type
        local reason = data.Reason
        local targetPlayer = FindPlayerByNameIgnoreCase2(targetName)

        local function GetUserIdFromName(name)
            local success, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(name)
            end)
            if success then
                return userId
            end
            return nil
        end

        if moderationType == "Kick" then
            if targetPlayer and targetPlayer ~= player then
                -- Whitelist-Check
                if IsPlayerWhitelisted(targetPlayer) then
                    warn(player.Name .. " tried to kick whitelisted player " .. targetPlayer.Name)
                    return
                end
                targetPlayer:Kick((reason and reason ~= "") and reason or "You got Banned!")
            end

        elseif moderationType == "Ban" then
            if targetPlayer ~= player then
                local userId = GetUserIdFromName(targetName)
                if userId then
                    -- Whitelist-Check
                    if IsPlayerWhitelisted(targetPlayer or {UserId = userId, Name = targetName}) then
                        warn(player.Name .. " tried to ban whitelisted player " .. targetName)
                        return
                    end

                    local alreadyBanned = false
                    pcall(function()
                        local banInfo = BanDataStore:GetAsync(tostring(userId))
                        if banInfo and banInfo.Banned then
                            alreadyBanned = true
                        end
                    end)

                    if alreadyBanned then
                        warn(targetName .. " is already banned.")
                        return
                    end

                    pcall(function()
                        BanDataStore:SetAsync(tostring(userId), {
                            Banned = true,
                            BannedBy = player.Name,
                            BannedAt = os.time(),
                            Reason = (reason and reason ~= "") and reason or "You got Banned!"
                        })
                    end)

                    pcall(function()
                        local list = BanListStore:GetAsync("BanList") or {}
                        if not table.find(list, userId) then
                            table.insert(list, userId)
                            BanListStore:SetAsync("BanList", list)
                        end
                    end)

                    local targetInGame = Players:GetPlayerByUserId(userId)
                    if targetInGame then
                        targetInGame:Kick("You have been banned from this game.")
                    end

                    UpdateBanList()

                    print("Player " .. targetName .. " got banned.")
                else
                    warn("Could not find UserId for " .. targetName .. ".")
                end
            end

        elseif moderationType == "Unban" then
            local userId = GetUserIdFromName(targetName)
            if userId then
                local banInfo
                local success, err = pcall(function()
                    banInfo = BanDataStore:GetAsync(tostring(userId))
                end)

                if success then
                    if banInfo and banInfo.Banned == true then
                        pcall(function()
                            BanDataStore:RemoveAsync(tostring(userId))
                        end)
                        print("Player " .. targetName .. " has been unbanned.")
                    else
                        print("Player " .. targetName .. " is not banned.")
                    end
                else
                    warn("Failed to check ban status for " .. targetName .. ": " .. tostring(err))
                end
                
                pcall(function()
                    local list = BanListStore:GetAsync("BanList") or {}
                    for i, id in ipairs(list) do
                        if id == userId then
                            table.remove(list, i)
                            break
                        end
                    end
                    BanListStore:SetAsync("BanList", list)
                end)
                
                UpdateBanList()
            else
                warn("Could not find UserId for " .. targetName .. ".")
            end

        elseif action == "GetDropdownData" then
            local dataType = data.Type

            if dataType == "Players" then
                local playerList = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    table.insert(playerList, p.Name)
                end
                AdminAction:FireClient(player, "DropdownData", {
                    Type = "Players",
                    Data = playerList
                })
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    local success, banData = pcall(function()
        return BanDataStore:GetAsync(tostring(player.UserId))
    end)

    if success and banData and banData.Banned then
        player:Kick("You are banned from this game. Reason: " .. (banData.Reason or "No reason provided"))
    end
    
    if IsPlayerWhitelisted(player) then
        UpdateBanList(player)
    end
end)
