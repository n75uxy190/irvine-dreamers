local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, speed: number, size: number)
	local mainGradient = TextEffects.Gradient.new(uiInstance, TextEffects.Templates.Oceanic.Color, 0);
	mainGradient:SetOffsetSpeed(speed, 1);
	mainGradient:SetRotation(-75, 1);
	mainGradient:SetRotationSpeed(0.1, 1);

	local mainStroke = TextEffects.Stroke.new(uiInstance, size);

	-- Wait until the stroke instance is created and parented before using it
	repeat task.wait() until mainStroke.Instance and mainStroke.Instance.Parent

	local strokeGradient = TextEffects.Gradient.new(mainStroke.Instance, TextEffects.Templates.Oceanic.Color, 0);
	strokeGradient:SetOffsetSpeed(-speed, 1);

	-- Ensure the gradient's instance is initialized and parented before setting speed
	repeat task.wait() until strokeGradient.Instance and strokeGradient.Instance.Parent

	return {
		Effects = { mainGradient, strokeGradient, mainStroke }
	};
end
