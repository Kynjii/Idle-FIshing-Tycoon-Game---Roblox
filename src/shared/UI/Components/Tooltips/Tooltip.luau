local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)

local Tooltip = {}

function Tooltip.Create(props: {
	BackgroundColor3: Color3?,
	Size: UDim2,
	Rounded: UDim?,
	Visible: boolean?,
	ItemImage: string,
	ItemCost: string,
	ItemName: string,
	ItemDescription: string,
	ItemStats: { [number]: { [string]: any } }?,
	Parent: Instance?,
})
	-- //SECTION - Shop Tooltip Container
	local shopTooltipContainer = Instance.new("Frame")
	shopTooltipContainer.Name = "ShopTooltip"
	shopTooltipContainer.Parent = props.Parent or nil
	shopTooltipContainer.Size = props.Size
	shopTooltipContainer.BackgroundColor3 = props.BackgroundColor3 or FFGEnum.THEME.color.panel
	shopTooltipContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.left
	shopTooltipContainer.Position = UDim2.fromScale(1.05, 0.5)
	shopTooltipContainer.Visible = props.Visible or false

	-- //SECTION - Shop Item Outline
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = FFGEnum.THEME.shop.shopItem.outline or Color3.new(0, 0, 0)
	containerStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	containerStroke.Thickness = FFGEnum.THEME.shop.shopItem.outlineThickness
	containerStroke.Parent = shopTooltipContainer
	-- //!SECTION

	-- //SECTION -  Shop Item Corner
	local corner = Instance.new("UICorner")
	corner.Parent = shopTooltipContainer

	if props.Rounded then
		corner.CornerRadius = props.Rounded
	else
		corner.CornerRadius = UDim.new(0)
	end
	-- //!SECTION

	-- //SECTION - Frame Header
	local frameHeader = Instance.new("ImageLabel")
	frameHeader.Name = "BG"
	frameHeader.Image = FFGEnum.THEME.shop.shopTooltip.frameTriangle
	frameHeader.Size = UDim2.fromScale(0.9, 0.1)
	frameHeader.AnchorPoint = FFGEnum.THEME.alignment.anchor.top
	frameHeader.Position = FFGEnum.THEME.alignment.position.frameHeader
	frameHeader.ResampleMode = Enum.ResamplerMode.Default
	frameHeader.BackgroundTransparency = 1
	frameHeader.Parent = shopTooltipContainer

	-- //SECTION -  Item Name
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemName"
	itemLabel.BackgroundTransparency = 1
	itemLabel.Size = UDim2.fromScale(0.85, 0.80)
	itemLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemLabel.Position = FFGEnum.THEME.alignment.position.textFrameHeaderCenter
	itemLabel.TextStrokeTransparency = 0
	itemLabel.Text = props.ItemName
	itemLabel.Font = FFGEnum.THEME.font
	itemLabel.TextColor3 = FFGEnum.THEME.color.white
	itemLabel.TextScaled = true
	itemLabel.Parent = frameHeader
	-- //!SECTION
	-- //!SECTION

	-- //SECTION Holds all the main elements
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "Main"
	mainContainer.Size = UDim2.fromScale(0.9, 0.9)
	mainContainer.Position = FFGEnum.THEME.alignment.position.center
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = shopTooltipContainer
	-- //!SECTION

	-- //SECTION - Item Info Container
	local itemInfoContainer = Instance.new("Frame")
	itemInfoContainer.Name = "ItemInfoContainer"
	itemInfoContainer.Size = UDim2.fromScale(1, 0.4)
	itemInfoContainer.Position = UDim2.fromScale(0.5, 0.05)
	itemInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.top
	itemInfoContainer.BackgroundTransparency = 1
	itemInfoContainer.Parent = mainContainer

	-- //SECTION -  Item Image
	local itemImageContainer = Instance.new("Frame")
	itemImageContainer.Name = "ItemImageContainer"
	itemImageContainer.BackgroundColor3 = FFGEnum.THEME.shop.shopItem.outline
	itemImageContainer.Size = UDim2.fromScale(0.5, 0.5)
	itemImageContainer.Parent = itemInfoContainer

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = props.ItemImage
	imageLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	imageLabel.Position = FFGEnum.THEME.alignment.position.center
	imageLabel.BackgroundTransparency = 1
	imageLabel.Size = UDim2.fromScale(0.9, 0.9)
	imageLabel.Parent = itemImageContainer

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = FFGEnum.THEME.button.cornerRadius
	imageCorner.Parent = itemImageContainer

	local imageStroke = Instance.new("UIStroke")
	imageStroke.Color = FFGEnum.THEME.color.teal_900
	imageStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	imageStroke.Thickness = 1
	imageStroke.Parent = itemImageContainer
	-- //!SECTION

	-- //SECTION - Item Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Text = props.ItemCost
	priceLabel.Font = FFGEnum.THEME.font
	priceLabel.TextColor3 = FFGEnum.THEME.intent.notice
	priceLabel.TextStrokeTransparency = 0
	priceLabel.TextScaled = true
	priceLabel.BackgroundTransparency = 1
	priceLabel.Size = UDim2.fromScale(0.9, 0.15)
	priceLabel.Parent = itemInfoContainer
	-- //!SECTION

	-- //SECTION - Item Description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Text = props.ItemDescription or ""
	descriptionLabel.TextColor3 = FFGEnum.THEME.color.teal_900
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextScaled = true
	descriptionLabel.Font = FFGEnum.THEME.font
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Size = UDim2.fromScale(0.9, 0.35)
	descriptionLabel.Parent = itemInfoContainer
	-- //!SECTION

	-- //SECTION - Item Stats
	if props.ItemStats then
		for i, stat in ipairs(props.ItemStats) do
			local statElement = Instance.new("TextLabel")
			statElement.Name = `{stat.Label}_label`
			statElement.Text = `{stat.Label}: {stat.Value}`
			statElement.TextColor3 = FFGEnum.THEME.color.teal_900
			statElement.TextWrapped = true
			statElement.TextScaled = true
			statElement.Font = FFGEnum.THEME.font
			statElement.BackgroundTransparency = 1
			statElement.Size = UDim2.fromScale(0.9, 0.35)
			statElement.Parent = itemInfoContainer
		end
	end
	-- //!SECTION

	-- //SECTION - Buy Button
	local buyButton = Instance.new("ImageButton")
	buyButton.BackgroundTransparency = 1
	buyButton.PressedImage = FFGEnum.THEME.button.white
	buyButton.Image = FFGEnum.THEME.button.white
	buyButton.HoverImage = FFGEnum.THEME.button.white
	buyButton.ResampleMode = Enum.ResamplerMode.Pixelated
	buyButton.ImageColor3 = FFGEnum.THEME.shop.shopItem.buttonColor
	buyButton.ScaleType = Enum.ScaleType.Slice
	buyButton.SliceCenter = Rect.new(32, 83, 32, 83)
	buyButton.AnchorPoint = FFGEnum.THEME.alignment.anchor.bottom
	buyButton.Position = FFGEnum.THEME.alignment.position.bottom
	buyButton.Parent = mainContainer
	buyButton.Size = UDim2.fromScale(1, 0.1)

	local baseSize = buyButton.Size
	buyButton.Activated:Connect(function()
		--
	end)
	buyButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(buyButton, baseSize)
	end)
	buyButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(buyButton, baseSize)
	end)

	local buttonTxt = Instance.new("TextLabel")
	buttonTxt.Position = UDim2.fromScale(0.5, 0.45)
	buttonTxt.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonTxt.TextColor3 = FFGEnum.THEME.color.white
	buttonTxt.BackgroundTransparency = 1
	buttonTxt.TextScaled = true
	buttonTxt.Text = "Purchase"
	buttonTxt.Font = FFGEnum.THEME.font
	buttonTxt.Size = buyButton.Size + UDim2.fromScale(0, 0.5)
	buttonTxt.Parent = buyButton
	-- //!SECTION

	-- //!SECTION

	-- //SECTION - UI List Layouts
	-- itemInfoContainer
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiListLayout.FillDirection = Enum.FillDirection.Vertical
	uiListLayout.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	uiListLayout.Parent = itemInfoContainer
	-- -- //!SECTION

	return shopTooltipContainer
end

function Tooltip.Initialize(parentInstance: Instance)
	local tooltip = Tooltip.Create({
		ItemImage = "",
		ItemCost = "",
		ItemDescription = "",
		ItemName = "",
		ItemStats = {},
		Parent = parentInstance,
		Size = UDim2.fromScale(0.3, 1),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		Visible = false,
	})

	-- //SECTION - Bindables
	type itemData = {
		Image: string,
		Price: number,
		Name: string,
		Id: string,
		Description: string,
		Stats: { [number]: string }?,
	}

	local bindableEvent = Events.GetBindableEvent(Events.BindableNames.ShowShopTooltip)
	if bindableEvent then bindableEvent.Event:Connect(function(data: itemData)
		if not data then
			error("Not data was passed when attempting to open shop tooltip", data)
			return
		end

		if tooltip then tooltip:Destroy() end
		tooltip = Tooltip.Create({
			ItemCost = data.Price,
			ItemDescription = data.Description,
			ItemName = data.Name,
			ItemImage = data.Image,
			ItemStats = data.Stats,
			Size = UDim2.fromScale(0.3, 1),
			Rounded = FFGEnum.THEME.button.cornerRadius,
			Visible = true,
			Parent = parentInstance,
		})
	end) end
	-- //!SECTION
end

return Tooltip
