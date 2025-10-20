local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.vide)
local UILabs = require(ReplicatedStorage.Packages.uilabs)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CreateVideStory = UILabs.CreateVideStory

local Datatype = UILabs.Datatype

local shopTooltip = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopTooltip)

-- UILab controls
local controls = {
	BackgroundColor3 = Datatype.Color3(FFGEnum.THEME.shop.shopItem.bgColor), -- Color3 is inside "Datatype", this is to avoid name collisions
	Visible = UILabs.Boolean(true),
}

local story = CreateVideStory({
	vide = Vide,
	controls = controls,
}, function(props)
	Vide.cleanup(function()
		print("Story is getting unmounted")
	end)

	return shopTooltip({
		ItemImage = "rbxassetid://135112095865386",
		BackgroundColor3 = props.controls.BackgroundColor3,
		Size = UDim2.fromOffset(150, 300),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		Visible = props.controls.Visible,
		ItemCost = "1.2k",
		ItemName = "Flynn's Hammer",
		ItemDescription = "This hammer is the mightiest hammer in all of Fur Land.",
	})
end)

return story
