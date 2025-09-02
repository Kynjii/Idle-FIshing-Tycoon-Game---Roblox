local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

-- //SECTION - TYPES
export type BoatProps = {
	Id: string,
	RealmId: number,
	Tier: number,
	Name: string,
	Level: number,
	MaxLevel: number,
	BaseCost: number,
	UpgradeCost: number,
	isPurchased: boolean,
	Owner: number,
	UpgradeStage: number,
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	StorageFull: boolean,
	FishInStorage: number,
	GrowthRate: number,
	CostGrowthRate: number,
}

export type BoatInstance = {
	-- Props
	Id: string,
	RealmId: number,
	Tier: number,
	Name: string,
	Level: number,
	MaxLevel: number,
	BaseCost: number,
	UpgradeCost: number,
	isPurchased: boolean,
	Owner: number,
	UpgradeStage: number,
	BaseStorage: number,
	CurrentMaxStorage: number,
	NextLvlMaxStorage: number,
	StorageFull: boolean,
	FishInStorage: number,
	GrowthRate: number,
	CostGrowthRate: number,

	-- Core boat actions
	Purchase: (self: BoatInstance) -> (),
	Upgrade: (self: BoatInstance) -> boolean,

	-- Calculations
	CalculateBaseCost: (self: BoatInstance) -> number,
	CalculateUpgradeCost: (self: BoatInstance) -> number,
	CalculateMaxStorage: (self: BoatInstance) -> (number, number),

	-- Handling Fish
	AddFish: (self: BoatInstance, amount: number) -> (),
	RemoveFish: (self: BoatInstance, amount: number) -> (),

	-- UI Setup
	Initialize: (self: BoatInstance) -> (),

	-- Visibility and Collision
	Hide: (self: BoatInstance) -> (),
	Show: (self: BoatInstance) -> (),
	CannotCollide: (self: BoatInstance) -> (),
	CanCollide: (self: BoatInstance) -> (),

	-- Utilities
	CanUpgrade: (self: BoatInstance) -> boolean,
	IncreaseUpgradeStage: (self: BoatInstance, stage: number) -> (),

	-- Saving and Loading
	Serialize: (self: BoatInstance) -> BoatProps,
}

export type Boat = {
	New: (props: BoatProps) -> BoatInstance,
}
-- //!SECTION

local Boat = {}
Boat.__index = Boat

local DEFAULTS: BoatProps = {
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Boat",
	Level = 1,
	MaxLevel = 100,
	isPurchased = false,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
	BaseCost = 100,
	BaseStorage = 90,
	GrowthRate = 1.1,
	CostGrowthRate = 1.1,
}

local BOAT_PROMOTION_LEVELS = {
	[1] = 1,
	[2] = 10,
	[3] = 20,
	[4] = 30,
	[5] = 40,
	[6] = 50,
	[7] = 60,
	[8] = 70,
	[9] = 80,
	[10] = 90,
	[11] = 100,
}

local function applyDefaults<T>(partial: { [string]: any }?, defaults: { [string]: any }): T
	local out = {}
	for k, v in pairs(defaults) do
		out[k] = v
	end
	for k, v in pairs(partial or {}) do
		out[k] = v
	end
	return (out :: any) :: T
end

-- //SECTION -  Constructor
function Boat.New(props: BoatProps): BoatInstance
	local merged = applyDefaults(props, DEFAULTS)

	merged.Id = merged.Id or HttpService:GenerateGUID(false)

	return setmetatable(merged, Boat) :: BoatInstance
end
-- //!SECTION

-- //SECTION -  Core boat actions
function Boat.Purchase(self: BoatInstance)
	self.isPurchased = true
end

function Boat.Upgrade(self: BoatInstance)
	if not self:CanUpgrade() then return false end

	self.Level += 1
	for k, v in ipairs(BOAT_PROMOTION_LEVELS) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			break
		end
	end
	self.UpgradeCost = self:CalculateUpgradeCost()
	if self.GetName then self.Name = self:GetName() end

	local currentMaxStorage: number, nextLvlMaxStorage: number = self:CalculateMaxStorage()
	self.CurrentMaxStorage = currentMaxStorage
	self.NextLvlMaxStorage = nextLvlMaxStorage

	return true
end
-- //!SECTION

-- //SECTION -  Calculations
function Boat.CalculateBaseCost(self: BoatInstance): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier] :: number
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local cost = baseCost * tierMultiplier * realmMultiplier

	return cost
end

function Boat.CalculateUpgradeCost(self: BoatInstance): number
	local baseCost = self:CalculateBaseCost()
	local growthRate = self.CostGrowthRate or DEFAULTS.CostGrowthRate
	local cost = baseCost * math.pow(growthRate, self.Level :: number)

	-- //TODO - handle boosts

	return cost
end

function Boat.CalculateMaxStorage(self: BoatInstance)
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	local growthRate = (self.GrowthRate or DEFAULTS.GrowthRate) + self.Tier * 0.02 :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier] :: number
	local maxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end
-- //!SECTION

-- //SECTION - Handling Fish
function Boat.AddFish(self: BoatInstance, amount: number)
	FFGHelpers.PrintLog("Adding Fish", amount)
	if self.StorageFull then
		FFGHelpers.PrintLog("Storage is full")
		return
	end

	self.FishInStorage += amount

	if self.FishInStorage > self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self.StorageFull = true
	end
end

function Boat.RemoveFish(self: BoatInstance, amount: number)
	self.FishInStorage = math.max(self.FishInStorage - amount, 0)

	self.StorageFull = false
end
-- //!SECTION

-- //SECTION - UI Setup
function Boat.Initialize(self: BoatInstance)
	if not self.isPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	-- Setup UI components
	local purchaseBoard = self:SetupPurchaseBoard()
	if purchaseBoard then self:SetupProximityPrompt(purchaseBoard) end
end
-- //!SECTION

-- Utilities
function Boat.CanUpgrade(self: BoatInstance): boolean
	return self.Level < self.MaxLevel
end

function Boat.IncreaseUpgradeStage(self: BoatInstance, stage: number)
	self.UpgradeStage = stage
end

-- //SECTION - Loading and Saving
function Boat.Serialize(self: BoatInstance): BoatProps
	return {
		Id = self.Id,
		RealmId = self.RealmId,
		Tier = self.Tier,
		Name = self.Name,
		Level = self.Level,
		MaxLevel = self.MaxLevel,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		isPurchased = self.isPurchased,
		Owner = self.Owner,
		UpgradeStage = self.UpgradeStage,
		BaseStorage = self.BaseStorage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		StorageFull = self.StorageFull,
		FishInStorage = self.FishInStorage,
		GrowthRate = self.GrowthRate,
		CostGrowthRate = self.CostGrowthRate,
	}
end
-- //!SECTION

return {
	New = Boat.New,
	Methods = Boat,
	BoatProps = nil :: any,
	BoatInstance = nil :: any,
}
