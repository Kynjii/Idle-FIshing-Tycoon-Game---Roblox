local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)

local Tooltip = {}
Tooltip.Existing = {}

-- Helper for handling Purchase/Upgrade via tooltip
local function handleButtonClick(itemId: string, isPurchased: boolean): ()
	if isPurchased then
		local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
		if assignJobEvent then assignJobEvent:FireServer(itemId, 1) end -- //TODO
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
	Size: UDim2,
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
	tooltipContainer.BackgroundTransparency = 1
	tooltipContainer.Size = props.Size
	tooltipContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.left
	tooltipContainer.Position = UDim2.fromScale(1.05, 0.5)
	tooltipContainer.Visible = props.Visible or false

	-- //SECTION - Tooltip BG
	local panelBG = Instance.new("ImageLabel")
	panelBG.Name = "PanelBG"
	panelBG.AnchorPoint = Vector2.new(0.5, 0.5)
	panelBG.BackgroundTransparency = 1
	panelBG.Image = FFGEnum.UI.Frames.MainUIPanel
	panelBG.Position = UDim2.fromScale(0.5, 0.5)
	panelBG.ScaleType = Enum.ScaleType.Slice
	panelBG.Size = UDim2.fromScale(1, 1)
	panelBG.SliceCenter = Rect.new(20, 33, 29, 73)
	panelBG.ZIndex = 0
	panelBG.Parent = tooltipContainer
	-- //!SECTION

	-- //SECTION - Frame Header
	local frameHeader = Instance.new("ImageLabel")
	frameHeader.Name = "HeaderImage"
	frameHeader.Image = FFGEnum.THEME.shop.shopTooltip.frameTriangle
	frameHeader.Size = UDim2.fromScale(1.015, 0.2)
	frameHeader.AnchorPoint = FFGEnum.THEME.alignment.anchor.frameHeader
	frameHeader.Position = FFGEnum.THEME.alignment.position.frameHeader
	frameHeader.ResampleMode = Enum.ResamplerMode.Default
	frameHeader.BackgroundTransparency = 1
	frameHeader.ZIndex = 50
	frameHeader.Parent = tooltipContainer

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
	UIConfig.applyTextConstraints(itemLabel, "h1")
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
	uIPadding.PaddingTop = UDim.new(0.16, 0)
	uIPadding.Parent = mainContainer

	local mainContainerUIList = Instance.new("UIListLayout")
	mainContainerUIList.Name = "MainContainerUIList"
	mainContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	mainContainerUIList.VerticalAlignment = Enum.VerticalAlignment.Top
	mainContainerUIList.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	mainContainerUIList.Parent = mainContainer
	UIConfig.setGap(mainContainerUIList, "XS")
	-- //!SECTION

	-- //SECTION - Item Info Container
	local itemInfoContainer = Instance.new("Frame")
	itemInfoContainer.Name = "ItemInfoContainer"
	itemInfoContainer.Size = UDim2.fromScale(1, 0.4)
	itemInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemInfoContainer.BackgroundTransparency = 1
	itemInfoContainer.Parent = mainContainer

	local itemInfoUIList = Instance.new("UIListLayout")
	itemInfoUIList.Name = "itemInfoUIList"
	itemInfoUIList.FillDirection = Enum.FillDirection.Horizontal
	itemInfoUIList.HorizontalFlex = Enum.UIFlexAlignment.SpaceAround
	itemInfoUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemInfoUIList.VerticalAlignment = Enum.VerticalAlignment.Center
	itemInfoUIList.Padding = UDim.new(0.05, 0)
	itemInfoUIList.SortOrder = Enum.SortOrder.LayoutOrder
	itemInfoUIList.VerticalFlex = Enum.UIFlexAlignment.None
	itemInfoUIList.Parent = itemInfoContainer

	local addInfoContainer = Instance.new("Frame")
	addInfoContainer.Name = "AddInfoContainer"
	addInfoContainer.Size = UDim2.fromScale(1, 1)
	addInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	addInfoContainer.Position = FFGEnum.THEME.alignment.position.center
	addInfoContainer.LayoutOrder = 2
	addInfoContainer.BackgroundTransparency = 1
	addInfoContainer.Parent = itemInfoContainer

	local addInfoContainerList = Instance.new("UIListLayout")
	addInfoContainerList.Name = "AddInfoContainerList"
	addInfoContainerList.FillDirection = Enum.FillDirection.Vertical
	addInfoContainerList.VerticalAlignment = Enum.VerticalAlignment.Center
	addInfoContainerList.SortOrder = Enum.SortOrder.LayoutOrder
	addInfoContainerList.Parent = addInfoContainer

	-- //SECTION - Item Price
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "ItemPriceContainer"
	priceContainer.Size = UDim2.fromScale(1, 0.3)
	priceContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	priceContainer.Position = FFGEnum.THEME.alignment.position.center
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = addInfoContainer

	local priceContainerList = Instance.new("UIListLayout")
	priceContainerList.Name = "UIListLayout"
	priceContainerList.FillDirection = Enum.FillDirection.Horizontal
	priceContainerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	priceContainerList.SortOrder = Enum.SortOrder.LayoutOrder
	priceContainerList.VerticalAlignment = Enum.VerticalAlignment.Center
	UIConfig.setGap(priceContainerList, "S")
	priceContainerList.Parent = priceContainer

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	icon.BackgroundTransparency = 1
	icon.Image = FFGEnum.UI.Icons.Gold
	icon.LayoutOrder = 1
	icon.Size = UDim2.fromScale(0.15, 0.15)
	UIConfig.applyAspect(icon)
	icon.Parent = priceContainer

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "ItemBaseCost"
	priceLabel.LayoutOrder = 2
	priceLabel.Text = props.ItemBaseCost
	priceLabel.AutomaticSize = Enum.AutomaticSize.X
	priceLabel.Font = FFGEnum.THEME.bigFont
	priceLabel.TextColor3 = FFGEnum.THEME.color.textGold
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.TextStrokeTransparency = 0
	priceLabel.BackgroundTransparency = 1
	priceLabel.Parent = priceContainer
	UIConfig.applyTextConstraints(priceLabel, "h2")
	-- //!SECTION

	-- //SECTION - Item Description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "ItemDescription"
	descriptionLabel.LayoutOrder = 2
	descriptionLabel.Text = props.ItemDescription or ""
	descriptionLabel.TextColor3 = FFGEnum.THEME.color.textMuted
	descriptionLabel.TextWrapped = true
	descriptionLabel.Font = FFGEnum.THEME.bigFont
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Size = UDim2.fromScale(1, 0.7)
	descriptionLabel.Parent = addInfoContainer
	UIConfig.applyTextConstraints(descriptionLabel, "caption")
	-- //!SECTION

	-- //SECTION - Item Stats
	local bottomContainer = Instance.new("Frame")
	bottomContainer.Name = "BottomContainer"
	bottomContainer.LayoutOrder = 3
	bottomContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	bottomContainer.BackgroundTransparency = 1
	bottomContainer.Size = UDim2.fromScale(1, 0.4)
	bottomContainer.Parent = mainContainer

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.BackgroundTransparency = 1
	statsContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	statsContainer.LayoutOrder = 3
	statsContainer.Position = FFGEnum.THEME.alignment.position.center
	statsContainer.Size = UDim2.fromScale(1, 0.7)
	statsContainer.Parent = bottomContainer
	UIConfig.applyPanelStyle(statsContainer, FFGEnum.THEME.color.white)

	local bottomContainerUIList = Instance.new("UIListLayout")
	bottomContainerUIList.Name = "UIListLayout"
	bottomContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bottomContainerUIList.Padding = UDim.new(0.05, 0)
	bottomContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	bottomContainerUIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	bottomContainerUIList.Parent = bottomContainer

	local innerStatsContainer = Instance.new("Frame")
	innerStatsContainer.Name = "StatsContainer"
	innerStatsContainer.BackgroundTransparency = 1
	innerStatsContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	innerStatsContainer.LayoutOrder = 3
	innerStatsContainer.Position = FFGEnum.THEME.alignment.position.center
	innerStatsContainer.Size = UDim2.fromScale(1, 0.6)
	innerStatsContainer.Parent = statsContainer

	local statsContainerUIList = Instance.new("UIListLayout")
	statsContainerUIList.Name = "StatsContainerUIList"
	statsContainerUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsContainerUIList.SortOrder = Enum.SortOrder.LayoutOrder
	statsContainerUIList.Parent = innerStatsContainer
	UIConfig.setGap(statsContainerUIList, "XL")

	local statsContainerUIPadding = Instance.new("UIPadding")
	statsContainerUIPadding.Name = "StatsContainerUIPadding"
	statsContainerUIPadding.Parent = innerStatsContainer
	UIConfig.setPadding(statsContainerUIPadding, "XL")

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
			statFrameContainer.Parent = innerStatsContainer

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
			statElementLabel.TextColor3 = FFGEnum.THEME.color.black
			statElementLabel.TextWrapped = true
			statElementLabel.LayoutOrder = 1
			statElementLabel.Font = FFGEnum.THEME.bigFont
			statElementLabel.BackgroundTransparency = 1
			statElementLabel.Size = UDim2.fromScale(0.5, 1)
			statElementLabel.Parent = statFrameContainer
			UIConfig.applyTextConstraints(statElementLabel, "body")

			local statElementValue = Instance.new("TextLabel")
			statElementValue.Name = `{stat.Label}_Value`
			statElementValue.Text = stat.Value
			statElementValue.TextXAlignment = Enum.TextXAlignment.Right
			statElementValue.TextColor3 = FFGEnum.THEME.color.black
			statElementValue.TextWrapped = true
			statElementValue.LayoutOrder = 2
			statElementValue.Font = FFGEnum.THEME.bigFont
			statElementValue.BackgroundTransparency = 1
			statElementValue.Size = UDim2.fromScale(0.5, 1)
			statElementValue.Parent = statFrameContainer
			UIConfig.applyTextConstraints(statElementValue, "body")
		end
	end
	-- //!SECTION

	-- //SECTION - Buttons
	local buttonContainer = Instance.new("Frame")
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.LayoutOrder = 3
	buttonContainer.Size = UDim2.fromScale(1, 0.3)
	buttonContainer.Parent = bottomContainer

	local buttonGrid = Instance.new("UIGridLayout")
	buttonGrid.FillDirection = Enum.FillDirection.Horizontal
	buttonGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonGrid.CellSize = UDim2.fromScale(1, 1)
	UIConfig.setGap(buttonGrid, "S")
	buttonGrid.Parent = buttonContainer

	-- Buy Button
	local buyButtonContainer = Instance.new("Frame")
	buyButtonContainer.Name = "BuyButtonContainer"
	buyButtonContainer.BackgroundTransparency = 1
	buyButtonContainer.LayoutOrder = 3
	buyButtonContainer.Size = UDim2.fromScale(1, 1)
	buyButtonContainer.Parent = buttonContainer

	local buyButton = Button.Create({
		color = props.IsPurchased and "Purple" or "Green",
		text = props.IsPurchased and "Assign" or "Purchase",
		size = UDim2.fromScale(1, 1),
	})
	buyButton.Parent = buyButtonContainer

	buyButton.Activated:Connect(function()
		handleButtonClick(props.ItemId, props.IsPurchased or false)
	end)
	local baseSize = buyButton.Size
	buyButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(buyButton, baseSize)
	end)
	buyButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(buyButton, baseSize)
	end)

	-- If purchased, add an upgrade option
	if props.IsPurchased then
		buttonGrid.CellSize = UDim2.fromScale(0.485, 1)

		local upgradeButtonContainer = Instance.new("Frame")
		upgradeButtonContainer.Name = "UpgradeButtonContainer"
		upgradeButtonContainer.BackgroundTransparency = 1
		upgradeButtonContainer.LayoutOrder = 4
		upgradeButtonContainer.Size = UDim2.fromScale(1, 1)
		upgradeButtonContainer.Parent = buttonContainer

		local upgradeButton = Button.Create({
			color = "Green",
			text = "Upgrade",
			size = UDim2.fromScale(1, 1),
		})
		upgradeButton.Parent = upgradeButtonContainer

		upgradeButton.Activated:Connect(function()
			-- handleButtonClick(props.ItemId, props.IsPurchased or false)
		end)
		local upgradeBaseSize = upgradeButton.Size
		upgradeButton.MouseEnter:Connect(function()
			AnimateButtonHover.Enter(upgradeButton, upgradeBaseSize)
		end)
		upgradeButton.MouseLeave:Connect(function()
			AnimateButtonHover.Leave(upgradeButton, upgradeBaseSize)
		end)
	end
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

	UIConfig.observeViewport(function()
		UIConfig.applyTextConstraints(itemLabel, "h1")
		UIConfig.applyTextConstraints(priceLabel, "h2")
		UIConfig.applyTextConstraints(descriptionLabel, "body")
	end)

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
			Size = UDim2.fromScale(0.3, 1),
			Visible = true,
			Parent = data.Parent,
		})
	end) end
	-- //!SECTION
end

return Tooltip
