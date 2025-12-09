local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local LootNotification = {}

export type Props = {
	ItemImage: "Gold" | "Fishing",
	Text: string?,
}

function LootNotification.Create(props: Props): Frame
	local lootNotificationContainer = Instance.new("Frame")
	lootNotificationContainer.Name = "NotificationContainer"
	lootNotificationContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	lootNotificationContainer.Position = UDim2.fromScale(0.5, 0.5)
	lootNotificationContainer.Size = UDim2.fromScale(1, 0.12)

	local notification = Instance.new("Frame")
	notification.Name = "Template"
	notification.AnchorPoint = Vector2.new(0, 0.5)
	notification.BackgroundTransparency = 1
	notification.Position = UDim2.fromScale(1.1, 0.5)
	notification.Size = UDim2.fromScale(1, 1)
	KinUI.AddCorner(notification, "M")
	notification.Parent = lootNotificationContainer

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
	uIGradient.Parent = lootNotificationContainer

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0.8, 0.6)
	textLabel.Text = props.Text or ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	KinUI.AddPadding(textLabel, "M")
	textLabel.Parent = notification

	if props.ItemImage then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Position = UDim2.fromScale(0, 0.5)
		icon.Size = UDim2.fromScale(0.5, 0.5)
		icon.ZIndex = 5
		icon.Image = FFGEnum.UI.Icons[props.ItemImage] or ""
		icon.Parent = textLabel
		KinUI.AddPadding(icon, "S")
		KinUI.ApplyAspect(icon, 1, Enum.DominantAxis.Width, Enum.AspectType.ScaleWithParentSize)
	end

	return lootNotificationContainer, notification
end

function LootNotification.Animate(frame: Frame)
	local DEFAULTS = {
		LEFT = 3,
		RIGHT = 0.5,
	}

	if frame then
		local tweenGoalLeft = {
			Position = UDim2.fromScale(0, 0.5),
		}

		local tweenGoalRight = {
			Position = UDim2.fromScale(2.1, 0.5),
		}

		local tweenInfoUp = TweenInfo.new(DEFAULTS.LEFT)
		local tweenLeft = TweenService:Create(frame, tweenInfoUp, tweenGoalLeft)

		local tweenInfoSwipe = TweenInfo.new(DEFAULTS.RIGHT, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tweenRight = TweenService:Create(frame, tweenInfoSwipe, tweenGoalRight)

		tweenLeft.Completed:Once(function()
			task.delay(1, function()
				tweenRight:Play()
			end)
		end)

		tweenRight.Completed:Once(function()
			frame.Parent:Destroy()
		end)

		tweenLeft:Play()
	end
end

return LootNotification
