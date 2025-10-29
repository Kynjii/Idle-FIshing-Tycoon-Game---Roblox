local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)

local Tooltip = {}
Tooltip.Existing = {}

-- Helper for handling Purchase/Upgrade via tooltip
local function handleButtonClick(itemId: string, isPurchased: boolean): ()
	if isPurchased then
		local assignJobEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.AssignJob)
		if assignJobEvent then assignJobEvent:InvokeServer(itemId, "job_id_1") end -- //TODO
	else
		local purchaseEvent = Events.GetRemote(Events.RemoteNames.HelperPurchased)
		if purchaseEvent then purchaseEvent:FireServer(itemId) end
	end
end

function Tooltip.ClearExisting(userId: number): ()
	if Tooltip.Existing[userId] then
		local existing = Tooltip.Existing[userId]
		existing:Destroy()
		Tooltip.Existing[userId] = nil
	end
end

function Tooltip.Create(props: {
	BackgroundColor3: Color3?,
	Size: UDim2,
	Rounded: UDim?,
	Visible: boolean?,
	ItemImage: string,
	ItemQualityId: number,
	ItemBaseCost: string,
	ItemName: string,
	ItemDescription: string,
	ItemStats: { [number]: { [string]: any } }?,
	ItemId: string,
	IsPurchased: boolean?,
	Owner: number?,
	Parent: Instance?,
})
	-- //SECTION - Tooltip Container
	local tooltipContainer = Instance.new("Frame")
	tooltipContainer.Name = "Tooltip"
	tooltipContainer.Parent = props.Parent or nil
	tooltipContainer.Size = props.Size
	tooltipContainer.BackgroundColor3 = props.BackgroundColor3 or FFGEnum.QUALITIES[props.ItemQualityId].Color
	tooltipContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.left
	tooltipContainer.Position = UDim2.fromScale(1.05, 0.5)
	tooltipContainer.Visible = props.Visible or false

	-- //SECTION - Tooltip Outline
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = FFGEnum.THEME.shop.shopTooltip.border or Color3.new(0, 0, 0)
	containerStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	containerStroke.Thickness = FFGEnum.THEME.shop.shopTooltip.outlineThickness
	containerStroke.Parent = tooltipContainer
	-- //!SECTION

	-- //SECTION -  Tooltip Corner
	local corner = Instance.new("UICorner")
	corner.Parent = tooltipContainer

	if props.Rounded then
		corner.CornerRadius = props.Rounded
	else
		corner.CornerRadius = UDim.new(0)
	end
	-- //!SECTION

	-- //SECTION - Frame Header
	local frameHeader = Instance.new("ImageLabel")
	frameHeader.Name = "HeaderImage"
	frameHeader.Image = FFGEnum.THEME.shop.shopTooltip.frameTriangle
	frameHeader.Size = UDim2.fromScale(1, 0.2)
	frameHeader.AnchorPoint = FFGEnum.THEME.alignment.anchor.frameHeader
	frameHeader.Position = FFGEnum.THEME.alignment.position.frameHeader
	frameHeader.ResampleMode = Enum.ResamplerMode.Default
	frameHeader.BackgroundTransparency = 1
	frameHeader.Parent = tooltipContainer

	local headerCorner = Instance.new("UICorner")
	headerCorner.Name = "UICorner"
	headerCorner.CornerRadius = UDim.new(0.6, 0)
	headerCorner.Parent = frameHeader

	-- //SECTION -  Item Name
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemName"
	itemLabel.BackgroundTransparency = 1
	itemLabel.Size = UDim2.fromScale(0.85, 0.80)
	itemLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemLabel.Position = FFGEnum.THEME.alignment.position.textFrameHeaderCenter
	itemLabel.TextStrokeTransparency = 0
	itemLabel.Text = props.ItemName
	itemLabel.Font = FFGEnum.THEME.bigFont
	if props.ItemQualityId then
		itemLabel.TextColor3 = FFGEnum.QUALITIES[props.ItemQualityId].Color
	else
		itemLabel.TextColor3 = FFGEnum.THEME.color.white
	end
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
	mainContainer.Parent = tooltipContainer

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Name = "MainContainerPadding"
	uIPadding.PaddingTop = UDim.new(0.12, 0)
	uIPadding.Parent = mainContainer

	local mainContainerUIList = Instance.new("UIListLayout")
	mainContainerUIList.Name = "MainContainerUIList"
	mainContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainContainerUIList.Padding = UDim.new(0.05, 0)
	mainContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	mainContainerUIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	mainContainerUIList.Parent = mainContainer
	-- //!SECTION

	-- //SECTION - Item Info Container
	local itemInfoContainer = Instance.new("Frame")
	itemInfoContainer.Name = "ItemInfoContainer"
	itemInfoContainer.Size = UDim2.fromScale(1, 0.5)
	itemInfoContainer.Position = UDim2.fromScale(0.5, 0.05)
	itemInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemInfoContainer.BackgroundTransparency = 1
	itemInfoContainer.Parent = mainContainer

	local itemInfoUIList = Instance.new("UIListLayout")
	itemInfoUIList.Name = "itemInfoUIList"
	itemInfoUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemInfoUIList.Padding = UDim.new(0.05, 0)
	itemInfoUIList.SortOrder = Enum.SortOrder.LayoutOrder
	itemInfoUIList.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	itemInfoUIList.Parent = itemInfoContainer

	-- //SECTION -  Item Image
	local itemImageContainer = Instance.new("Frame")
	itemImageContainer.Name = "ItemImageContainer"
	itemImageContainer.BackgroundColor3 = FFGEnum.THEME.shop.shopItem.bgColor
	itemImageContainer.Size = UDim2.fromScale(0.5, 0.5)
	itemImageContainer.Parent = itemInfoContainer

	local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint.Parent = itemImageContainer

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
	imageStroke.Color = FFGEnum.THEME.shop.shopItem.element
	imageStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	imageStroke.Thickness = 1
	imageStroke.Parent = itemImageContainer
	-- //!SECTION

	-- //SECTION - Item Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "ItemBaseCost"
	priceLabel.LayoutOrder = 1
	priceLabel.Text = props.ItemBaseCost
	priceLabel.Font = FFGEnum.THEME.bigFont
	priceLabel.TextColor3 = FFGEnum.THEME.intent.notice
	priceLabel.TextStrokeTransparency = 0
	priceLabel.TextScaled = true
	priceLabel.BackgroundTransparency = 1
	priceLabel.Size = UDim2.fromScale(0.9, 0.15)
	priceLabel.Parent = itemInfoContainer
	-- //!SECTION

	-- //SECTION - Item Description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "ItemDescription"
	descriptionLabel.LayoutOrder = 2
	descriptionLabel.Text = props.ItemDescription or ""
	descriptionLabel.TextColor3 = FFGEnum.THEME.color.white
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextScaled = true
	descriptionLabel.Font = FFGEnum.THEME.normalFont
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Size = UDim2.fromScale(0.9, 0.35)
	descriptionLabel.Parent = itemInfoContainer
	-- //!SECTION

	-- //SECTION - Item Stats
	local bottomContainer = Instance.new("Frame")
	bottomContainer.Name = "BottomContainer"
	bottomContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	bottomContainer.BackgroundTransparency = 1
	bottomContainer.Size = UDim2.fromScale(1, 0.4)
	bottomContainer.Parent = mainContainer

	local bottomContainerUIList = Instance.new("UIListLayout")
	bottomContainerUIList.Name = "UIListLayout"
	bottomContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bottomContainerUIList.Padding = UDim.new(0.05, 0)
	bottomContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	bottomContainerUIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	bottomContainerUIList.Parent = bottomContainer

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	statsContainer.BackgroundColor3 = FFGEnum.THEME.shop.shopItem.bgColor
	statsContainer.LayoutOrder = 3
	statsContainer.Position = FFGEnum.THEME.alignment.position.center
	statsContainer.Size = UDim2.fromScale(1, 0.6)
	statsContainer.Parent = bottomContainer

	local statsContainerUIList = Instance.new("UIListLayout")
	statsContainerUIList.Name = "StatsContainerUIList"
	statsContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	statsContainerUIList.Parent = statsContainer

	local statsContainerCorner = Instance.new("UICorner")
	statsContainerCorner.Name = "StatsContainerCorner"
	statsContainerCorner.CornerRadius = UDim.new(0.1, 0)
	statsContainerCorner.Parent = statsContainer

	local statsContainerUIStroke = Instance.new("UIStroke")
	statsContainerUIStroke.Name = "StatsContainerUIStroke"
	statsContainerUIStroke.Color = FFGEnum.THEME.shop.shopTooltip.border
	statsContainerUIStroke.Thickness = FFGEnum.THEME.shop.shopItem.outlineThickness
	statsContainerUIStroke.Parent = statsContainer

	local statsContainerUIPadding = Instance.new("UIPadding")
	statsContainerUIPadding.Name = "StatsContainerUIPadding"
	statsContainerUIPadding.PaddingBottom = UDim.new(0.05, 0)
	statsContainerUIPadding.PaddingLeft = UDim.new(0.05, 0)
	statsContainerUIPadding.PaddingRight = UDim.new(0.05, 0)
	statsContainerUIPadding.PaddingTop = UDim.new(0.05, 0)
	statsContainerUIPadding.Parent = statsContainer

	local statOrder = {
		Storage = 1,
		WalkSpeed = 2,
		CatchRate = 3,
		CritChance = 3,
		Luck = 4,
		SwingRate = 4,
		WoodYield = 5,
		OreYield = 5,
		FishValue = 5,
		LoadTime = 6,
		CastTime = 6,
	}

	if props.ItemStats then
		for i, stat in ipairs(props.ItemStats) do
			local statFrameContainer = Instance.new("Frame")
			statFrameContainer.Name = `{stat.Label}Container`
			statFrameContainer.BackgroundTransparency = 1
			statFrameContainer.Size = UDim2.fromScale(1, 0.2)
			statFrameContainer.LayoutOrder = statOrder[stat.Label] or 0
			statFrameContainer.Parent = statsContainer

			local statFrameContainerUIList = Instance.new("UIListLayout")
			statFrameContainerUIList.Name = "UIListLayout"
			statFrameContainerUIList.FillDirection = Enum.FillDirection.Horizontal
			statFrameContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
			statFrameContainerUIList.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
			statFrameContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
			statFrameContainerUIList.Parent = statFrameContainer

			local statElementLabel = Instance.new("TextLabel")
			statElementLabel.Name = `{stat.Label}_label`
			statElementLabel.Text = stat.Label
			statElementLabel.TextXAlignment = Enum.TextXAlignment.Left
			statElementLabel.TextColor3 = FFGEnum.THEME.color.green_900
			statElementLabel.TextWrapped = true
			statElementLabel.TextScaled = true
			statElementLabel.LayoutOrder = 1
			statElementLabel.Font = FFGEnum.THEME.bigFont
			statElementLabel.BackgroundTransparency = 1
			statElementLabel.Size = UDim2.fromScale(0.5, 1)
			statElementLabel.Parent = statFrameContainer

			local statElementValue = Instance.new("TextLabel")
			statElementValue.Name = `{stat.Label}_Value`
			statElementValue.Text = stat.Value
			statElementValue.TextXAlignment = Enum.TextXAlignment.Right
			statElementValue.TextColor3 = FFGEnum.THEME.color.green_900
			statElementValue.TextWrapped = true
			statElementValue.TextScaled = true
			statElementValue.LayoutOrder = 2
			statElementValue.Font = FFGEnum.THEME.bigFont
			statElementValue.BackgroundTransparency = 1
			statElementValue.Size = UDim2.fromScale(0.5, 1)
			statElementValue.Parent = statFrameContainer
		end
	end
	-- //!SECTION

	-- //SECTION - Buy Button
	local imageButtonContainer = Instance.new("Frame")
	imageButtonContainer.Name = "ImageButtonContainer"
	imageButtonContainer.BackgroundTransparency = 1
	imageButtonContainer.LayoutOrder = 3
	imageButtonContainer.Size = UDim2.fromScale(1, 0.3)
	imageButtonContainer.Parent = bottomContainer

	local buyButton = Button.Create({
		color = "Green",
		text = props.IsPurchased and "Assign" or "Buy",
		size = UDim2.fromScale(1, 1),
	})
	buyButton.Parent = imageButtonContainer

	local baseSize = buyButton.Size
	buyButton.Activated:Connect(function()
		handleButtonClick(props.ItemId, props.IsPurchased or false)
	end)
	buyButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(buyButton, baseSize)
	end)
	buyButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(buyButton, baseSize)
	end)
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

	return tooltipContainer
end

function Tooltip.Initialize()
	-- //SECTION - Bindables
	type itemData = {
		Image: string,
		Price: number,
		Name: string,
		Id: string,
		Description: string,
		Stats: { [number]: string }?,
		Owner: number,
		IsPurchased: boolean?,
	}

	local openTooltipEvent = Events.GetBindableEvent(Events.BindableNames.ShowTooltip)
	if openTooltipEvent then openTooltipEvent.Event:Connect(function(data: itemData)
		if not data then
			error("Not data was passed when attempting to open tooltip", data)
			return
		end

		Tooltip.ClearExisting(data.Owner)

		Tooltip.Existing[data.Owner] = Tooltip.Create({
			ItemBaseCost = data.ItemBaseCost,
			ItemDescription = data.ItemDescription,
			ItemName = data.ItemName,
			ItemImage = data.ItemImage,
			ItemStats = data.ItemStats,
			ItemQualityId = data.ItemQualityId,
			ItemId = data.ItemId,
			IsPurchased = data.IsPurchased or false,
			Size = UDim2.fromScale(0.3, 0.9),
			Rounded = FFGEnum.THEME.button.cornerRadius,
			Visible = true,
			Parent = data.Parent,
		})
	end) end
	-- //!SECTION
end

return Tooltip
