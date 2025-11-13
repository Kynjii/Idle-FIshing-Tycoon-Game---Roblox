local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local StatsIndexer = require(ReplicatedStorage.Shared.Utils.StatsIndexer)
local AvailableHelperListItem = {}

function AvailableHelperListItem.Create(helper: HelperType.HelperData, selectedHelperState: StringValue)
	local availableHelperTemplate = Instance.new("Frame")
	availableHelperTemplate.AutomaticSize = Enum.AutomaticSize.Y
	availableHelperTemplate.Name = "AvailableHelperTemplate"
	availableHelperTemplate.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	availableHelperTemplate.BackgroundTransparency = 1
	availableHelperTemplate.Position = FFGEnum.THEME.alignment.position.center
	availableHelperTemplate.Size = UDim2.fromScale(1, 1)

	local bG = Instance.new("ImageLabel")
	bG.Name = "BG"
	bG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	bG.BackgroundTransparency = 1
	bG.Image = FFGEnum.UI.Items.BackgroundQualityId[helper.QualityId]
	bG.Position = FFGEnum.THEME.alignment.position.center
	bG.ScaleType = Enum.ScaleType.Slice
	bG.Size = UDim2.fromScale(1, 1)
	bG.SliceCenter = Rect.new(45, 45, 45, 45)
	bG.Parent = availableHelperTemplate

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	container.BackgroundTransparency = 1
	container.Position = FFGEnum.THEME.alignment.position.center
	container.Size = UDim2.fromScale(1, 1)
	KinUI.ApplyList(container, Enum.FillDirection.Vertical)
	KinUI.AddPadding(container, "XL")

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "HelperName"
	textLabel.LayoutOrder = 1
	textLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	textLabel.BackgroundTransparency = 1
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.Position = FFGEnum.THEME.alignment.position.center
	textLabel.Size = UDim2.fromScale(1, 0.2)
	textLabel.Text = helper.Name or ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = container

	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.fromScale(1, 0.7)
	mainContainer.BackgroundTransparency = 1
	mainContainer.AutomaticSize = Enum.AutomaticSize.Y
	mainContainer.LayoutOrder = 2
	KinUI.ApplyList(mainContainer, Enum.FillDirection.Horizontal, { VAlign = Enum.VerticalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })
	mainContainer.Parent = container

	local assignButton = Instance.new("ImageButton")
	assignButton.Name = "AssignButton"
	assignButton.LayoutOrder = 2
	assignButton.ImageColor3 = FFGEnum.THEME.color.white
	assignButton.Position = UDim2.fromScale(0.8, 0.5)
	assignButton.BackgroundTransparency = 1
	assignButton.Image = FFGEnum.UI.Buttons.ButtonImages.Assign
	assignButton.ScaleType = Enum.ScaleType.Fit
	assignButton.Size = UDim2.fromScale(0.2, 0.5)
	KinUI.ApplyAspect(assignButton, 16 / 9)
	assignButton.Parent = mainContainer

	local baseColor = assignButton.ImageColor3
	local baseImage = assignButton.Image
	assignButton.MouseEnter:Connect(function()
		assignButton.ImageColor3 = FFGEnum.THEME.hoverStrokeColor
	end)

	assignButton.MouseLeave:Connect(function()
		assignButton.ImageColor3 = baseColor
	end)

	assignButton.Activated:Connect(function()
		if selectedHelperState and selectedHelperState.Value == "" then
			selectedHelperState.Value = helper.Id

			assignButton.Image = FFGEnum.UI.Buttons.ButtonImages.Unassign
		else
			assignButton.Image = baseImage
			selectedHelperState.Value = ""
		end
	end)

	local helperInfoContainer = Instance.new("Frame")
	helperInfoContainer.Name = "HelperInfoContainer"
	helperInfoContainer.BackgroundTransparency = 1
	helperInfoContainer.Size = UDim2.fromScale(0.8, 1)
	helperInfoContainer.LayoutOrder = 2
	KinUI.ApplyPanelStyle(helperInfoContainer)
	KinUI.AddPadding(helperInfoContainer, "M")
	helperInfoContainer.Parent = mainContainer

	local helperInnerInfoContainer = Instance.new("Frame")
	helperInnerInfoContainer.Name = "HelperInnerInfoContainer"
	helperInnerInfoContainer.BackgroundTransparency = 1
	helperInnerInfoContainer.Size = UDim2.fromScale(1, 1)
	KinUI.ApplyList(helperInnerInfoContainer, Enum.FillDirection.Horizontal, { VAlign = Enum.VerticalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })
	KinUI.AddPadding(helperInnerInfoContainer, "L")
	helperInnerInfoContainer.Parent = helperInfoContainer

	local helperImage = Instance.new("ImageLabel")
	helperImage.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	helperImage.Position = FFGEnum.THEME.alignment.position.center
	helperImage.Name = "HelperImage"
	helperImage.Image = helper.ItemImage
	helperImage.LayoutOrder = 1
	helperImage.BackgroundTransparency = 1
	helperImage.Size = UDim2.fromScale(0.6, 0.6)
	helperImage.ZIndex = 1
	KinUI.ApplyAspect(helperImage)
	helperImage.Parent = helperInnerInfoContainer

	local helperInfo = Instance.new("Frame")
	helperInfo.LayoutOrder = 2
	helperInfo.BackgroundTransparency = 1
	helperInfo.Size = UDim2.fromScale(0.6, 1)
	KinUI.ApplyList(helperInfo, Enum.FillDirection.Vertical, { VAlign = Enum.VerticalAlignment.Top, HAlign = Enum.HorizontalAlignment.Left })
	helperInfo.Parent = helperInnerInfoContainer

	local entityLevelAndStageContainer = Instance.new("Frame")
	entityLevelAndStageContainer.Name = "EntityLevelAndStageContainer"
	entityLevelAndStageContainer.LayoutOrder = 2
	entityLevelAndStageContainer.Position = FFGEnum.THEME.alignment.position.center
	entityLevelAndStageContainer.Size = UDim2.fromScale(1, 0.2)
	entityLevelAndStageContainer.BackgroundTransparency = 1
	entityLevelAndStageContainer.Parent = helperInfo
	KinUI.ApplyList(
		entityLevelAndStageContainer,
		Enum.FillDirection.Horizontal,
		{ HAlign = Enum.HorizontalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center }
	)

	local helperLevel = Instance.new("TextLabel")
	helperLevel.Name = "Level"
	helperLevel.Font = FFGEnum.THEME.bigFont
	helperLevel.Size = UDim2.fromScale(0.5, 1)
	helperLevel.BackgroundTransparency = 1
	helperLevel.TextColor3 = FFGEnum.THEME.color.Green
	helperLevel.TextXAlignment = Enum.TextXAlignment.Left
	helperLevel.LayoutOrder = 1
	helperLevel.Text = `Level {helper.Level}`
	helperLevel.TextScaled = true
	KinUI.AddPadding(helperLevel, "M")
	helperLevel.Parent = entityLevelAndStageContainer

	local helperStage = Instance.new("TextLabel")
	helperStage.Name = "Stage"
	helperStage.Font = FFGEnum.THEME.bigFont
	helperStage.Size = UDim2.fromScale(0.5, 1)
	helperStage.BackgroundTransparency = 1
	helperStage.TextXAlignment = Enum.TextXAlignment.Center
	helperStage.LayoutOrder = 2
	helperStage.Text = FFGEnum.STAGES[helper.UpgradeStage].Label
	helperStage.TextColor3 = FFGEnum.STAGES[helper.UpgradeStage].Color or Color3.new(1, 1, 1)
	helperStage.TextScaled = true
	KinUI.AddPadding(helperStage, "M")
	helperStage.Parent = entityLevelAndStageContainer

	local helperStatsContainer = Instance.new("Frame")
	helperStatsContainer.LayoutOrder = 2
	helperStatsContainer.Size = UDim2.fromScale(1, 0.8)
	helperStatsContainer.BackgroundTransparency = 1
	KinUI.ApplyList(helperStatsContainer, Enum.FillDirection.Vertical)
	KinUI.AddPadding(helperStatsContainer, "M")
	helperStatsContainer.Parent = helperInfo

	local preparedData = StatsIndexer.Prepare(helper)

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
			statFrameContainer.Parent = helperStatsContainer

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

	container.Parent = availableHelperTemplate

	return availableHelperTemplate
end

return AvailableHelperListItem
