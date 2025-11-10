local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local PlayerNotification = {}

export type Props = {
	Text: string,
	Type: "Green" | "Red",
}

function PlayerNotification.Create(props: Props)
	local messageTemplate = Instance.new("Frame")
	messageTemplate.Name = "MessageTemplate"
	messageTemplate.AnchorPoint = Vector2.new(0.5, 1)
	messageTemplate.BackgroundColor3 = Color3.new(1, 1, 1)
	messageTemplate.Position = UDim2.fromScale(0.5, 1)
	messageTemplate.Size = UDim2.fromScale(1, 0.3)

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
	textLabel.Text = props.Text or ""
	textLabel.TextColor3 = props.Type == "Red" and FFGEnum.THEME.color.red or FFGEnum.THEME.color.Green
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = messageTemplate

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.290713, 0.553567)

	local messageIcon = Instance.new("ImageLabel")
	messageIcon.Name = "MessageIcon"
	messageIcon.AnchorPoint = Vector2.new(0.5, 1)
	messageIcon.BackgroundTransparency = 1
	messageIcon.Image = props.Type == "Red" and FFGEnum.UI.Icons.Alert or FFGEnum.UI.Icons.ThumbsUp
	messageIcon.ImageColor3 = Color3.fromRGB(255, 255, 0)
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

function PlayerNotification.Animate(frame: Frame)
	local DEFAULTS = {
		Duration = 3,
	}

	if frame then
		local tweenGoal = {
			Position = FFGEnum.THEME.alignment.position.top,
		}

		local _progressTween = nil
		if _progressTween then
			_progressTween:Cancel()
			_progressTween = nil
		end

		local tweenInfo = TweenInfo.new(DEFAULTS.Duration)
		local tween = TweenService:Create(frame, tweenInfo, tweenGoal)

		tween.Completed:Once(function()
			if _progressTween == tween then _progressTween = nil end
			fadeOut(frame, 1)
		end)

		tween:Play()
	end
end

return PlayerNotification
