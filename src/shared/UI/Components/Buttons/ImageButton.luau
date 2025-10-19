local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local GetColor3 = require(ReplicatedStorage.Shared.Utils.GetColor3)

-- //SECTION -  Vide functions
local create = vide.create
local effect = vide.effect
local source = vide.source
local spring = vide.spring
-- //!SECTION

local getColor = GetColor3

local function ImageButton(
	props: {
		ImageAsset: string,
		HoverAsset: string?,
		PressedAsset: string?,
		Text: string?,
		TextColor: Color3? | (() -> Color3)?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?, -- defines a size
		ScaleType: Enum?,
		SliceCenter: Rect?,
		BackgroundTransparency: number?,
		Visible: boolean?, -- defaulted to show if not passed
		Disabled: () -> boolean?, -- external source (vide.source())
		Activated: () -> (),
	}
)
	-- External source
	local isDisabled = props.Disabled

	-- Animate source/variables
	local sizeSource = source(props.Size)
	local size = spring(sizeSource, 0.2)
	local springDebounce = false

	local imageButton = create("ImageButton")({
		Image = props.ImageAsset or "",
		HoverImage = props.HoverAsset or "",
		PressedImage = props.PressedAsset or props.HoverAsset or "",
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Size = size,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position,
		ScaleType = props.ScaleType,
		SliceCenter = props.SliceCenter or Rect.new(50, 50, 37, 37),
		SliceScale = props.ImageAsset and 1,
		ResampleMode = Enum.ResamplerMode.Pixelated,
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
			imageButton.PressedImage = props.PressedAsset or props.HoverAsset or ""
			imageButton.Interactable = true
		end
	end)

	if props.Rounded then
		local corner = create("UICorner")({
			CornerRadius = props.Rounded,
		})
		corner.Parent = imageButton
	end

	if props.Text then create("TextLabel")({
		TextColor3 = getColor(props.TextColor, FFGEnum.THEME.color.black),
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

return ImageButton
