local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
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
	color: "Green" | "Blue" | "BlueGray" | "Gray" | "Orange" | "Purple" | "Red" | "SkyBlue" | "White" | "Yellow",
	text: string?,
	size: UDim2?,
})
	local button = Instance.new("ImageButton")
	button.Image = buttonImages.squareColor[props.color] or ""
	button.PressedImage = buttonImages.squareColor.Blue
	button.HoverImage = buttonImages.squareColor.Blue
	button.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	button.Position = FFGEnum.THEME.alignment.position.center
	button.ScaleType = Enum.ScaleType.Slice
	button.SliceCenter = Rect.new(25, 64, 39, 161)
	button.BackgroundTransparency = 1
	button.Size = props.size or UDim2.fromScale(1, 1)

	if props.text then
		local buttonText = Instance.new("TextLabel")
		buttonText.Font = FFGEnum.THEME.bigFont
		buttonText.Text = props.text
		buttonText.TextColor3 = FFGEnum.THEME.color.white
		buttonText.BackgroundTransparency = 1
		buttonText.Size = UDim2.fromScale(1, 1)
		buttonText.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		buttonText.Position = FFGEnum.THEME.alignment.position.center
		buttonText.Parent = button
		UIConfig.applyTextConstraints(buttonText, "h2")
	end

	return button
end

return Button
