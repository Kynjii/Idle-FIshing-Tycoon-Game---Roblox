local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local SkillTypes = require(ReplicatedStorage.Shared.Types.SkillTypes)
local SkillUpNotification = {}

function SkillUpNotification.Create(text: string, skill: SkillTypes.SkillType)
	local messageTemplate = Instance.new("Frame")
	messageTemplate.Name = "MessageTemplate"
	messageTemplate.AnchorPoint = Vector2.new(0.5, 1)
	messageTemplate.BackgroundColor3 = Color3.new(1, 1, 1)
	messageTemplate.Position = UDim2.fromScale(0.5, 1)
	messageTemplate.Size = UDim2.fromScale(1, 0.7)

	local uIGradient = Instance.new("UIGradient")
	uIGradient.Name = "UIGradient"
	uIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0, 10, 22)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0, 10, 22)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	uIGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.197007, 0.75),
		NumberSequenceKeypoint.new(0.5, 0.24375),
		NumberSequenceKeypoint.new(0.799252, 0.7375),
		NumberSequenceKeypoint.new(1, 1),
	})
	uIGradient.Parent = messageTemplate

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Text = text or ""
	textLabel.TextColor3 = FFGEnum.THEME.color.Green
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = messageTemplate

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.6, 0.6)

	local messageIcon = Instance.new("ImageLabel")
	messageIcon.Name = "MessageIcon"
	messageIcon.AnchorPoint = Vector2.new(0.5, 1)
	messageIcon.BackgroundTransparency = 1
	messageIcon.Image = FFGEnum.UI.Icons[skill]
	messageIcon.Position = UDim2.fromScale(0.5, 0)
	messageIcon.ScaleType = Enum.ScaleType.Fit
	messageIcon.Size = UDim2.fromScale(0.4, 1)
	messageIcon.Parent = frame

	frame.Parent = messageTemplate

	return messageTemplate
end

local function fadeOut(frame: Frame, duration: number)
	local tweenGoal = {
		Transparency = 1,
	}

	local _progressTween = nil
	if _progressTween then
		_progressTween:Cancel()
		_progressTween = nil
	end

	local tweenInfo = TweenInfo.new(duration)
	local tween = TweenService:Create(frame, tweenInfo, tweenGoal)

	tween.Completed:Once(function()
		if _progressTween == tween then _progressTween = nil end
		frame:Destroy()
	end)

	tween:Play()
end

function SkillUpNotification.Animate(frame: Frame)
	local DEFAULTS = {
		Duration1 = 2.5,
		Duration2 = 0.5,
	}

	if frame then
		local tweenGoal1 = {
			Position = FFGEnum.THEME.alignment.position.top,
		}

		local tweenGoal2 = {
			Position = FFGEnum.THEME.alignment.position.bottom,
		}

		local _progressTween = nil
		if _progressTween then
			_progressTween:Cancel()
			_progressTween = nil
		end

		local tweenInfo1 = TweenInfo.new(DEFAULTS.Duration1)
		local tweenInfo2 = TweenInfo.new(DEFAULTS.Duration2)
		local tween1 = TweenService:Create(frame, tweenInfo1, tweenGoal1)
		local tween2 = TweenService:Create(frame, tweenInfo2, tweenGoal2)

		tween1.Completed:Once(function()
			if _progressTween == tween1 then _progressTween = tween2 end
			tween2:Play()
		end)

		tween2.Completed:Once(function()
			if _progressTween == tween2 then _progressTween = nil end
			fadeOut(frame, 1)
		end)

		tween1:Play()
	end
end

return SkillUpNotification
