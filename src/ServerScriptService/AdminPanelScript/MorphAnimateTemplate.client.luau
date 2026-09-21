local humanoid = script.Parent:WaitForChild("Humanoid")

local idleAnimId = script:GetAttribute("IdleAnim") or ""
local walkAnimId = script:GetAttribute("WalkAnim") or ""
local runAnimId = script:GetAttribute("RunAnim") or ""

local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = idleAnimId
local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = walkAnimId
local runAnim = Instance.new("Animation")
runAnim.AnimationId = runAnimId

local idleTrack = humanoid:LoadAnimation(idleAnim)
local walkTrack = humanoid:LoadAnimation(walkAnim)
local runTrack = humanoid:LoadAnimation(runAnim)

idleTrack:Play()

humanoid.Running:Connect(function(speed)
    if speed > 0 then
        if idleTrack.IsPlaying then idleTrack:Stop() end
        if speed > humanoid.WalkSpeed*0.6 then
            if not runTrack.IsPlaying then runTrack:Play() end
            if walkTrack.IsPlaying then walkTrack:Stop() end
        else
            if not walkTrack.IsPlaying then walkTrack:Play() end
            if runTrack.IsPlaying then runTrack:Stop() end
        end
    else
        if not idleTrack.IsPlaying then idleTrack:Play() end
        if walkTrack.IsPlaying then walkTrack:Stop() end
        if runTrack.IsPlaying then runTrack:Stop() end
    end
end)