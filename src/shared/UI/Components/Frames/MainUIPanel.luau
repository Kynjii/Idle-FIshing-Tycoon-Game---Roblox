local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
local MainUIPanel = {}

function MainUIPanel.Create(props: {
	Name: string,
})
	local detailsContainer = Instance.new("Frame")
	detailsContainer.Visible = true
	detailsContainer.Name = "DetailsContainer"
	detailsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	detailsContainer.BackgroundTransparency = 1
	detailsContainer.Position = UDim2.fromScale(0.5, 0.5)
	detailsContainer.Size = UDim2.fromScale(1, 1)

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = FFGEnum.THEME.color.panel
	main.Position = UDim2.fromScale(0.490615, 0.518226)
	main.Size = UDim2.fromScale(0.499, 0.611)
	main.Parent = detailsContainer

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0.07, 0)
	uICorner.Parent = main

	local uIStroke = Instance.new("UIStroke")
	uIStroke.Name = "UIStroke"
	uIStroke.Color = FFGEnum.THEME.shop.shopItem.bgColor
	uIStroke.Thickness = 5
	uIStroke.Parent = main

	local title = Instance.new("Frame")
	title.Name = "Title"
	title.BackgroundColor3 = FFGEnum.THEME.color.primary_900
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.176558, -0.03)
	title.Size = UDim2.fromScale(0.252294, 0.124159)
	title.ZIndex = 2

	local title1 = Instance.new("TextLabel")
	title1.Name = "Title"
	title1.AnchorPoint = Vector2.new(0.5, 0.5)
	title1.BackgroundTransparency = 1
	title1.Font = Enum.Font.FredokaOne
	title1.Position = UDim2.fromScale(0.5, 0.5)
	title1.Size = UDim2.fromScale(0.9, 0.9)
	title1.Text = props.Name
	title1.TextColor3 = Color3.new(1, 1, 1)
	title1.TextScaled = true
	title1.TextStrokeTransparency = 0.7
	title1.Parent = title

	local uICornerTitle = Instance.new("UICorner")
	uICornerTitle.Name = "UICorner"
	uICornerTitle.CornerRadius = UDim.new(0.2, 0)
	uICornerTitle.Parent = title1

	local uICorner1 = Instance.new("UICorner")
	uICorner1.Name = "UICorner"
	uICorner1.CornerRadius = UDim.new(0.2, 0)
	uICorner1.Parent = title

	local uIStroke1 = Instance.new("UIStroke")
	uIStroke1.Name = "UIStroke"
	uIStroke1.Color = FFGEnum.THEME.shop.shopItem.bgColor
	uIStroke1.Thickness = FFGEnum.THEME.shop.shopItem.outlineThickness
	uIStroke1.Parent = title

	title.Parent = main

	local closeButton = Instance.new("ImageButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.BackgroundColor3 = FFGEnum.THEME.color.orange_900
	closeButton.Position = UDim2.fromScale(1.00485, -0.00189609)
	closeButton.Size = UDim2.fromScale(0.06, 0.09)

	local baseSize = closeButton.Size
	closeButton.Activated:Connect(function()
		detailsContainer.Visible = false
		if Lighting then
			local blur = Lighting:FindFirstChild("Blur")
			if blur then blur:Destroy() end
		end
	end)

	closeButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(closeButton, baseSize)
	end)

	closeButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(closeButton, baseSize)
	end)

	local uICorner2 = Instance.new("UICorner")
	uICorner2.Name = "UICorner"
	uICorner2.CornerRadius = UDim.new(0.2, 0)
	uICorner2.Parent = closeButton

	local uIStroke2 = Instance.new("UIStroke")
	uIStroke2.Name = "UIStroke"
	uIStroke2.Color = FFGEnum.THEME.shop.shopItem.bgColor
	uIStroke2.Thickness = FFGEnum.THEME.shop.shopItem.outlineThickness
	uIStroke2.Parent = closeButton

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0.480769, 0.634615)
	textLabel.Text = "X"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0

	local uIStroke3 = Instance.new("UIStroke")
	uIStroke3.Name = "UIStroke"
	uIStroke3.Thickness = 2
	uIStroke3.Parent = textLabel

	textLabel.Parent = closeButton

	local uIAspectRatioConstraint1 = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint1.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint1.Parent = closeButton

	closeButton.Parent = main

	return detailsContainer
end

return MainUIPanel
