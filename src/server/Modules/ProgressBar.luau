local TweenService = game:GetService("TweenService")
local ProgressBar = {}

function ProgressBar.Show(parent)
	if not parent then return end

	for _, decendant in pairs(parent:GetDescendants()) do
		if decendant:IsA("Frame") then decendant.Visible = true end
	end
end

function ProgressBar.Hide(parent)
	if not parent then return end

	for _, decendant in pairs(parent:GetDescendants()) do
		if decendant:IsA("Frame") then decendant.Visible = false end
	end
end

function ProgressBar.Update(progressBarFrame: Frame, currentValue: number, maxValue: number)
	local max = maxValue or 0
	local current = currentValue or 0
	local progress = (max > 0) and math.clamp(current / max, 0, 1) or 0

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local goal = { Size = UDim2.fromScale(progress, 1) }

	local _progressTween = nil
	if _progressTween then
		_progressTween:Cancel()
		_progressTween = nil
	end

	local tween = TweenService:Create(progressBarFrame, tweenInfo, goal)
	tween:Play()

	tween.Completed:Once(function()
		if _progressTween == tween then _progressTween = nil end
	end)
end

return ProgressBar
