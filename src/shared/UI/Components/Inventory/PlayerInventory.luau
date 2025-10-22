local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local PlayerInventory = {}

function PlayerInventory.Create(props: {
	Name: string,
	ScreenGuiName: string,
})
	local shopScreenGui = Instance.new("ScreenGui")
	shopScreenGui.Name = props.ScreenGuiName
	shopScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	shopScreenGui.ResetOnSpawn = false
	shopScreenGui.Enabled = true

	local mainPanel = MainUIPanel.Create({ Name = "Inventory" })
	mainPanel.Parent = shopScreenGui

	local shopItemsContainer = Instance.new("ScrollingFrame")
	shopItemsContainer.Name = "ShopItemsContainer"
	shopItemsContainer.Active = true
	shopItemsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	shopItemsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopItemsContainer.BackgroundTransparency = 1
	shopItemsContainer.CanvasSize = UDim2.fromScale(0, 4)
	shopItemsContainer.Position = UDim2.fromScale(0.5, 0.533006)
	shopItemsContainer.ScrollBarImageColor3 = Color3.new()
	shopItemsContainer.ScrollBarThickness = 0
	shopItemsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	shopItemsContainer.Size = UDim2.fromScale(1, 0.933988)

	local uiGridLayout = Instance.new("UIGridLayout")
	uiGridLayout.Name = "UIGridLayout"
	uiGridLayout.CellSize = UDim2.fromScale(0.15, 0.3)
	uiGridLayout.CellPadding = UDim2.fromScale(0.05, 0.05)
	uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
	uiGridLayout.FillDirectionMaxCells = 5
	uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiGridLayout.Parent = shopItemsContainer

	local gridPadding = Instance.new("UIPadding")
	gridPadding.Name = "GridPadding"
	gridPadding.PaddingBottom = UDim.new(0.01, 0)
	gridPadding.PaddingLeft = UDim.new(0.01, 0)
	gridPadding.PaddingRight = UDim.new(0.01, 0)
	gridPadding.PaddingTop = UDim.new(0.01, 0)
	gridPadding.Parent = shopItemsContainer

	shopItemsContainer.Parent = mainPanel

	local tooltip = Tooltip({
		ItemImage = "",
		ItemCost = "",
		ItemDescription = "",
		ItemName = "",
		Parent = mainPanel,
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
	}

	local bindableEvent = Events.GetBindableEvent(Events.BindableNames.ShowShopTooltip)
	if bindableEvent then bindableEvent.Event:Connect(function(data: itemData)
		if not data then
			error("Not data was passed when attempting to open shop tooltip", data)
			return
		end

		if tooltip then tooltip:Destroy() end
		tooltip = Tooltip({
			ItemCost = data.Price,
			ItemDescription = data.Description,
			ItemName = data.Name,
			ItemImage = data.Image,
			Size = UDim2.fromScale(0.3, 1),
			Rounded = FFGEnum.THEME.button.cornerRadius,
			Visible = true,
			Parent = mainPanel,
		})
	end) end
	-- //!SECTION

	return shopScreenGui
end

function PlayerInventory.CloseShop(screenGui)
	screenGui.Enabled = false
	if Lighting then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then blur:Destroy() end
	end
end

return PlayerInventory
