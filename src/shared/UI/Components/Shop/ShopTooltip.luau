local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local GetValue = require(ReplicatedStorage.Shared.Utils.GetValue)

-- //SECTION -  Vide functions
local create = vide.create
local effect = vide.effect
local source = vide.source
local spring = vide.spring
-- //!SECTION

local function ShopTooltip(props: {
	BackgroundColor3: Color3?,
	Size: UDim2,
	Rounded: UDim?,
	Visible: boolean?,
	ItemImage: string,
	ItemCost: string,
	ItemName: string,
	ItemDescription: string,
})
	local isOwned = source(false)

	-- //SECTION - Shop Tooltip Container
	local shopTooltipContainer = create("Frame")({
		Size = props.Size,
		BackgroundColor3 = props.BackgroundColor3 or FFGEnum.THEME.color.white,
		AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
		Position = FFGEnum.THEME.alignment.position.center,
		Visible = props.Visible or true,
	})

	-- //SECTION - Shop Item Outline
	local containerStroke = create("UIStroke")({
		Color = FFGEnum.THEME.shop.shopItem.outline or Color3.new(0, 0, 0),
		StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
		Thickness = FFGEnum.THEME.shop.shopItem.outlineThickness,
	})
	containerStroke.Parent = shopTooltipContainer
	-- //!SECTION

	-- //SECTION -  Shop Item Corner
	local corner = create("UICorner")({})
	corner.Parent = shopTooltipContainer

	if GetValue(props.Rounded) then
		corner.CornerRadius = props.Rounded
	else
		corner.CornerRadius = UDim.new(0)
	end
	-- //!SECTION

	-- //SECTION - Frame Header
	local frameHeader = create("ImageLabel")({
		Image = FFGEnum.THEME.shop.shopTooltip.frameTriangle,
		Size = UDim2.fromScale(0.9, 0.1),
		AnchorPoint = FFGEnum.THEME.alignment.anchor.top,
		Position = FFGEnum.THEME.alignment.position.frameHeader,
		ResampleMode = Enum.ResamplerMode.Default,
		BackgroundTransparency = 1,
		Parent = shopTooltipContainer,
	})

	-- //SECTION -  Item Name
	create("TextLabel")({
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.85, 0.85),
		AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
		Position = FFGEnum.THEME.alignment.position.textFrameHeaderCenter,
		TextStrokeTransparency = 0,
		Text = props.ItemName,
		Font = FFGEnum.THEME.font,
		TextColor3 = FFGEnum.THEME.color.white,
		TextScaled = true,
		Parent = frameHeader,
	})
	-- //!SECTION
	-- //!SECTION

	-- //SECTION Holds all the main elements
	local mainContainer = create("Frame")({
		Size = UDim2.fromScale(0.9, 0.9),
		Position = FFGEnum.THEME.alignment.position.center,
		AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
		BackgroundTransparency = 1,
		Parent = shopTooltipContainer,
	})
	-- //!SECTION

	-- //SECTION - Item Info Container
	local itemInfoContainer = create("Frame")({
		Size = UDim2.fromScale(1, 0.4),
		Position = UDim2.fromScale(0.5, 0.05),
		AnchorPoint = FFGEnum.THEME.alignment.anchor.top,
		BackgroundTransparency = 1,
		Parent = mainContainer,
	})

	-- //SECTION -  Item Image
	local itemImageContainer = create("Frame")({
		BackgroundColor3 = FFGEnum.THEME.shop.shopItem.outline,
		Size = UDim2.fromScale(0.3, 0.3),
		Parent = itemInfoContainer,
	})
	create("ImageLabel")({
		Image = props.ItemImage,
		AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
		Position = FFGEnum.THEME.alignment.position.center,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.9, 0.9),
		Parent = itemImageContainer,
	})

	create("UICorner")({
		CornerRadius = FFGEnum.THEME.button.cornerRadius,
		Parent = itemImageContainer,
	})

	create("UIStroke")({
		Color = FFGEnum.THEME.color.teal_900,
		StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
		Thickness = 1,
		Parent = itemImageContainer,
	})
	-- //!SECTION

	-- //SECTION - Item Price
	create("TextLabel")({
		Text = props.ItemCost,
		Font = FFGEnum.THEME.font,
		TextColor3 = FFGEnum.THEME.intent.notice,
		TextStrokeTransparency = 0,
		TextScaled = true,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.9, 0.15),
		Parent = itemInfoContainer,
	})
	-- //!SECTION

	-- //SECTION - Item Description
	create("TextLabel")({
		Text = props.ItemDescription,
		TextColor3 = FFGEnum.THEME.color.teal_900,
		TextWrapped = true,
		TextScaled = true,
		Font = FFGEnum.THEME.font,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.9, 0.35),
		Parent = itemInfoContainer,
	})
	-- //!SECTION

	-- //SECTION - Buy Button
	local buttonSize = UDim2.fromScale(1, 0.1)
	local sizeSource = source(buttonSize)
	local buttonColor = source(FFGEnum.THEME.shop.shopItem.buttonColor)
	local buttonText = source("Purchase")
	local size = spring(sizeSource, 0.2)
	local sizeSpringDebounce = false

	local buyButton = create("ImageButton")({
		BackgroundTransparency = 1,
		PressedImage = FFGEnum.THEME.button.white,
		Image = FFGEnum.THEME.button.white,
		HoverImage = FFGEnum.THEME.button.white,
		ResampleMode = Enum.ResamplerMode.Pixelated,
		ImageColor3 = buttonColor,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		AnchorPoint = FFGEnum.THEME.alignment.anchor.bottom,
		Position = FFGEnum.THEME.alignment.position.bottom,
		Parent = mainContainer,
		Size = size,
		Activated = function(input)
			isOwned(true)
		end,
		MouseEnter = function()
			if sizeSpringDebounce then return end
			sizeSpringDebounce = true
			local size = buttonSize + UDim2.fromScale(0.01, 0.01)
			sizeSource(size)
		end,
		MouseLeave = function()
			sizeSource(buttonSize)
			sizeSpringDebounce = false
		end,
	})

	local buttonTxt = create("TextLabel")({
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextColor3 = FFGEnum.THEME.color.white,
		BackgroundTransparency = 1,
		TextScaled = true,
		Text = buttonText,
		Font = FFGEnum.THEME.font,
		Size = buyButton.Size + UDim2.fromScale(0, 0.5),
	})
	buttonTxt.Parent = buyButton
	-- //!SECTION

	-- //!SECTION

	-- //SECTION - UI List Layouts
	-- itemInfoContainer
	create("UIListLayout")({
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		FillDirection = Enum.FillDirection.Vertical,
		VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly,
		Parent = itemInfoContainer,
	})

	-- -- //!SECTION

	-- //SECTION - Effects
	effect(function()
		if isOwned() then
			buttonColor(FFGEnum.THEME.button.disabledColor)
			buttonText("Owned")

			buyButton.Active = false
			buyButton.Interactable = false
			buttonTxt.TextColor3 = FFGEnum.THEME.intent.disabled
		end
	end)
	-- //!SECTION

	return shopTooltipContainer
end

return ShopTooltip
