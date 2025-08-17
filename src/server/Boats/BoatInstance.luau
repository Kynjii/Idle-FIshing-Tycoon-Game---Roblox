local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
local Formulas = require(ServerScriptService.Server.Game.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local BOATEnum = FFGEnum.ATTRIBUTES.BOAT

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

local NAME = {
	[1] = "Driftwood Skiff",
	[2] = "Netting Dory",
	[3] = "Herring Lugger",
	[4] = "Tidecaller Canoe",
	[5] = "Seablessed Punt",
	[6] = "Knight's Hull",
	[7] = "Crimson Cutter",
	[8] = "Ironhook Galley",
	[9] = "Mariner’s Galleon",
	[10] = "Wyrmcatcher",
	[11] = "The Flynnrunner",
}

local STARTER_STATS: FFGTypes.BoatState = {
	[BOATEnum.Level] = 1,
	[BOATEnum.MaxLevel] = 100,
	[BOATEnum.Tier] = 1,
	[BOATEnum.Name] = NAME[1],
	[BOATEnum.isActive] = false,
	[BOATEnum.isPurchased] = false,
	[BOATEnum.UpgradeStage] = 1,
	[BOATEnum.CurrentMaxStorage] = 100,
	[BOATEnum.NextLvlMaxStorage] = 100,
	[BOATEnum.RealmLevel] = 1,
	[BOATEnum.BaseCost] = Formulas.BOAT.BaseCost,
	[BOATEnum.UpgradeCost] = 100,
	[BOATEnum.FPS] = 10,
	[BOATEnum.FishInStorage] = 0,
	[BOATEnum.StorageFull] = false,
}

local BoatInstance = {}
BoatInstance.__index = BoatInstance

function BoatInstance:Purchase()
	self[BOATEnum.isPurchased] = true
end

function BoatInstance:Upgrade()
	self[BOATEnum.Level] += 1
	self[BOATEnum.UpgradeCost] = self:CalculateUpgradeCost()
	self[BOATEnum.Name] = self:GetName()
	self[BOATEnum.CurrentMaxStorage] = self:CalculateMaxStorage()
end

function BoatInstance:CalculateBaseCost(): number
	local baseCost = Formulas.BOAT.BaseCost

	if baseCost <= 0 then
		FFGHelpers.PrintLog("Base Cost is either 0 or below, returning")
		return
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local realmMultiplier = math.pow(self[BOATEnum.RealmLevel], 2.25) -- scaling curve

	local cost = baseCost * tierMultiplier * realmMultiplier

	return cost
end

function BoatInstance:CalculateUpgradeCost(): number
	local baseCost = self[BOATEnum.BaseCost] or STARTER_STATS.BaseCost

	if baseCost <= 0 then
		FFGHelpers.PrintLog("Base cost is either 0 or below, returning")
		return
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]

	local realmMultiplier = math.pow(self[BOATEnum.RealmLevel], 2.25) -- scaling curve

	local growthRate = Formulas.BOAT.GrowthRate

	local cost = baseCost * math.pow(growthRate, self[BOATEnum.Level]) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

-- //SECTION - Handles State updates for the boat
function BoatInstance:GetName(): string
	return NAME[self[BOATEnum.UpgradeStage]]
end

-- BOAT.UpdateLevel = function(player: Player, primaryPart: Part, currentState: FFGTypes.BoatState?)
-- 	primaryPart:SetAttribute(BOATEnum.Level, currentState.Level)
-- 	DataManager.UpdateBoatState(player, BOATEnum.Level, currentState.Level)

-- 	-- do and set max storage calcs
-- 	local current, nextValue = BOAT.GetMaxStorage(currentState.Level, currentState.Tier, currentState.RealmLevel)
-- 	if current and nextValue then
-- 		primaryPart:SetAttribute(BOATEnum.CurrentMaxStorage, current)
-- 		DataManager.UpdateBoatState(player, BOATEnum.CurrentMaxStorage, current)

-- 		primaryPart:SetAttribute(BOATEnum.NextLvlMaxStorage, nextValue)
-- 		DataManager.UpdateBoatState(player, BOATEnum.NextLvlMaxStorage, nextValue)
-- 	end

-- 	-- do and set upgrade cost calcs
-- 	local value = BOAT.GetUpgradeCost(currentState.Level, currentState.Tier, currentState.RealmLevel, currentState.BaseCost)
-- 	if value then
-- 		primaryPart:SetAttribute(BOATEnum.UpgradeCost, value)
-- 		DataManager.UpdateBoatState(player, BOATEnum.UpgradeCost, value)
-- 	else
-- 		FFGHelpers.PrintLog("No value found for upgradeCost", value)
-- 	end
-- end

-- BOAT.UpdatePurchasedState = function(player: Player, primaryPart: Part, state: BoolValue)
-- 	primaryPart:SetAttribute(BOATEnum.isPurchased, state)
-- 	DataManager.UpdateBoatState(player, BOATEnum.isPurchased, state)
-- end

-- BOAT.UpdateActiveState = function(player: Player, primaryPart: Part, state: BoolValue)
-- 	primaryPart:SetAttribute(BOATEnum.isActive, state)
-- 	DataManager.UpdateBoatState(player, BOATEnum.isActive, state)
-- end

-- BOAT.AddOwner = function(player: Player, primaryPart: Part)
-- 	primaryPart:SetAttribute(BOATEnum.Owner, player.UserId)
-- 	DataManager.UpdateBoatState(player, BOATEnum.Owner, player.UserId)
-- end

-- BOAT.IncreaseUpgradeStage = function(player: Player, primaryPart: Part, newStage: number)
-- 	primaryPart:SetAttribute(BOATEnum.UpgradeStage, newStage)
-- 	DataManager.UpdateBoatState(player, BOATEnum.UpgradeStage, newStage)
-- end

-- BOAT.UpdateFishingState = function(primaryPart: Part, isActive: boolean)
-- 	if isActive then
-- 		BOAT.StartFishing(primaryPart)
-- 	else
-- 		BOAT.StopFishing(primaryPart)
-- 	end
-- end
-- //!SECTION

-- //SECTION - (De)Serialization
function BoatInstance:serialize()
	return {
		id = self.id,
		ownerId = self.ownerId,
		level = self.level,
		tier = self.tier,
		isPurchased = self.isPurchased,
		upgradeCost = self.upgradeCost,
	}
end

function BoatInstance:fromSerializedData(data: FFGTypes.BoatState, boatModel: Model)
	local instance = setmetatable({}, BoatInstance)

	-- Restore the data
	instance.id = data.id
	instance.ownerId = data.ownerId
	instance.level = data.level
	instance.tier = data.tier
	instance.isPurchased = data.isPurchased
	instance.upgradeCost = data.upgradeCost

	-- Re-attach runtime-only stuff
	instance.model = boatModel
	instance.primaryPart = boatModel.PrimaryPart

	return instance
end
-- //!SECTION

-- //SECTION - Boat  Utilities
function BoatInstance:IsStorageFull()
	return self[BOATEnum.StorageFull]
end

function BoatInstance:Show(boat: Model)
	local boatParts = boat
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function BoatInstance:CanCollide(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function BoatInstance:CannotCollide(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end

function BoatInstance:Hide(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

function BoatInstance:ResetBoat(boat: Model, player: Player)
	local primaryPart = boat.PrimaryPart

	local attributes = FFGDefaults.BOAT_STARTING_ATT

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end

	FFGHelpers.PrintLog("Reset Attributes completed: ", primaryPart:GetAttributes())
end
-- //!SECTION

function BoatInstance:New(state: FFGTypes.BoatState, ownerId, model)
	local instance = setmetatable({}, BoatInstance)

	instance[BOATEnum.Id] = state.Id or HttpService:GenerateGUID(false)
	instance[BOATEnum.Owner] = state.Owner or ownerId
	instance[BOATEnum.Level] = state.Level or STARTER_STATS.Level
	instance[BOATEnum.MaxLevel] = state.MaxLevel or STARTER_STATS.MaxLevel
	instance[BOATEnum.Tier] = state.Tier or STARTER_STATS.Tier
	instance[BOATEnum.Name] = state.Name or STARTER_STATS.Name
	instance[BOATEnum.BoatModel] = model
	instance[BOATEnum.BaseCost] = instance:CalculateBaseCost() or STARTER_STATS.BaseCost
	instance[BOATEnum.UpgradeCost] = instance:CalculateUpgradeCost() or STARTER_STATS.UpgradeCost

	return instance
end

return BoatInstance
