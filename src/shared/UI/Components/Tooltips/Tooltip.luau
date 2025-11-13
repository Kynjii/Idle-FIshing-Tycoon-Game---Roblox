local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local StatsIndexer = require(ReplicatedStorage.Shared.Utils.StatsIndexer)

local Tooltip = {}
Tooltip.Existing = {}

-- Helper for handling Purchase/Upgrade via tooltip
local function handleButtonClick(itemId: string, isPurchased: boolean): ()
	if isPurchased then
		local upgradeHelper = Events.GetRemote(Events.RemoteNames.UpgradeHelper)
		if upgradeHelper then upgradeHelper:FireServer(itemId) end
	else
		local purchaseEvent = Events.GetRemote(Events.RemoteNames.HelperPurchased)
		if purchaseEvent then purchaseEvent:FireServer(itemId) end
	end
end

local function clearStats(innerStatsContainer: Frame)
	if not innerStatsContainer then return end
	local statElements = innerStatsContainer:GetChildren()

	if statElements then
		for _, element in pairs(statElements) do
			if element:IsA("UIListLayout") or element:IsA("UIPadding") then continue end
			element:Destroy()
		end
	end
end

local function createStats(item, innerStatsContainer)
	clearStats(innerStatsContainer)

	local preparedData = StatsIndexer.Prepare(item)

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

	if preparedData then
		for i, stat in ipairs(preparedData) do
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
			statElementLabel.TextScaled = true
			statElementLabel.Font = FFGEnum.THEME.bigFont
			statElementLabel.BackgroundTransparency = 1
			statElementLabel.Size = UDim2.fromScale(0.5, 1)
			KinUI.ApplyTextConstraints(statElementLabel, "body")
			statElementLabel.Parent = statFrameContainer

			local statType = Format.GetStatType(stat.Label)
			local isDecimal = statType == "decimal"

			local statElementValue = Instance.new("TextLabel")
			statElementValue.Name = `{stat.Label}_Value`
			statElementValue.Text = isDecimal and Format.Percent(stat.Value) or stat.Value
			statElementValue.TextXAlignment = Enum.TextXAlignment.Right
			statElementValue.TextColor3 = FFGEnum.THEME.color.black
			statElementValue.TextWrapped = true
			statElementValue.LayoutOrder = 2
			statElementValue.TextScaled = true
			statElementValue.Font = FFGEnum.THEME.bigFont
			statElementValue.BackgroundTransparency = 1
			statElementValue.Size = UDim2.fromScale(0.5, 1)
			KinUI.ApplyTextConstraints(statElementValue, "body")
			statElementValue.Parent = statFrameContainer
		end
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
	Item: HelperType.HelperData,
	Parent: Instance?,
})
	local item = props.Item

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
	itemLabel.Text = item.Name
	itemLabel.Font = FFGEnum.THEME.bigFont
	if item.QualityId or item.Tier then
		itemLabel.TextColor3 = FFGEnum.QUALITIES[item.QualityId or item.Tier].Color
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
	mainContainer.Size = UDim2.fromScale(0.9, 0.8)
	mainContainer.Position = FFGEnum.THEME.alignment.position.bottom
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.bottom
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = tooltipContainer
	KinUI.ApplyList(mainContainer, Enum.FillDirection.Vertical, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })
	-- //!SECTION

	-- //SECTION - Item Info Container
	local itemInfoContainer = Instance.new("Frame")
	itemInfoContainer.Name = "ItemInfoContainer"
	itemInfoContainer.Size = UDim2.fromScale(1, 0.4)
	itemInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemInfoContainer.BackgroundTransparency = 1
	itemInfoContainer.Parent = mainContainer
	KinUI.ApplyList(itemInfoContainer, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceAround, HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	local addInfoContainer = Instance.new("Frame")
	addInfoContainer.Name = "AddInfoContainer"
	addInfoContainer.Size = UDim2.fromScale(1, 1)
	addInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	addInfoContainer.Position = FFGEnum.THEME.alignment.position.center
	addInfoContainer.LayoutOrder = 2
	addInfoContainer.BackgroundTransparency = 1
	addInfoContainer.Parent = itemInfoContainer
	KinUI.ApplyList(addInfoContainer, Enum.FillDirection.Vertical, { VAlign = Enum.VerticalAlignment.Bottom })

	-- //SECTION - Item Description
	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "ItemDescription"
	descriptionLabel.LayoutOrder = 3
	descriptionLabel.Text = item.Description or ""
	descriptionLabel.TextColor3 = FFGEnum.THEME.color.textMuted
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextScaled = true
	descriptionLabel.Font = FFGEnum.THEME.bigFont
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Size = UDim2.fromScale(1, 0.7)
	KinUI.ApplyTextConstraints(descriptionLabel, "body")
	descriptionLabel.Parent = addInfoContainer
	-- //!SECTION

	-- //SECTION - Quality & Level Label
	local entityLevelAndQualityContainer = Instance.new("Frame")
	entityLevelAndQualityContainer.Name = "EntityLevelAndQualityContainer"
	entityLevelAndQualityContainer.LayoutOrder = 2
	entityLevelAndQualityContainer.Position = FFGEnum.THEME.alignment.position.center
	entityLevelAndQualityContainer.Size = UDim2.fromScale(1, 0.2)
	entityLevelAndQualityContainer.BackgroundTransparency = 1
	entityLevelAndQualityContainer.Parent = addInfoContainer
	KinUI.ApplyList(
		entityLevelAndQualityContainer,
		Enum.FillDirection.Horizontal,
		{ HAlign = Enum.HorizontalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center }
	)

	local levelLabel: TextLabel
	local stageLabel: TextLabel
	if item.IsPurchased then
		levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.LayoutOrder = 1
		levelLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		levelLabel.Position = FFGEnum.THEME.alignment.position.center
		levelLabel.Size = UDim2.fromScale(0.3, 1)
		levelLabel.Text = item.IsPurchased and `Level {item.Level}` or ""
		levelLabel.TextColor3 = FFGEnum.THEME.color.Green
		levelLabel.TextStrokeTransparency = 0.7
		levelLabel.TextScaled = true
		levelLabel.Font = FFGEnum.THEME.bigFont
		levelLabel.BackgroundTransparency = 1
		levelLabel.Parent = entityLevelAndQualityContainer

		stageLabel = Instance.new("TextLabel")
		stageLabel.Name = "StageLabel"
		stageLabel.LayoutOrder = 2
		stageLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		stageLabel.Position = FFGEnum.THEME.alignment.position.center
		stageLabel.Size = UDim2.fromScale(0.3, 1)
		stageLabel.Text = FFGEnum.STAGES[item.UpgradeStage].Label
		stageLabel.TextColor3 = FFGEnum.STAGES[item.UpgradeStage].Color or Color3.new(1, 1, 1)
		stageLabel.TextStrokeTransparency = 0.7
		stageLabel.TextScaled = true
		stageLabel.Font = FFGEnum.THEME.bigFont
		stageLabel.BackgroundTransparency = 1
		stageLabel.Parent = entityLevelAndQualityContainer
	end

	local qualityLabel = Instance.new("TextLabel")
	qualityLabel.Name = "QualityLabel"
	qualityLabel.LayoutOrder = 3
	qualityLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	qualityLabel.Position = FFGEnum.THEME.alignment.position.center
	qualityLabel.Size = UDim2.fromScale(0.3, 1)
	qualityLabel.Text = FFGEnum.QUALITIES[item.QualityId or item.Tier].Label or ""
	qualityLabel.TextColor3 = FFGEnum.QUALITIES[item.QualityId or item.Tier].Color or Color3.new(1, 1, 1)
	qualityLabel.TextStrokeTransparency = 0.7
	qualityLabel.TextScaled = true
	qualityLabel.Font = FFGEnum.THEME.bigFont
	qualityLabel.BackgroundTransparency = 1
	qualityLabel.Parent = entityLevelAndQualityContainer
	-- //!SECTION

	-- //SECTION - Item Stats
	local bottomContainer = Instance.new("Frame")
	bottomContainer.Name = "BottomContainer"
	bottomContainer.LayoutOrder = 3
	bottomContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	bottomContainer.BackgroundTransparency = 1
	bottomContainer.Size = UDim2.fromScale(1, 0.5)
	bottomContainer.Parent = mainContainer
	KinUI.ApplyList(bottomContainer, Enum.FillDirection.Vertical, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center, VFlex = Enum.UIFlexAlignment.SpaceBetween })

	local statsPanel = Instance.new("Frame")
	statsPanel.Name = "StatsPanel"
	statsPanel.BackgroundTransparency = 1
	statsPanel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	statsPanel.LayoutOrder = 3
	statsPanel.Position = FFGEnum.THEME.alignment.position.center
	statsPanel.Size = UDim2.fromScale(1, 0.6)
	statsPanel.Parent = bottomContainer
	KinUI.ApplyPanelStyle(statsPanel, FFGEnum.THEME.color.white)

	local innerStatsContainer = Instance.new("Frame")
	innerStatsContainer.Name = "StatsContainer"
	innerStatsContainer.BackgroundTransparency = 1
	innerStatsContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	innerStatsContainer.LayoutOrder = 3
	innerStatsContainer.Position = FFGEnum.THEME.alignment.position.center
	innerStatsContainer.Size = UDim2.fromScale(1, 0.6)
	innerStatsContainer.Parent = statsPanel
	KinUI.ApplyList(innerStatsContainer, Enum.FillDirection.Vertical, { HAlign = Enum.HorizontalAlignment.Center, Padding = "XL" })

	local innerStatsPadding = Instance.new("UIPadding")
	KinUI.SetPadding(innerStatsPadding, "XL")
	innerStatsPadding.Parent = innerStatsContainer

	createStats(item, innerStatsContainer)
	-- //!SECTION

	local purchaseTypeLabel = Instance.new("TextLabel")
	purchaseTypeLabel.Name = "PurchaseTypeLabel"
	purchaseTypeLabel.LayoutOrder = 3
	purchaseTypeLabel.Size = UDim2.fromScale(1, 0.1)
	purchaseTypeLabel.Text = item.IsPurchased and "Upgrade" or "Purchase"
	purchaseTypeLabel.AutomaticSize = Enum.AutomaticSize.X
	purchaseTypeLabel.Font = FFGEnum.THEME.bigFont
	purchaseTypeLabel.TextColor3 = FFGEnum.THEME.color.textGold
	purchaseTypeLabel.TextXAlignment = Enum.TextXAlignment.Center
	purchaseTypeLabel.TextStrokeTransparency = 0
	purchaseTypeLabel.TextScaled = true
	purchaseTypeLabel.BackgroundTransparency = 1
	purchaseTypeLabel.Parent = bottomContainer

	-- //SECTION - Buttons
	-- Buy Button
	local buyButtonContainer = Instance.new("Frame")
	buyButtonContainer.Name = "BuyButtonContainer"
	buyButtonContainer.BackgroundTransparency = 1
	buyButtonContainer.LayoutOrder = 3
	buyButtonContainer.Size = UDim2.fromScale(1, 0.2)
	buyButtonContainer.Parent = bottomContainer

	local cost: number = item.IsPurchased and item.UpgradeCost or item.BaseCost or 0
	local buyButton = Button.Create({
		Color = "Green",
		Text = Format.CurrencyNumber(cost),
		Size = UDim2.fromScale(1, 1),
		CurrencyType = "Gold",
	})
	buyButton.Parent = buyButtonContainer

	buyButton.Activated:Connect(function()
		handleButtonClick(item.Id, item.IsPurchased or false)
	end)
	-- //!SECTION
	-- //!SECTION

	local helperUpgradedEvent = Events.GetRemote(Events.RemoteNames.HelperUpgraded)
	if item.Stats then
		if helperUpgradedEvent then
			helperUpgradedEvent.OnClientEvent:Connect(function(helperData: HelperType.HelperData)
				-- Update Quality
				qualityLabel.Text = FFGEnum.QUALITIES[helperData.QualityId].Label or ""
				qualityLabel.TextColor3 = FFGEnum.QUALITIES[helperData.QualityId].Color or Color3.new(1, 1, 1)

				-- Update Level
				if levelLabel then levelLabel.Text = item.IsPurchased and `Level {helperData.Level}` or "" end

				-- Update Stage
				if stageLabel then
					stageLabel.Text = FFGEnum.STAGES[helperData.UpgradeStage].Label
					stageLabel.TextColor3 = FFGEnum.STAGES[helperData.UpgradeStage].Color or Color3.new(1, 1, 1)
				end

				-- Update Stats
				createStats(helperData, innerStatsContainer)

				-- Update Button State (disabled and or upgrade cost)
				local btnText: TextLabel? = buyButton:FindFirstChild("ButtonText", true)
				if btnText then
					if helperData.Level ~= helperData.MaxLevel then
						btnText.Text = Format.CurrencyNumber(helperData.UpgradeCost)
					else
						btnText.Text = "Max level"
					end
				end
			end)
		end
	end

	return tooltipContainer
end

function Tooltip.Initialize()
	-- //SECTION - Bindables
	type itemData = {
		Item: HelperType.HelperData,
		Parent: Instance,
	}

	local openTooltipEvent = Events.GetBindableEvent(Events.BindableNames.ShowTooltip)
	if openTooltipEvent then
		openTooltipEvent.Event:Connect(function(data: itemData)
			if not data then
				error(`Not data was passed when attempting to open tooltip: {data}`)
				return
			end

			Tooltip.ClearExisting(data.Item.Owner)

			Tooltip.Existing[data.Item.Owner] = Tooltip.Create({
				Item = data.Item,
				Size = UDim2.fromScale(0.3, 1),
				Visible = true,
				Parent = data.Parent,
			})
		end)
	end
	-- //!SECTION
end

return Tooltip
