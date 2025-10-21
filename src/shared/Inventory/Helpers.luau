export type Helper = {
	Id: string, -- stable key (e.g., "helper_1")
	Name: string, -- display
	CurrencyType: string,
	BaseCost: number,
	Tags: { string }?, -- optional: e.g., {"limited","new"}
}

local Catalog: { Helper } = {
	{ Id = "helper_1", Name = "Helper 1", BaseCost = 100, CurrencyType = "Gold" },
	{ Id = "helper_2", Name = "Helper 2", BaseCost = 200, CurrencyType = "Gold" },
	{ Id = "helper_3", Name = "Helper 3", BaseCost = 300, CurrencyType = "Gold" },
	{ Id = "helper_4", Name = "Helper 4", BaseCost = 400, CurrencyType = "Gold" },
	{ Id = "helper_5", Name = "Helper 5", BaseCost = 500, CurrencyType = "Gold" },
	{ Id = "helper_6", Name = "Helper 6", BaseCost = 600, CurrencyType = "Gold" },
}

table.freeze(Catalog)

return Catalog
