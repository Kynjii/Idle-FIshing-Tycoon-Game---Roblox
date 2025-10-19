local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UILabs = require(ReplicatedStorage.Packages.uilabs)
local vide = require(ReplicatedStorage.Packages.vide)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CreateVideStory = UILabs.CreateVideStory

local button = require(ReplicatedStorage.Shared.UI.Components.Buttons.TextButton)

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
	TextColor3 = FFGEnum.THEME.color.white,
	Disabled = isDisabled(),
	BackgroundColor3 = FFGEnum.THEME.color.white,
}

local story = CreateVideStory({
	vide = vide,
	controls = controls,
}, function(props)
	vide.cleanup(function()
		print("Story is getting unmounted")
	end)

	return button({
		Text = props.controls.Text,
		TextColor3 = props.controls.TextColor3,
		BackgroundColor3 = props.controls.BackgroundColor3,
		Size = UDim2.fromScale(0.5, 0.3),
		Position = UDim2.fromScale(0.5, 0.5),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		Visible = props.controls.Visible,
		Disabled = props.controls.Disabled,
		Activated = function()
			local clickSound: Sound = clicks[math.random(1, #clicks)]
			if clickSound then clickSound:Play() end
		end,
	})
end)

return story
