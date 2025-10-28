local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	shopItemContainer.BackgroundTransparency = props.BackgroundTransparency or props.ItemQualityId == 1 and 0 or 1
	shopItemContainer.Size = props.Size
	shopItemContainer.BackgroundColor3 = props.BackgroundColor3 or FFGEnum.THEME.color.white
	shopItemContainer.AnchorPoint = props.AnchorPoint or FFGEnum.THEME.alignment.anchor.center
	shopItemContainer.Position = props.Position or FFGEnum.THEME.alignment.position.center
	shopItemContainer.Visible = props.Visible or true
	shopItemContainer.ClipsDescendants = true
	shopItemContainer.Parent = props.Parent or nil

	local frameCorner = Instance.new("UICorner")
	if props.ItemQualityId == 1 then frameCorner.Parent = shopItemContainer end

	local itemQualityBG = Instance.new("ImageLabel")
	itemQualityBG.Name = "ItemBG"
	itemQualityBG.Size = UDim2.fromScale(1, 1)
	itemQualityBG.SliceCenter = props.SliceCenter or nil
	itemQualityBG.ScaleType = props.ScaleType or nil
	itemQualityBG.BackgroundTransparency = 1
	itemQualityBG.ImageTransparency = props.ItemQualityId == 1 and 0.4 or 0
	itemQualityBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemQualityBG.Position = FFGEnum.THEME.alignment.position.center
	itemQualityBG.Image = FFGEnum.UI.Items.BackgroundQualityId[props.ItemQualityId]
	itemQualityBG.Parent = shopItemContainer

	-- local backgroundPattern = Instance.new("ImageLabel")
	-- backgroundPattern.Name = "ImageLabel"
	-- backgroundPattern.AnchorPoint = Vector2.new(0.5, 0.5)
	-- backgroundPattern.BackgroundTransparency = 1
	-- backgroundPattern.Image =
	-- backgroundPattern.Position = UDim2.fromScale(0.5, 0.4)
	-- backgroundPattern.ScaleType = Enum.ScaleType.Fit
	-- backgroundPattern.Size = UDim2.fromScale(1, 1)
	-- backgroundPattern.ZIndex = 0
	-- backgroundPattern.Parent = shopItemContainer

	-- local backgroundPatternGradient = Instance.new("UIGradient")
	-- backgroundPatternGradient.Name = "UIGradient"
	-- local base = props.BackgroundColor3 or FFGEnum.THEME.color.white
	-- local factor = 0.8 -- reduce brightness by 20%
	-- local darker = Color3.new(math.clamp(base.R * factor, 0, 1), math.clamp(base.G * factor, 0, 1), math.clamp(base.B * factor, 0, 1))

	-- backgroundPatternGradient.Color = ColorSequence.new({
	-- 	ColorSequenceKeypoint.new(0, props.BackgroundColor3 or FFGEnum.THEME.color.white),
	-- 	ColorSequenceKeypoint.new(0.5, darker),
	-- 	ColorSequenceKeypoint.new(1, props.BackgroundColor3 or FFGEnum.THEME.color.white),
	-- })
	-- backgroundPatternGradient.Transparency = NumberSequence.new({
	-- 	NumberSequenceKeypoint.new(0, 0.7),
	-- 	NumberSequenceKeypoint.new(1, 0.7),
	-- })
	-- backgroundPatternGradient.Parent = backgroundPattern

	local strokeThickness = 0
	shopItemContainer.MouseEnter:Connect(function()
		if not props.HoverEffect then return end
	end)
	shopItemContainer.MouseLeave:Connect(function()
		if props.HoverEffect then return end
	end)

	-- //SECTION - Shop Item Outline
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = props.HoverEffect and FFGEnum.THEME.color.buttons or Color3.new(0, 0, 0)
	containerStroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	containerStroke.Thickness = strokeThickness

	containerStroke.Parent = shopItemContainer

	local containerStroke2 = Instance.new("UIStroke")
	containerStroke2.Color = props.HoverEffect and FFGEnum.THEME.color.white or Color3.new(0, 0, 0)
	containerStroke2.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	containerStroke2.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	containerStroke2.Thickness = (strokeThickness / 2)
	containerStroke2.Transparency = 0.9

	containerStroke2.Parent = shopItemContainer

	shopItemContainer.MouseEnter:Connect(function()
		strokeThickness = FFGEnum.THEME.shop.shopItem.outlineThickness
		containerStroke2.Thickness = strokeThickness
	end)

	shopItemContainer.MouseLeave:Connect(function()
		strokeThickness = 0
		containerStroke2.Thickness = strokeThickness
	end)
	-- //!SECTION

	-- //SECTION -  Shop Item Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = props.Rounded
	corner.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION Holds all the main elements
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "ShopItemMainContainer"
	mainContainer.Size = UDim2.fromScale(0.9, 0.9)
	mainContainer.Position = FFGEnum.THEME.alignment.position.center
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION -  Item Image
	local item = Instance.new("ImageLabel")
	item.Image = props.ItemImage
	item.BackgroundTransparency = 1
	item.Size = UDim2.fromScale(0.8, 0.75)
	item.ZIndex = 2
	item.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Price
	local ItemBaseCostColor = FFGEnum.THEME.shop.shopItem.buttonColor

	local ItemBaseCostTxt = Instance.new("TextLabel")
	ItemBaseCostTxt.BorderSizePixel = 0
	ItemBaseCostTxt.Position = FFGEnum.THEME.alignment.position.bottom
	ItemBaseCostTxt.AnchorPoint = FFGEnum.THEME.alignment.anchor.bottom
	ItemBaseCostTxt.TextColor3 = FFGEnum.THEME.color.white
	ItemBaseCostTxt.BackgroundColor3 = ItemBaseCostColor
	ItemBaseCostTxt.TextScaled = true
	ItemBaseCostTxt.Text = props.ItemBaseCost
	ItemBaseCostTxt.Font = FFGEnum.THEME.bigFont
	ItemBaseCostTxt.Size = UDim2.fromScale(1, 0.2)
	ItemBaseCostTxt.Parent = shopItemContainer
	-- //!SECTION

	-- //SECTION - UI List Layout
	local uiList = Instance.new("UIListLayout")
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.VerticalFlex = Enum.UIFlexAlignment.SpaceBetween
	uiList.Parent = mainContainer
	-- //!SECTION

	-- //SECTION - Hover Effects
	shopItemContainer.MouseEnter:Connect(function()
		-- UIStroke
		strokeThickness = FFGEnum.THEME.shop.shopItem.outlineThickness
		containerStroke.Thickness = strokeThickness

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
		-- UIStroke
		strokeThickness = 0
		containerStroke.Thickness = strokeThickness
	end)

	return shopItemContainer
end

return ShopItem
