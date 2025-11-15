--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)

local function ShopItem(
	props: {
		ItemData: HelperType.HelperData,
		BackgroundColor3: Color3?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?,
		ScaleType: Enum.ScaleType?,
		SliceCenter: Rect?,
		Visible: boolean?,
		HoverEffect: boolean?,
		Parent: Instance,
		ShopInstance: Instance,
	}
)
	local item = props.ItemData

	local shopItemContainer = Instance.new("Frame")
	shopItemContainer.Name = item.Id or item.Species
	shopItemContainer.BackgroundTransparency = 1
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

	local variant = {
		normal = 1,
		elemental = 2,
		elder = 5,
	}

	local itemQualityBG = Instance.new("ImageLabel")
	itemQualityBG.Name = "ItemBG"
	itemQualityBG.Size = UDim2.fromScale(1, 1)
	if props.SliceCenter ~= nil then itemQualityBG.SliceCenter = props.SliceCenter end
	if props.ScaleType ~= nil then itemQualityBG.ScaleType = props.ScaleType end
	itemQualityBG.BackgroundTransparency = 1
	itemQualityBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemQualityBG.Position = FFGEnum.THEME.alignment.position.center
	itemQualityBG.Image = FFGEnum.UI.Items.BackgroundQualityId[item.QualityId or item.Tier or variant[item.Variant]]
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
	corner.CornerRadius = props.Rounded or UDim.new(0, 0)
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
	itemName.Name = "ItemName"
	itemName.Font = FFGEnum.THEME.bigFont
	itemName.Size = UDim2.fromScale(1, 0.2)
	itemName.BackgroundTransparency = 1
	itemName.TextColor3 = FFGEnum.THEME.color.white
	itemName.LayoutOrder = 1
	itemName.Text = item.Name or item.Species
	itemName.TextScaled = true
	KinUI.AddStroke(itemName, "L")
	itemName.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Image
	local itemImage = Instance.new("ImageLabel")
	itemImage.Name = "ItemImage"
	itemImage.Image = item.ItemImage or ""
	itemImage.LayoutOrder = 2
	itemImage.BackgroundTransparency = 1
	itemImage.Size = UDim2.fromScale(0.6, 0.6)
	itemImage.ZIndex = 2
	KinUI.ApplyAspect(itemImage)
	itemImage.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Price
	if not item.IsPurchased then
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
		ItemBaseCostTxt.LayoutOrder = 2
		ItemBaseCostTxt.Text = item.Caught and "CAUGHT" or Format.CurrencyNumber(item.BaseCost or 0) or ""
		ItemBaseCostTxt.Font = FFGEnum.THEME.bigFont
		ItemBaseCostTxt.Size = UDim2.fromScale(0.5, 0.9)
		ItemBaseCostTxt.TextScaled = true
		ItemBaseCostTxt.Parent = priceContainerInner

		local priceContainerList = Instance.new("UIListLayout")
		priceContainerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		priceContainerList.VerticalAlignment = Enum.VerticalAlignment.Center
		priceContainerList.FillDirection = Enum.FillDirection.Horizontal
		priceContainerList.SortOrder = Enum.SortOrder.LayoutOrder
		priceContainerList.Parent = priceContainerInner
	end
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
				Item = item,
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
