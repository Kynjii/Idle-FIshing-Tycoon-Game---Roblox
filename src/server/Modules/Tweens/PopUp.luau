local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local PopUp = {}

local DEFAULTS = {
	Duration = 1,
}

function PopUp.Animate(billboard: BillboardGui, textValue: number, imageLabel: ImageLabel)
	if billboard and textValue then
		local image = imageLabel
		local text = billboard:WaitForChild("TextLabel") :: TextLabel

		billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 10)
		text.Font = FFGEnum.THEME.font
		text.Text = "+" .. FormatNumber(textValue)
		text.TextColor3 = Color3.fromRGB(0, 255, 0)

		PopUp.AnimateBillboard(billboard)
		if image then PopUp.AnimateImageLabel(image) end
		if text then PopUp.AnimateTextLabel(text) end
	end
end

function PopUp.AnimateImageLabel(imageLabel: ImageLabel)
	local tweenGoal = {
		ImageTransparency = 0,
	}

	local _progressTween = nil
	if _progressTween then
		_progressTween:Cancel()
		_progressTween = nil
	end

	local tweenInfo = TweenInfo.new(DEFAULTS.Duration)
	local tween = TweenService:Create(imageLabel, tweenInfo, tweenGoal)

	tween.Completed:Once(function()
		if _progressTween == tween then _progressTween = nil end
	end)

	tween:Play()
end

function PopUp.AnimateTextLabel(textLabel: ImageLabel)
	local tweenGoal = {
		TextTransparency = 0,
	}

	local _progressTween = nil
	if _progressTween then
		_progressTween:Cancel()
		_progressTween = nil
	end

	local tweenInfo = TweenInfo.new(DEFAULTS.Duration)
	local tween = TweenService:Create(textLabel, tweenInfo, tweenGoal)

	tween.Completed:Once(function()
		if _progressTween == tween then _progressTween = nil end
	end)

	tween:Play()
end

function PopUp.AnimateBillboard(billboard: BillboardGui)
	local tweenGoal = {
		StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 0, 2),
	}

	local _progressTween = nil
	if _progressTween then
		_progressTween:Cancel()
		_progressTween = nil
	end

	local tweenInfo = TweenInfo.new(DEFAULTS.Duration)
	local tween = TweenService:Create(billboard, tweenInfo, tweenGoal)

	tween.Completed:Once(function()
		if _progressTween == tween then _progressTween = nil end
		billboard:Destroy()
	end)

	tween:Play()
end

return PopUp
