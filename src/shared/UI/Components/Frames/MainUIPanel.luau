local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PanelTab = require(script.Parent.PanelTab)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local AnimateButtonHover = require(ReplicatedStorage.Shared.UI.AnimateButtonHover)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)

local MainUIPanel = {}

type TabsData = {
	Name: string,
	Index: number,
	Icon: string?,
}

type TabProp = {
	hasTabs: boolean,
	tabs: { [number]: TabsData },
}

function MainUIPanel.Create(props: {
	screenGuiName: string,
	panelName: string,
	panelTabs: TabProp?,
})
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = props.screenGuiName
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false

	local panelContainer = Instance.new("Frame")
	panelContainer.Name = "PanelContainer"
	panelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	panelContainer.BackgroundTransparency = 1
	panelContainer.Position = UDim2.fromScale(0.45, 0.5)
	panelContainer.Size = UDim2.fromScale(0.619, 0.7)
	panelContainer.ZIndex = 0
	panelContainer.Parent = screenGui
	UIConfig.ApplyAspect(panelContainer, 16 / 9)

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
	panelBG.Parent = panelContainer

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Position = UDim2.fromScale(-0.035, 0.6)
	tabContainer.Size = UDim2.fromScale(0.071, 0.778777)
	tabContainer.Parent = panelContainer

	local uIListLayout = Instance.new("UIListLayout")
	UIConfig.SetGap(uIListLayout, "XS")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = tabContainer

	if props.panelTabs and props.panelTabs.hasTabs then
		for _, tab in pairs(props.panelTabs.tabs) do
			PanelTab.Create({
				Name = tab.Name,
				Parent = tabContainer,
				LayoutOrder = tab.Index,
				Icon = tab.Icon,
			})
		end
	end

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.Size = UDim2.fromScale(1, 1)
	main.Parent = panelContainer

	local mainPadding = Instance.new("UIPadding")
	UIConfig.SetPadding(mainPadding, "S")
	mainPadding.Parent = main

	local panelNameContainer = Instance.new("Frame")
	panelNameContainer.Name = "PanelNameContainer"
	panelNameContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	panelNameContainer.BackgroundTransparency = 1
	panelNameContainer.Position = UDim2.fromScale(0.500531, 0.1)
	panelNameContainer.Size = UDim2.fromScale(1, 0.0868755)
	panelNameContainer.Parent = main

	local panelNameContainerPadding = Instance.new("UIPadding")
	UIConfig.SetPadding(panelNameContainerPadding, "S")
	panelNameContainerPadding.Parent = panelNameContainer

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Text = props.panelName
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	UIConfig.ApplyTextConstraints(textLabel, "h1")

	local uIStroke = Instance.new("UIStroke")
	uIStroke.Name = "UIStroke"
	uIStroke.LineJoinMode = Enum.LineJoinMode.Bevel
	uIStroke.Thickness = 2.4
	uIStroke.Parent = textLabel

	textLabel.Parent = panelNameContainer

	local innerWindow = Instance.new("Frame")
	innerWindow.Name = "InnerWindow"
	innerWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	innerWindow.BackgroundTransparency = 1
	innerWindow.LayoutOrder = 2
	innerWindow.Position = UDim2.fromScale(0.5, 0.55)
	innerWindow.Size = UDim2.fromScale(1, 0.8)
	innerWindow.ZIndex = 10
	UIConfig.ApplyPanelStyle(innerWindow)
	innerWindow.Parent = main

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromScale(0.497595, 0.512493)
	container.Size = UDim2.fromScale(1, 0.888397)

	local closeButton = Instance.new("ImageButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.BackgroundColor3 = FFGEnum.THEME.color.orange_900
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Size = UDim2.fromScale(0.06, 0.09)

	local baseSize = closeButton.Size
	closeButton.Activated:Connect(function()
		if screenGui then screenGui.Enabled = false end
		if Lighting then
			local children = Lighting:GetChildren()
			for _, instance: Instance in pairs(children) do
				if instance.Name == "Blur" then instance:Destroy() end
			end
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

	local closeButtonX = Instance.new("TextLabel")
	closeButtonX.Name = "TextLabel"
	closeButtonX.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButtonX.BackgroundTransparency = 1
	closeButtonX.Font = FFGEnum.THEME.bigFont
	closeButtonX.Position = UDim2.fromScale(0.5, 0.5)
	closeButtonX.Size = UDim2.fromScale(0.480769, 0.634615)
	closeButtonX.Text = "X"
	closeButtonX.TextColor3 = Color3.new(1, 1, 1)
	closeButtonX.TextScaled = true
	closeButtonX.TextStrokeTransparency = 0

	local uIStroke3 = Instance.new("UIStroke")
	uIStroke3.Name = "UIStroke"
	uIStroke3.Thickness = 2
	uIStroke3.Parent = closeButtonX

	closeButtonX.Parent = closeButton

	local uIAspectRatioConstraint1 = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint1.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint1.Parent = closeButton

	closeButton.Parent = main

	UIConfig.ObserveViewport(function()
		UIConfig.ApplyTextConstraints(textLabel, "h1")
		UIConfig.ApplyPanelStyle(innerWindow)
	end)

	return screenGui
end

return MainUIPanel
