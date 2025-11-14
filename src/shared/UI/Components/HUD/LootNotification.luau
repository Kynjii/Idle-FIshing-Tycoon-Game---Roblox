local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local LootNotification = {}

export type Props = {
	ItemType: "Gold" | "Fishing",
	Text: string?,
}

function LootNotification.Create(props: Props)
	local lootNotificationContainer = Instance.new("CanvasGroup")
	lootNotificationContainer.Name = "LootNotificationContainer"
	lootNotificationContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	lootNotificationContainer.Position = FFGEnum.THEME.alignment.position.bottom
	lootNotificationContainer.Transparency = 1
	lootNotificationContainer.Visible = true
	lootNotificationContainer.Size = UDim2.fromScale(1, 0.4)

	local bG = Instance.new("ImageLabel")
	bG.Name = "BG"
	bG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	bG.BackgroundTransparency = 1
	bG.Image = FFGEnum.UI.ProgressBar.InnerBar.BlueTrape.Asset
	bG.Position = FFGEnum.THEME.alignment.position.center
	bG.Rotation = 180
	bG.ImageColor3 = FFGEnum.THEME.button.pressedColor
	bG.ScaleType = Enum.ScaleType.Slice
	bG.Size = UDim2.fromScale(1, 1)
	bG.SliceCenter = FFGEnum.UI.ProgressBar.InnerBar.BlueTrape.SliceCenter
	bG.Parent = lootNotificationContainer

	local lootContainer = Instance.new("Frame")
	lootContainer.Name = "LootContainer"
	lootContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	lootContainer.BackgroundTransparency = 1
	lootContainer.Position = FFGEnum.THEME.alignment.position.center
	lootContainer.Size = UDim2.fromScale(1, 1)
	lootContainer.ZIndex = 5
	KinUI.ApplyList(lootContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Left, VAlign = Enum.VerticalAlignment.Center, Padding = "M" })

	if props.ItemType then
		local lootImage = Instance.new("ImageLabel")
		lootImage.Name = "LootImage"
		lootImage.AnchorPoint = Vector2.new(1, 0.5)
		lootImage.BackgroundTransparency = 1
		lootImage.Image = FFGEnum.UI.Icons[props.ItemType] or ""
		lootImage.LayoutOrder = 1
		lootImage.Position = FFGEnum.THEME.alignment.position.center
		lootImage.ScaleType = Enum.ScaleType.Fit
		lootImage.Size = UDim2.fromScale(0.3, 0.7)
		KinUI.ApplyAspect(lootImage, 16 / 9, Enum.DominantAxis.Width, Enum.AspectType.ScaleWithParentSize)
		lootImage.Parent = lootContainer
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Text = props.Text or ""
	textLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	textLabel.BackgroundTransparency = 1
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.LayoutOrder = 2
	textLabel.Position = FFGEnum.THEME.alignment.position.center
	textLabel.Size = UDim2.fromScale(0.7, 0.9)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.7
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextScaled = true
	textLabel.ZIndex = 5
	textLabel.Parent = lootContainer

	lootContainer.Parent = lootNotificationContainer

	return lootNotificationContainer
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

function LootNotification.Animate(frame: Frame)
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

return LootNotification
