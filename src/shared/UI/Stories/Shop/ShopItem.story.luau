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
		ItemData = {
			BaseCost = 16000,
			CurrencyType = "Gold",
			CurrentAssignment = 0,
			Description = "A crew member specialized in Transporting Fish from the Port to the Market.",
			Entity = "Helper",
			Id = "50bf32f2-deae-4a0f-9420-9ec0e27a9d99",
			IsPurchased = true,
			ItemImage = "rbxassetid://135331905621652",
			JobCategory = "Transporting",
			Level = 1,
			MaxLevel = 100,
			Name = "Transporter",
			Owner = 8984765705,
			QualityId = 3,
			RealmId = 1,
			ResourceInStorage = 0,
			Stats = {
				FishValue = 0.1,
				LoadTime = 8,
				Storage = 62,
				WalkSpeed = 6,
			},
			StorageFull = true,
			TeamId = 1,
			UpgradeCost = 17280,
			UpgradeStage = 1,
		},
		Size = UDim2.fromOffset(150, 200),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		HoverEffect = props.HoverEffect,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(83, 83, 94, 105),
		Parent = target,
		ShopInstance = target,
	})

	return function()
		item:Destroy()
	end
end

return story
