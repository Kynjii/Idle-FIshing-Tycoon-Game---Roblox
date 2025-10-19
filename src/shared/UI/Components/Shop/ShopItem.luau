local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

-- //SECTION -  Vide functions
local create = vide.create
local effect = vide.effect
local source = vide.source
local spring = vide.spring
-- //!SECTION

local function ShopItem(
	props: {
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?, -- defines a size
		BGColor: Color3?,
		BackgroundTransparency: number?,
		Visible: boolean?, -- defaulted to show if not passed
		Disabled: () -> boolean?, -- external source (vide.source())
		Purchased: () -> boolean?, -- external source (vide.source())
	}
)
	-- External source
	local isDisabled = props.Disabled
	local isPurchased = props.Purchased

	-- Animate source/variables
	local strokeThicknessSource = source(0)
	local strokeThickness = spring(strokeThicknessSource, 0.2)
	local springDebounce = false

	local shopContainer = create("Frame")({
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Size = props.Size,
		BackgroundColor3 = props.BGColor or "",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position,
		Visible = props.Visible,

		MouseEnter = function()
			if springDebounce then return end
			springDebounce = true
			strokeThicknessSource(2)
		end,
		MouseLeave = function()
			strokeThicknessSource(0)
			springDebounce = false
		end,
	})

	local containerStroke = create("UIStroke")({
		Color = FFGEnum.THEME.hoverStrokeColor,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = strokeThickness,
	})

	containerStroke.Parent = shopContainer

	-- effect(function()
	-- 	if isDisabled() then
	-- 		imageButton.Image = FFGEnum.THEME.button.shopBuyDisabled
	-- 		imageButton.Active = false
	-- 		imageButton.HoverImage = ""
	-- 		imageButton.PressedImage = ""
	-- 		imageButton.Interactable = false
	-- 	else
	-- 		imageButton.Image = props.ImageAsset or ""
	-- 		imageButton.Active = true
	-- 		imageButton.HoverImage = props.HoverAsset or ""
	-- 		imageButton.PressedImage = ""
	-- 		imageButton.Interactable = true
	-- 	end
	-- end)

	if props.Rounded then
		local corner = create("UICorner")({
			CornerRadius = props.Rounded,
		})
		corner.Parent = shopContainer
	end

	return shopContainer
end

return ShopItem
