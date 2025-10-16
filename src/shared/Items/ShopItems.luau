local Category = {
	Helper = 1,
	Cosmetic = 2,
	Booster = 3,
}

export type ShopItem = {
	id: string, -- stable key (e.g., "helper_1")
	name: string, -- display
	currencyType: string,
	baseCost: number,
	category: number, -- Category.Helper, etc.
	tags: { string }?, -- optional: e.g., {"limited","new"}
}

local Catalog: { ShopItem } = {
	{ id = "helper_1", name = "Helper 1", baseCost = 100, currencyType = "Gold", category = Category.Helper },
	{ id = "helper_2", name = "Helper 2", baseCost = 200, currencyType = "Gold", category = Category.Helper },
	{ id = "booster_1", name = "Boost 1", baseCost = 10000, currencyType = "Gold", category = Category.Booster },
}

table.freeze(Catalog)

return Catalog
