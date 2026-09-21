local MedusaHead = {}

function MedusaHead.Attach(ctx)
	local Tool = ctx.Tool
	local cfg = ctx.Configuration
	local ActivationTrack = ctx.ActivationTrack

	Tool.Activated:Connect(function()
		if ActivationTrack then
			pcall(function() ActivationTrack:Play() end)
		end
	end)
end

return MedusaHead
