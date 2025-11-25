local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local LootNotification = {}

export type Props = {
	ItemImage: "Gold" | "Fishing",
	Text: string?,
}

function LootNotification.Create(props: Props): Frame & CanvasGroup
	local lootNotificationContainer = Instance.new("Frame")
	lootNotificationContainer.Name = "NotificationContainer"
	lootNotificationContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	lootNotificationContainer.BackgroundTransparency = 1
	lootNotificationContainer.Position = UDim2.fromScale(0.5, 0.5)
	lootNotificationContainer.Size = UDim2.fromScale(1, 0.28)

	local notification = Instance.new("CanvasGroup")
	notification.Name = "Template"
	notification.AnchorPoint = Vector2.new(0, 0.5)
	notification.BackgroundTransparency = 1
	notification.Position = UDim2.fromScale(1.1, 0.5)
	notification.Size = UDim2.fromScale(1, 1)
	KinUI.AddCorner(notification, "M")
	notification.Parent = lootNotificationContainer

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
	textLabel.Size = UDim2.fromScale(0.8, 0.6)
	textLabel.Text = props.Text or ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = bG

	bG.Parent = notification

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

		icon.Parent = notification
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
