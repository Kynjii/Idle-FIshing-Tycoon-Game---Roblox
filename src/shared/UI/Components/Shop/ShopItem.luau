local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)

local function ShopItem(
	props: {
		BackgroundColor3: Color3?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?,
		ScaleType: Enum?,
		SliceCenter: Rect?,
		Visible: boolean?,
		HoverEffect: boolean?,
		ItemImage: string,
		ItemName: string,
		ItemId: string,
		ItemDescription: string,
		ItemBaseCost: string,
		ItemStats: { [number]: { [string]: any } }?,
		ItemQualityId: number,
		Parent: Instance,
		ShopInstance: Instance,
		Owner: number,
		IsPurchased: boolean?,
	}
)
	local shopItemContainer = Instance.new("Frame")
	shopItemContainer.Name = props.ItemId
	shopItemContainer.BackgroundTransparency = props.BackgroundTransparency or 1
	shopItemContainer.Size = props.Size
	shopItemContainer.BackgroundColor3 = props.BackgroundColor3 or FFGEnum.THEME.color.white
	shopItemContainer.AnchorPoint = props.AnchorPoint or FFGEnum.THEME.alignment.anchor.center
	shopItemContainer.Position = props.Position or FFGEnum.THEME.alignment.position.center
	shopItemContainer.Visible = props.Visible or true
	shopItemContainer.ClipsDescendants = true
	shopItemContainer.Parent = props.Parent or nil

	local shopItemContainerAspect = Instance.new("UIAspectRatioConstraint")
	shopItemContainerAspect.AspectRatio = 1
	shopItemContainerAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	shopItemContainerAspect.Parent = shopItemContainer

	local itemQualityBG = Instance.new("ImageLabel")
	itemQualityBG.Name = "ItemBG"
	itemQualityBG.Size = UDim2.fromScale(1, 1)
	itemQualityBG.SliceCenter = props.SliceCenter or nil
	itemQualityBG.ScaleType = props.ScaleType or nil
	itemQualityBG.BackgroundTransparency = 1
	itemQualityBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemQualityBG.Position = FFGEnum.THEME.alignment.position.center
	itemQualityBG.Image = FFGEnum.UI.Items.BackgroundQualityId[props.ItemQualityId]
	itemQualityBG.Parent = shopItemContainer

	-- //SECTION - Shop Item Outline
	local hoverImage = Instance.new("ImageLabel")
	hoverImage.Name = "HoverImage"
	hoverImage.Image = FFGEnum.UI.Items.Hovered
	hoverImage.BackgroundTransparency = 1
	hoverImage.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	hoverImage.Position = FFGEnum.THEME.alignment.position.center
	hoverImage.ScaleType = Enum.ScaleType.Slice
	hoverImage.SliceCenter = Rect.new(26, 34, 31, 37)
	hoverImage.ImageColor3 = FFGEnum.THEME.color.white
	hoverImage.ImageTransparency = 0.7
	hoverImage.Size = UDim2.fromScale(0.95, 0.85)
	hoverImage.Visible = false
	hoverImage.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION -  Shop Item Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = props.Rounded
	corner.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION Holds all the main elements
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "ShopItemMainContainer"
	mainContainer.Size = UDim2.fromScale(0.9, 0.8)
	mainContainer.Position = FFGEnum.THEME.alignment.position.center
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION - Item Name
	local itemName = Instance.new("TextLabel")
	itemName.Font = FFGEnum.THEME.bigFont
	itemName.TextScaled = true
	itemName.Size = UDim2.fromScale(1, 0.2)
	itemName.BackgroundTransparency = 1
	itemName.TextColor3 = FFGEnum.THEME.color.white
	itemName.LayoutOrder = 1
	itemName.Text = props.ItemName
	itemName.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Image
	local item = Instance.new("ImageLabel")
	item.Name = "ItemImage"
	item.Image = props.ItemImage
	item.LayoutOrder = 2
	item.BackgroundTransparency = 1
	item.Size = UDim2.fromScale(0.6, 0.6)
	item.ZIndex = 2
	item.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Price
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "PriceContainer"
	priceContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	priceContainer.Size = UDim2.fromScale(1, 0.2)
	priceContainer.LayoutOrder = 3
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = mainContainer

	local priceContainerGradient = Instance.new("ImageLabel")
	priceContainerGradient.Name = "Gradient"
	priceContainerGradient.Image = "rbxassetid://74369602913754"
	priceContainerGradient.Size = UDim2.fromScale(0.99, 1)
	priceContainerGradient.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	priceContainerGradient.Position = FFGEnum.THEME.alignment.position.center
	priceContainerGradient.ImageColor3 = Color3.fromRGB(1, 1, 1)
	priceContainerGradient.ImageTransparency = 0.7
	priceContainerGradient.Rotation = 180
	priceContainerGradient.BackgroundTransparency = 1
	priceContainerGradient.Parent = priceContainer

	local priceContainerGradientCorner = Instance.new("UICorner")
	priceContainerGradientCorner.CornerRadius = UDim.new(0.3)
	priceContainerGradientCorner.Parent = priceContainerGradient

	local priceContainerInner = Instance.new("Frame")
	priceContainerInner.Size = UDim2.fromScale(1, 1)
	priceContainerInner.LayoutOrder = 3
	priceContainerInner.BackgroundTransparency = 1
	priceContainerInner.Parent = priceContainer

	local currencyIcon = Instance.new("ImageLabel")
	currencyIcon.Image = FFGEnum.UI.Icons.Gold
	currencyIcon.BackgroundTransparency = 1
	currencyIcon.Size = UDim2.fromScale(0.3, 0.9)
	currencyIcon.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	currencyIcon.Parent = priceContainerInner

	local currencyIconAspect = Instance.new("UIAspectRatioConstraint")
	currencyIconAspect.Parent = currencyIcon

	local ItemBaseCostTxt = Instance.new("TextLabel")
	ItemBaseCostTxt.BorderSizePixel = 0
	ItemBaseCostTxt.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	ItemBaseCostTxt.TextColor3 = FFGEnum.THEME.color.white
	ItemBaseCostTxt.BackgroundTransparency = 1
	ItemBaseCostTxt.TextScaled = true
	ItemBaseCostTxt.LayoutOrder = 2
	ItemBaseCostTxt.Text = props.ItemBaseCost
	ItemBaseCostTxt.Font = FFGEnum.THEME.bigFont
	ItemBaseCostTxt.Size = UDim2.fromScale(0.5, 0.9)
	ItemBaseCostTxt.Parent = priceContainerInner

	local priceContainerList = Instance.new("UIListLayout")
	priceContainerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	priceContainerList.VerticalAlignment = Enum.VerticalAlignment.Center
	priceContainerList.FillDirection = Enum.FillDirection.Horizontal
	priceContainerList.SortOrder = Enum.SortOrder.LayoutOrder
	priceContainerList.Parent = priceContainerInner
	-- //!SECTION

	-- //SECTION - UI List Layout
	local uiList = Instance.new("UIListLayout")
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiList.VerticalFlex = Enum.UIFlexAlignment.SpaceAround
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = mainContainer
	-- //!SECTION

	-- //SECTION - Hover Effects
	shopItemContainer.MouseEnter:Connect(function()
		hoverImage.Visible = true

		-- Tooltips
		local bindableEvent = Events.GetBindableEvent(Events.BindableNames.ShowTooltip)
		if bindableEvent then
			local itemData = {
				ItemImage = props.ItemImage,
				ItemBaseCost = props.ItemBaseCost,
				ItemName = props.ItemName,
				ItemId = props.ItemId,
				ItemDescription = props.ItemDescription,
				ItemStats = props.ItemStats,
				ItemQualityId = props.ItemQualityId,
				Owner = props.Owner,
				Parent = props.ShopInstance,
			}

			Events.FireBindableEvent(Events.BindableNames.ShowTooltip, itemData)
		end
	end)

	shopItemContainer.MouseLeave:Connect(function()
		hoverImage.Visible = false
	end)

	return shopItemContainer
end

return ShopItem
