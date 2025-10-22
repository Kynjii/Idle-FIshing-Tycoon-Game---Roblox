local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)

local props = {
	BackgroundColor3 = FFGEnum.THEME.shop.shopItem.bgColor,
	BackgroundTransparency = 0,
	HoverEffect = true,
	Visible = true,
}

local function story(target)
	local item = ShopItem({
		ItemImage = "rbxassetid://135112095865386",
		BackgroundColor3 = props.BackgroundColor3,
		BackgroundTransparency = props.BackgroundTransparency,
		Size = UDim2.fromOffset(100, 100),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		HoverEffect = props.HoverEffect,
		Visible = props.Visible,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		ItemPrice = "1.1k",
		ItemName = "hammer_01",
		ItemId = "Hammer",
		ItemDescription = "",
		Parent = target,
		ShopInstance = target,
	})

	return function()
		item:Destroy()
	end
end

return story
