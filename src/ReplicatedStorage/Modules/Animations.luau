local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PlayerGui = Player:WaitForChild("PlayerGui")

local Blur = Lighting:WaitForChild("Blur")

local function TweenFrame(Frame, Visible)
	local FinalPosition = Visible and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1.5, 0)

	if Visible then
		Frame.Position = UDim2.new(0.5, 0, 1.5, 0)
		task.wait()
		Frame.Visible = true
	end

	local Tween = TweenService:Create(
		Frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{Position = FinalPosition}
	)

	Tween:Play()

	if not Visible then
		Tween.Completed:Once(function()
			Frame.Visible = false
			Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		end)
	end
end

local function TweenCamera(Visible)
	local TargetFieldOfView = Visible and 60 or 70

	local Tween = TweenService:Create(
		Camera,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{FieldOfView = TargetFieldOfView}
	)

	Tween:Play()
end

local function TweenBlur(Visible)
	local TargetSize = Visible and 10 or 0

	if Visible then
		Blur.Size = 0
		Blur.Enabled = true
	end

	local Tween = TweenService:Create(
		Blur,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{Size = TargetSize}
	)

	Tween:Play()

	if not Visible then
		Tween.Completed:Once(function()
			local FramesToCheck = {
				PlayerGui.IndexGui.IndexFrame,
				PlayerGui.RebirthGui.RebirthFrame,
				PlayerGui.ShopGui.ShopFrame,
			}

			local AnyStillOpen = false
			for _, FrameToCheck in ipairs(FramesToCheck) do
				if FrameToCheck.Visible then
					AnyStillOpen = true
					break
				end
			end

			if not AnyStillOpen then
				Blur.Enabled = false
			end
		end)
	end
end

local function TweenButton(UIScale, Scale)
	local Tween = TweenService:Create(
		UIScale,
		TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{Scale = Scale}
	)

	Tween:Play()
end

local Animations = {}

function Animations:AnimateFrame(Frame, Visible)
	if not Frame or not Frame:IsA("Frame") then return end
	
	local Open = SoundService.Sounds:WaitForChild("Open")
	local Close = SoundService.Sounds:WaitForChild("Close")
	
	if Visible then
		Open:Play()
	else
		Close:Play()
	end
	
	local FramesToCheck = {
		PlayerGui.IndexGui.IndexFrame,
		PlayerGui.RebirthGui.RebirthFrame,
		PlayerGui.ShopGui.ShopFrame,
		PlayerGui.RobuxShopGui.RobuxShopFrame
	}

	for _, Descendant in ipairs(FramesToCheck) do
		if Descendant ~= Frame and Descendant.Visible then
			TweenFrame(Descendant, false)
			TweenCamera(false)
			TweenBlur(false)
		end
	end

	if Frame.Visible and not Visible then
		TweenFrame(Frame, false)
		TweenCamera(false)
		TweenBlur(false)
	elseif not Frame.Visible and Visible then
		TweenFrame(Frame, true)
		TweenCamera(true)
		TweenBlur(true)
	end
end

function Animations:AnimateButton(Button)
	if not Button then return end

	local Select = SoundService.Sounds:WaitForChild("Select")

	Button.MouseEnter:Connect(function()
		TweenButton(Button.UIScale, 1.1)
		Select:Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenButton(Button.UIScale, 1)
	end)

	Button.MouseButton1Down:Connect(function()
		TweenButton(Button.UIScale, 0.9)
	end)

	Button.MouseButton1Up:Connect(function()
		TweenButton(Button.UIScale, 1)
	end)

	Button.Activated:Connect(function()
		TweenButton(Button.UIScale, 1)
	end)
end

return Animations