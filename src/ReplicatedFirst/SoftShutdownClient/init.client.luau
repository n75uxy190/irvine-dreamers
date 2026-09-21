local TeleportService = game:GetService("TeleportService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Gui = script:WaitForChild("ShutdownUI")
local TeleportData = TeleportService:GetLocalPlayerTeleportData()
if typeof(TeleportData)~='nil' then
	print(TeleportData)
end
local function DisableCoreUI()
	pcall(function()
		while StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All) do
			task.wait()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end
	end)
end
if typeof(TeleportData)~='nil' and TeleportData["SoftShutdown"][1]==true then
	local ArrivingGui = Gui:Clone()
	ArrivingGui.Parent = PlayerGui
	ArrivingGui:WaitForChild(TeleportData["SoftShutdown"][2]).Enabled=true
	if TeleportData["SoftShutdown"][2]=="Addition" then
		DisableCoreUI()
		local MidTerm=script["MidTermUI"]:WaitForChild("Removal"):Clone()
		TeleportService:SetTeleportGui(MidTerm)
	end
end
if typeof(TeleportData)=='nil' or TeleportData["SoftShutdown"][2]=="Removal" then
	local MidTerm=script["MidTermUI"]:WaitForChild("Addition"):Clone()
	TeleportService:SetTeleportGui(MidTerm)
end
workspace:GetAttributeChangedSignal("ShuttingDown"):Wait()
DisableCoreUI()
local NewGui=Gui:Clone()
NewGui.Parent=PlayerGui
NewGui:WaitForChild("InterfaceScript").Enabled=true