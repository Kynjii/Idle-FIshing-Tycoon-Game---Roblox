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
		ImageAsset: string,
		HoverAsset: string?,
		Text: string?,
		TextColor: Color3?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: boolean?, -- only adds a corner if passed
		CornerRadius: number?,
		ScaleType: Enum?,
		SliceCenter: Rect?,
		BackgroundTransparency: number?,
		HoverStyle: string?,
		Visible: boolean?, -- defaulted to show if not passed
		Disabled: () -> boolean?, -- external source (vide.source())
		Purchased: () -> boolean?, -- external source (vide.source())
		Activated: () -> (),
	}
)
	-- External source
	local isDisabled = props.Disabled
	local isPurchased = props.Purchased

	-- Animate source/variables
	local sizeSource = source(props.Size)
	local size = spring(sizeSource, 0.2)
	local springDebounce = false

	local imageButton = create("Frame")({
		Image = props.ImageAsset or "",
		HoverImage = props.HoverAsset or "",
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Size = size,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position,
		ScaleType = props.ScaleType,
		SliceCenter = props.SliceCenter or Rect.new(50, 50, 37, 37),
		SliceScale = props.ImageAsset and 1,
		Visible = props.Visible,

		Activated = props.Activated,
		MouseEnter = function()
			if springDebounce then return end
			springDebounce = true
			local size = props.Size + UDim2.fromScale(0.01, 0.01)
			sizeSource(size)
		end,
		MouseLeave = function()
			local size = props.Size
			sizeSource(size)
			springDebounce = false
		end,
	})

	effect(function()
		if isDisabled() then
			imageButton.Image = FFGEnum.THEME.button.shopBuyDisabled
			imageButton.Active = false
			imageButton.HoverImage = ""
			imageButton.PressedImage = ""
			imageButton.Interactable = false
		else
			imageButton.Image = props.ImageAsset or ""
			imageButton.Active = true
			imageButton.HoverImage = props.HoverAsset or ""
			imageButton.PressedImage = ""
			imageButton.Interactable = true
		end
	end)

	if props.Rounded then
		local corner = create("UICorner")({
			CornerRadius = props.CornerRadius,
		})
		corner.Parent = imageButton
	end

	if props.Text then create("TextLabel")({
		TextColor3 = props.TextColor or Color3.fromRGB(255, 255, 255),
		Font = FFGEnum.THEME.font,
		Text = props.Text,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Parent = imageButton,
		Size = UDim2.fromScale(0.8, 0.9),
		TextScaled = true,
	}) end

	return imageButton
end

return ShopItem
