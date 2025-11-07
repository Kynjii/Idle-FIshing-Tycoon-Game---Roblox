--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local AnimateButtonHover = require(ReplicatedStorage.Shared.UI.AnimateButtonHover)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
local AvailableHelperListItem = {}

function AvailableHelperListItem.Create(helper: HelperType.HelperData)
	local availableHelperTemplate = Instance.new("Frame")
	availableHelperTemplate.AutomaticSize = Enum.AutomaticSize.Y
	availableHelperTemplate.Name = "availableHelperTemplate"
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
	UIConfig.ApplyList(container, Enum.FillDirection.Vertical)

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Parent = container
	UIConfig.SetPadding(uIPadding, "M")

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
	UIConfig.ApplyList(mainContainer, Enum.FillDirection.Horizontal, { VAlign = Enum.VerticalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })
	mainContainer.Parent = container

	local assignButton = Instance.new("ImageButton")
	assignButton.Name = "AssignButton"
	assignButton.LayoutOrder = 2
	assignButton.Position = UDim2.fromScale(0.8, 0.5)
	assignButton.BackgroundTransparency = 1
	assignButton.Image = "rbxassetid://119147831935362"
	assignButton.ScaleType = Enum.ScaleType.Fit
	assignButton.Size = UDim2.fromScale(0.2, 0.5)
	UIConfig.ApplyAspect(assignButton, 16 / 9)
	assignButton.Parent = mainContainer

	local baseSize = assignButton.Size
	assignButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(assignButton, baseSize)
	end)

	assignButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(assignButton, baseSize)
	end)

	assignButton.Activated:Connect(function()
		print("Clicky click, time to assign")
	end)

	container.Parent = availableHelperTemplate

	return availableHelperTemplate
end

return AvailableHelperListItem
