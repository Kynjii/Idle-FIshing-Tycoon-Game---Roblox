local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UILabs = require(ReplicatedStorage.Packages.uilabs)
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CreateVideStory = UILabs.CreateVideStory

local button = require(ReplicatedStorage.Shared.UI.Components.Buttons.ImageButton)

local isDisabled = vide.source(false)

-- UI Sounds
local clicks = {}
local index = 1
for _, track in pairs(FFGEnum.THEME.sounds.clicks) do
	clicks[index] = track
	index += 1
end

-- UILab controls
local controls = {
	Visible = true,
	Text = UILabs.String("Purchase"),
	Disabled = isDisabled(),
}

local story = CreateVideStory({
	vide = vide,
	controls = controls,
}, function(props)
	vide.cleanup(function()
		print("Story is getting unmounted")
	end)

	return button({
		Size = UDim2.fromScale(0.5, 0.3),
		ImageAsset = FFGEnum.THEME.button.shopBuy,
		PressedAsset = FFGEnum.THEME.button.shopBuyHover,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		Position = UDim2.fromScale(0.5, 0.5),
		Text = props.controls.Text,
		Visible = props.controls.Visible,
		Disabled = props.controls.Disabled,
		Activated = function()
			local clickSound: Sound = clicks[math.random(1, #clicks)]
			if clickSound then clickSound:Play() end
		end,
	})
end)

return story
