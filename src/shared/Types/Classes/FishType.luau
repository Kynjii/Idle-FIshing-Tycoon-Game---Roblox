export type FishData = {
	Entity: string,
	Id: string,
	RealmId: number,
	TeamId: number,
	Owner: number,
	Name: string,
	NameKey: string,
	Species: string,
	SpeciesKey: string,
	Variant: "Normal" | "Elemental" | "Elder",
	QualityId: number,
	MaxHP: number,
	Weight: number,
	ItemImage: string,
	ElementNum: number?,
	ElementName: string?,
	Caught: boolean?,
}

local FishType: FishData = {}

return FishType
