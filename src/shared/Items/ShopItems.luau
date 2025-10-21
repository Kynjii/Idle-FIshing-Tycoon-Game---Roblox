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
	jobCategory: number, -- Category.Helper, etc.
	tags: { string }?, -- optional: e.g., {"limited","new"}
}

local Catalog: { ShopItem } = {
	{ id = "helper_1", name = "Helper 1", baseCost = 100, currencyType = "Gold", jobCategory = Category.Helper },
	{ id = "helper_2", name = "Helper 2", baseCost = 200, currencyType = "Gold", jobCategory = Category.Helper },
	{ id = "helper_3", name = "Helper 3", baseCost = 300, currencyType = "Gold", jobCategory = Category.Helper },
	{ id = "helper_4", name = "Helper 4", baseCost = 400, currencyType = "Gold", jobCategory = Category.Helper },
	{ id = "helper_5", name = "Helper 5", baseCost = 500, currencyType = "Gold", jobCategory = Category.Helper },
	{ id = "helper_6", name = "Helper 6", baseCost = 600, currencyType = "Gold", jobCategory = Category.Helper },
}

table.freeze(Catalog)

return Catalog
