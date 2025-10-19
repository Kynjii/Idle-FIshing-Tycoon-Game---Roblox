local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local GetColor3 = require(ReplicatedStorage.Shared.Utils.GetColor3)

-- //SECTION -  Vide functions
local create = vide.create
local source = vide.source
local effect = vide.effect
local spring = vide.spring
-- //!SECTION

local getColor = GetColor3

local function TextButton(
	props: {
		Text: string,
		TextColor3: Color3?,
		BackgroundColor3: Color3? | (() -> Color3)?,
		BackgroundTransparency: number?,
		Size: UDim2,
		AnchorPoint: Vector2?,
		Position: UDim2?, -- default to {.5 .5}
		Rounded: UDim?, -- defines a size
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
		BackgroundColor3 = getColor(props.BackgroundColor3, FFGEnum.THEME.color.white),
		BackgroundTransparency = props.BackgroundTransparency or (props.BackgroundColor3 and 0 or 1),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		TextColor3 = props.TextColor3 or FFGEnum.THEME.color.black,
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
			textButton.BackgroundColor3 = getColor(props.BackgroundColor3, FFGEnum.THEME.color.white)
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
