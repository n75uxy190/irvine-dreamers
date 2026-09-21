local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, speed: number, size: number)
	local mainGradient = TextEffects.Gradient.new(uiInstance, TextEffects.Templates.Zebra.Color, 0);
	mainGradient:SetOffsetSpeed(speed, 1);
	mainGradient:SetRotation(90, 1);

	local mainStroke = TextEffects.Stroke.new(uiInstance, size);

	-- Wait until the stroke instance is created and parented before using it
	repeat task.wait() until mainStroke.Instance and mainStroke.Instance.Parent

	local strokeGradient = TextEffects.Gradient.new(mainStroke.Instance, TextEffects.Templates.Zebra.Color, 0);
	strokeGradient:SetOffset(0.5, 1);
	strokeGradient:SetRotation(90, 1);

	-- Ensure the gradient's instance is initialized and parented before setting speed
	repeat task.wait() until strokeGradient.Instance and strokeGradient.Instance.Parent

	task.delay(0.1, function()
		strokeGradient:SetOffsetSpeed(speed, 1);
	end);

	return {
		Effects = { mainGradient, strokeGradient, mainStroke }
	};
end
