local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

-- //SECTION -  Vide functions
local create = vide.create
local source = vide.source
local effect = vide.effect
local spring = vide.spring
-- //!SECTION

local function TextButton(
	props: {
		Text: string,
		TextColor: Color3?,
		BGColor: Color3?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?, -- defines a size
		BackgroundTransparency: number?,
		HoverStyle: string?,
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

	local textButton = create("TextButton")({
		BackgroundColor3 = props.BGColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = props.BackgroundTransparency or props.BGColor and 0 or 1,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		TextColor3 = props.TextColor or Color3.fromRGB(0, 0, 0),
		Size = size,
		Visible = props.Visible or true,
		Text = props.Text,
		Font = FFGEnum.THEME.font,
		TextScaled = true,

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
			textButton.Active = false
			textButton.Interactable = false
			textButton.BackgroundColor3 = FFGEnum.THEME.intent.muted
		else
			textButton.Active = true
			textButton.Interactable = true
			textButton.BackgroundColor3 = props.BGColor or Color3.fromRGB(255, 255, 255)
		end
	end)

	if props.Rounded then
		local corner = create("UICorner")({
			CornerRadius = props.Rounded,
		})
		corner.Parent = textButton
	end

	return textButton
end

return TextButton
