--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local StatsIndexer = require(ReplicatedStorage.Shared.Utils.StatsIndexer)

local canAffordEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.CanAfford)

local InfoPanel = {}

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
			statElementLabel.TextColor3 = FFGEnum.THEME.color.white
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
			statElementValue.TextColor3 = FFGEnum.THEME.color.white
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

function InfoPanel.Create(props: {
	Infodata: any,
	Parent: Instance,
})
	local data = props.Infodata
	local isFish = data.Entity == FFGEnum.CLASS.ENTITY_NAME.Fish
	local isHelper = data.Entity == FFGEnum.CLASS.ENTITY_NAME.Helper

	local panelContainer = Instance.new("Frame")
	panelContainer.Name = "InfoPanelContainer"
	panelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	panelContainer.BackgroundTransparency = 1
	panelContainer.Position = UDim2.fromScale(0.80, 0.5)
	panelContainer.Size = UDim2.fromScale(0.35, 0.9)
	panelContainer.ZIndex = 0
	panelContainer.Parent = props.Parent
	KinUI.AddStroke(panelContainer, "XL", FFGEnum.THEME.FrameStrokes.PrimaryBlue)
	KinUI.AddCorner(panelContainer, "S")
	KinUI.ApplyList(panelContainer, Enum.FillDirection.Vertical, { VFlex = Enum.UIFlexAlignment.SpaceAround })
	KinUI.AddPadding(panelContainer, "M")

	-- //SECTION - Header
	local itemName = Instance.new("Frame")
	itemName.Name = "ItemName"
	itemName.BackgroundTransparency = 1
	itemName.Size = UDim2.fromScale(1, 0.15)
	itemName.Parent = panelContainer

	local text
	if isFish and data then
		local fishData = data :: FishType.FishData
		text = ((not fishData.Caught and "???") or fishData.Name)
	end

	if isHelper and data then
		local helperData = data :: HelperType.HelperData
		text = helperData.Name
	end
	KinUI.AddTextLabel(itemName, nil, text or "", "L")
	-- //!SECTION

	-- //SECTION - Item Image
	local itemImage = Instance.new("Frame")
	itemImage.Name = "ItemImage"
	itemImage.BackgroundTransparency = 1
	itemImage.Size = UDim2.fromScale(1, 0.3)
	itemImage.Parent = panelContainer

	local image
	if isFish and data then
		local fishData = data :: FishType.FishData
		if fishData.SpeciesKey then
			if fishData.Caught then
				image = fishData.ItemImage
			else
				image = FishData.FISH_ASSETS_MASKED[fishData.SpeciesKey]
			end
		else
			image = fishData.ItemImage or ""
		end
	end

	if isHelper and data then
		local helperData = data :: HelperType.HelperData
		image = helperData.ItemImage
	end

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ItemImage"
	if image then imageLabel.Image = image end
	imageLabel.BackgroundTransparency = 1
	imageLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	imageLabel.Position = FFGEnum.THEME.alignment.position.center
	imageLabel.Size = UDim2.fromScale(0.6, 0.6)
	imageLabel.ZIndex = 2
	KinUI.ApplyAspect(imageLabel)
	imageLabel.Parent = itemImage
	-- //!SECTION

	-- //SECTION - Item Variants / Quality
	local itemVariants = Instance.new("Frame")
	itemVariants.BackgroundTransparency = 1
	itemVariants.Name = "ItemVariants"
	itemVariants.Size = UDim2.fromScale(1, 0.08)
	itemVariants.Parent = panelContainer
	KinUI.ApplyList(itemVariants, Enum.FillDirection.Vertical)
	if isFish then KinUI.AddTextLabel(itemVariants, UDim2.fromScale(1, 0.3), isFish and "Variant" or "", "M") end
	KinUI.AddPadding(itemVariants, "M")

	local variantsContainer = Instance.new("Frame")
	variantsContainer.BackgroundTransparency = 1
	variantsContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	variantsContainer.Position = FFGEnum.THEME.alignment.position.center
	variantsContainer.Size = UDim2.fromScale(1, 0.9)
	variantsContainer.Parent = itemVariants
	KinUI.ApplyList(variantsContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	if isFish then
		local fishData = data :: FishType.FishData
		if fishData.Variant == FishData.FISH_VARIANT.NORMAL then
			KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), not fishData.Caught and "???" or "Normal", "M", 1, FFGEnum.THEME.Variants.Normal)
		elseif fishData.Variant == FishData.FISH_VARIANT.ELEMENTAL then
			local element = not fishData.Caught and "???" or fishData.ElementName or "Elemental"
			local elementColor = not fishData.Caught and FFGEnum.THEME.Variants.Elemental[1] or fishData.ElementNum and FFGEnum.THEME.Variants.Elemental[fishData.ElementNum]
			KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), element, "M", 2, elementColor)
		elseif fishData.Variant == FishData.FISH_VARIANT.ELDER then
			KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), not fishData.Caught and "???" or "Elder", "M", 3, FFGEnum.THEME.Variants.Elder)
		end
	end

	if isHelper and data.QualityId then
		local helperData = data :: HelperType.HelperData
		KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), FFGEnum.QUALITIES[helperData.QualityId].Label, "M", nil, FFGEnum.QUALITIES[helperData.QualityId].Color)
	end
	-- //!SECTION

	local statData = nil
	if isFish then
		local fishData = data :: FishType.FishData
		local fishStatFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishStat)
		if fishStatFn then
			if fishData.Caught then
				local freshData = fishStatFn:InvokeServer(fishData)
				local variantData = freshData[fishData.Variant]
				statData = variantData
			end
		end
	elseif isHelper then
		local helperData = data :: HelperType.HelperData
		statData = helperData.Stats
	end

	local itemProgress = Instance.new("Frame")
	itemProgress.Name = "ItemProgress"
	itemProgress.BackgroundTransparency = 1
	itemProgress.Size = UDim2.fromScale(1, 0.4)
	itemProgress.Parent = panelContainer
	KinUI.ApplyList(itemProgress, Enum.FillDirection.Vertical, { VFlex = Enum.UIFlexAlignment.SpaceBetween, HAlign = Enum.HorizontalAlignment.Center })

	if isFish then
		if data.Caught then
			local progressHeader = Instance.new("Frame")
			progressHeader.BackgroundTransparency = 1
			progressHeader.Size = UDim2.fromScale(1, 0.1)
			progressHeader.LayoutOrder = 1
			progressHeader.Parent = itemProgress
			local label = KinUI.AddTextLabel(progressHeader, UDim2.fromScale(0.3, 1), "Total Count", "M")
			label.Position = UDim2.fromScale(0.35, 0.5)

			for i, qualityNum in ipairs(FFGEnum.QUALITIES) do
				local qualityContainer = Instance.new("Frame")
				qualityContainer.Size = UDim2.fromScale(1, 0.15)
				qualityContainer.BackgroundTransparency = 1
				qualityContainer.LayoutOrder = i + 1
				qualityContainer.Parent = itemProgress
				KinUI.ApplyList(qualityContainer, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center })

				local textLabel = KinUI.AddTextLabel(qualityContainer, UDim2.fromScale(0.25, 0.8), FFGEnum.QUALITIES[i].Label, "M")
				textLabel.LayoutOrder = 1

				local countLabel = KinUI.AddTextLabel(qualityContainer, UDim2.fromScale(0.15, 0.8), statData[FFGEnum.QUALITIES[i].Label].Caught, "M")
				countLabel.LayoutOrder = 2

				local progressBarContainer, progressBar = ProgressBar.Create({ Color = "Green", Parent = qualityContainer })
				progressBarContainer.Size = UDim2.fromScale(0.4, 1)
				if typeof(progressBarContainer) == "Frame" then progressBarContainer.LayoutOrder = 3 end

				ProgressBar.Update(progressBar, statData[FFGEnum.QUALITIES[i].Label].Caught, 1000)

				local claimButton = Button.Create({ Color = "White", Text = "Claim", CurrencyType = "None", Size = UDim2.fromScale(0.1, 1) })
				claimButton.ImageColor3 = FFGEnum.THEME.intent.disabled
				claimButton.LayoutOrder = 4
				claimButton.Interactable = false
				claimButton.Parent = qualityContainer
			end
		else
			KinUI.AddTextLabel(itemProgress, UDim2.fromScale(0.8, 0.8), "Undiscovered", "M")
		end
	end

	if isHelper then
		local helperData = data :: HelperType.HelperInstance

		local progressHeader = Instance.new("Frame")
		progressHeader.BackgroundTransparency = 1
		progressHeader.Size = UDim2.fromScale(1, 0.1)
		progressHeader.LayoutOrder = 1
		progressHeader.Parent = itemProgress
		KinUI.ApplyList(progressHeader, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center })

		local levelLabel: TextLabel
		local stageLabel: TextLabel
		if helperData.IsPurchased then
			levelLabel = Instance.new("TextLabel")
			levelLabel.Name = "LevelLabel"
			levelLabel.LayoutOrder = 1
			levelLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
			levelLabel.Position = FFGEnum.THEME.alignment.position.center
			levelLabel.Size = UDim2.fromScale(0.3, 1)
			levelLabel.Text = helperData.IsPurchased and `Level {helperData.Level}` or ""
			levelLabel.TextColor3 = FFGEnum.THEME.color.Green
			levelLabel.TextStrokeTransparency = 0.7
			levelLabel.TextScaled = true
			levelLabel.Font = FFGEnum.THEME.bigFont
			levelLabel.BackgroundTransparency = 1
			levelLabel.Parent = progressHeader

			stageLabel = Instance.new("TextLabel")
			stageLabel.Name = "StageLabel"
			stageLabel.LayoutOrder = 2
			stageLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
			stageLabel.Position = FFGEnum.THEME.alignment.position.center
			stageLabel.Size = UDim2.fromScale(0.3, 1)
			stageLabel.Text = FFGEnum.STAGES[helperData.UpgradeStage].Label
			stageLabel.TextColor3 = FFGEnum.STAGES[helperData.UpgradeStage].Color or Color3.new(1, 1, 1)
			stageLabel.TextStrokeTransparency = 0.7
			stageLabel.TextScaled = true
			stageLabel.Font = FFGEnum.THEME.bigFont
			stageLabel.BackgroundTransparency = 1
			stageLabel.Parent = progressHeader
		end

		createStats(helperData, itemProgress)

		if isHelper then
			local buyButtonContainer = Instance.new("Frame")
			buyButtonContainer.Name = "BuyButtonContainer"
			buyButtonContainer.BackgroundTransparency = 1
			buyButtonContainer.LayoutOrder = 10
			buyButtonContainer.Size = UDim2.fromScale(1, 0.2)
			buyButtonContainer.Parent = itemProgress

			local cost: number = helperData.IsPurchased and helperData.UpgradeCost or helperData.BaseCost or 0
			local canAfford = false
			if canAffordEvent then canAfford = canAffordEvent:InvokeServer("Gold", cost) end

			local colorToUse = canAfford and "Green" or "Gray"

			local buyButton = Button.Create({
				Color = colorToUse,
				Text = Format.CurrencyNumber(cost),
				Size = UDim2.fromScale(0.5, 1),
				CurrencyType = "Gold",
			})
			buyButton.Parent = buyButtonContainer

			buyButton.Activated:Connect(function()
				handleButtonClick(helperData.Id, helperData.IsPurchased or false)
			end)

			local goldChangedEvent = Events.GetRemote(Events.RemoteNames.GoldChanged)
			if goldChangedEvent then
				goldChangedEvent.OnClientEvent:Connect(function(newGoldAmount)
					if buyButton then
						if newGoldAmount < cost then
							Button.Disable(buyButton)
						elseif newGoldAmount >= cost then
							Button.Enable(buyButton)
						end
					end
				end)
			end

			local helperUpgradedEvent = Events.GetRemote(Events.RemoteNames.HelperUpgraded)
			if helperData.Stats then
				if helperUpgradedEvent then
					helperUpgradedEvent.OnClientEvent:Connect(function(helperData: HelperType.HelperInstance)
						-- Update Level
						if levelLabel then levelLabel.Text = helperData.IsPurchased and `Level {helperData.Level}` or "" end

						-- Update Stage
						if stageLabel then
							stageLabel.Text = FFGEnum.STAGES[helperData.UpgradeStage].Label
							stageLabel.TextColor3 = FFGEnum.STAGES[helperData.UpgradeStage].Color or Color3.new(1, 1, 1)
						end

						-- Update Stats
						createStats(helperData, itemProgress)

						-- Update Button State (disabled and or upgrade cost)
						local btnText = buyButton:FindFirstChild("ButtonText", true) :: TextLabel?
						if btnText then
							if helperData.Level ~= helperData.MaxLevel then
								btnText.Text = Format.CurrencyNumber(helperData.UpgradeCost or 0)
							else
								btnText.Text = "Max level"
							end
						end
					end)
				end
			end
		end
	end

	return panelContainer
end

return InfoPanel
