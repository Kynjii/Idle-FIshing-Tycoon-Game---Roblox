local TweenService = game:GetService("TweenService")
local ButtonHover = {}

function ButtonHover.Enter(button: ImageButton | TextButton, baseSize: UDim2)
	local tweenGoal = {
		Size = baseSize + UDim2.fromScale(0.01, 0.01),
	}

	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local tween = TweenService:Create(button, tweenInfo, tweenGoal)
	tween:Play()

	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

function ButtonHover.Leave(button: ImageButton | TextButton, baseSize: UDim2)
	local tweenGoal = {
		Size = baseSize,
	}

	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local tween = TweenService:Create(button, tweenInfo, tweenGoal)
	tween:Play()

	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

return ButtonHover
