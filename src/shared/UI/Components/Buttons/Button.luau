local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local AnimateButtonHover = require(ReplicatedStorage.Shared.UI.AnimateButtonHover)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Button = {}

local buttonImages = {
	squareColor = {
		Green = "rbxassetid://117523854412152",
		Blue = "rbxassetid://106924732482845", -- pressed/hovered
		BlueGray = "rbxassetid://97163201361197",
		Gray = "rbxassetid://120715593495406", -- disabled
		Orange = "rbxassetid://83441298838791",
		Purple = "rbxassetid://125793396941611",
		Red = "rbxassetid://94099958341252",
		SkyBlue = "rbxassetid://130856420084871",
		White = "rbxassetid://136257301484168",
		Yellow = "rbxassetid://122172302659103",
	},
}

function Button.Create(props: {
	Color: "Green" | "Blue" | "BlueGray" | "Gray" | "Orange" | "Purple" | "Red" | "SkyBlue" | "White" | "Yellow",
	Text: string?,
	Size: UDim2?,
	CurrencyType: "None" | "Gold",
	Image: string?,
})
	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.Image = buttonImages.squareColor[props.Color] or ""
	button.PressedImage = buttonImages.squareColor.Blue
	button.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	button.Position = FFGEnum.THEME.alignment.position.center
	button.ScaleType = Enum.ScaleType.Slice
	button.SliceCenter = Rect.new(25, 64, 39, 161)
	button.BackgroundTransparency = 1
	button.Size = props.Size or UDim2.fromScale(1, 1)
	KinUI.AddPadding(button, "S")

	local buttonText: TextLabel?
	if props.Text then
		buttonText = Instance.new("TextLabel")
		buttonText.Name = "ButtonText"
		buttonText.Font = FFGEnum.THEME.bigFont
		buttonText.Text = props.Text
		buttonText.LayoutOrder = 2
		buttonText.TextColor3 = FFGEnum.THEME.color.white
		buttonText.BackgroundTransparency = 1
		buttonText.TextScaled = true
		buttonText.Size = UDim2.fromScale(0.7, 0.5)
		buttonText.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		buttonText.Position = FFGEnum.THEME.alignment.position.textCenter
		buttonText.Parent = button
	end

	if props.CurrencyType == "Gold" then
		local currencyIcon = Instance.new("ImageLabel")
		currencyIcon.Name = "CurrencyIcon"
		currencyIcon.Image = FFGEnum.UI.Icons.Gold
		currencyIcon.LayoutOrder = 1
		currencyIcon.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		currencyIcon.Position = FFGEnum.THEME.alignment.position.center
		currencyIcon.BackgroundTransparency = 1
		currencyIcon.Size = UDim2.fromScale(0.25, 0.25)
		KinUI.ApplyAspect(currencyIcon)
		currencyIcon.Parent = button

		if buttonText then buttonText.Size = UDim2.fromScale(0.3, 1) end

		KinUI.ApplyList(button, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })
	end

	local baseSize = button.Size
	button.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(button, baseSize)
	end)

	button.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(button, baseSize)
	end)

	return button
end

return Button
