local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local LootNotification = {}

export type Props = {
	ItemImage: "Gold" | "Fishing",
	Text: string?,
}

function LootNotification.Create(props: Props)
	local lootNotificationContainer = Instance.new("CanvasGroup")
	lootNotificationContainer.Name = "NotificationContainer"
	lootNotificationContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	lootNotificationContainer.BackgroundTransparency = 1
	lootNotificationContainer.Position = UDim2.fromScale(0.5, 0.130233)
	lootNotificationContainer.Size = UDim2.fromScale(1, 0.28)
	KinUI.AddCorner(lootNotificationContainer, "M")

	local bG = Instance.new("ImageLabel")
	bG.Name = "BG"
	bG.AnchorPoint = Vector2.new(0.5, 0.5)
	bG.BackgroundTransparency = 1
	bG.Image = FFGEnum.UI.Notifications.ToastWhite
	bG.ImageColor3 = Color3.fromRGB(37, 190, 255)
	bG.Position = UDim2.fromScale(0.5, 0.5)
	bG.ScaleType = Enum.ScaleType.Slice
	bG.Size = UDim2.fromScale(1, 1)
	bG.SliceCenter = Rect.new(4, 26, 7, 29)

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.Position = UDim2.fromScale(0.5, 1)
	textLabel.Size = UDim2.fromScale(0.826442, 0.675447)
	textLabel.Text = props.Text or ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = bG

	bG.Parent = lootNotificationContainer

	if props.ItemType then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0.5, 1)
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.fromScale(0.5, 0.35)
		icon.Size = UDim2.fromScale(0.239935, 0.324553)
		icon.ZIndex = 5
		icon.Image = FFGEnum.UI.Icons[props.ItemImage] or ""
		KinUI.ApplyAspect(icon)

		icon.Parent = lootNotificationContainer
	end

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
		UP = 3,
		SWIPE = 0.5,
	}

	if frame then
		local tweenGoalUp = {
			Position = FFGEnum.THEME.alignment.position.top,
		}

		local tweenGoalSwipe = {
			Position = UDim2.fromScale(1.1, 0.5),
		}

		local tweenInfoUp = TweenInfo.new(DEFAULTS.UP)
		local tweenUp = TweenService:Create(frame, tweenInfoUp, tweenGoalUp)

		local tweenInfoSwipe = TweenInfo.new(DEFAULTS.SWIPE)
		local tweenSwipe = TweenService:Create(frame, tweenInfoSwipe, tweenGoalSwipe)

		tweenUp.Completed:Once(function()
			tweenSwipe:Play()
		end)

		tweenSwipe.Completed:Once(function()
			fadeOut(frame, 1)
		end)

		tweenUp:Play()
	end
end

return LootNotification
