local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

-- //SECTION - Boat Data
local NAME = {
	Fishing = "Fisher", -- [Job]: Name
	Woodcutting = "Woodcutter",
	Mining = "Miner",
	Transport = "Hauler",
}

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Helper,
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Helper",
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.BOAT.BaseCost,
	BaseStorage = Formulas.BOAT.BaseStorage,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
	BaseTravelTime = 10, -- secs
	BaseLoadTime = 10, -- secs
}

-- local ANIMATIONS = {
-- 	WaterBob = "WaterBob",
-- }
-- //!SECTION

local Helper = {}
Helper.__index = Helper

type Helper = typeof(setmetatable({}, Helper))

-- //SECTION - Constructor
function Helper.New(state: { [string]: any }?, player: Player, teamId: number): Helper
	local self = setmetatable({}, Helper)

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		self[key] = value
	end

	-- Override with provided state values
	if state then
		for key, value in pairs(state) do
			self[key] = value
		end
	end
	-- Calculate derived properties
	self.Entity = self.Entity or DEFAULTS.Entity
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.JobCategory = state and state.JobCategory or self:GenerateJobCategory()
	self.Name = self:GetName()

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.LoadTime = self:CalculateLoadTime()
	self.CurrentTravelTime = self:CalculateTravelTime()
	self.QualityId = state and state.QualityId or self:DefineQuality()
	self.Stats = state and state.Stats or self:GenerateStats()
	print("Stats:", self.Stats)

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Core Helper Actions
function Helper.Upgrade(self: Helper): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then self:IncreaseUpgradeStage(stage) end

	self.CurrentFPS, self.NextFPS = self:CalculateFPS()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Helper.IncreaseUpgradeStage(self: Helper, stage: number): ()
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Helper.CalculateBaseCost(self: Helper): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Helper.CalculateUpgradeCost(self: Helper): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level, self.Tier, self.RealmId)

	self.UpgradeCost = cost

	return cost
end

function Helper.CalculateBaseStorage(self: Helper): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Helper.CalculateMaxStorage(self: Helper): (number, number)
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level)
end

function Helper.CalculateTravelTime(self: Helper): number
	return ClassCalculators.CalculateTravelTime(DEFAULTS.BaseTravelTime, self.Level)
end

function Helper.CalculateLoadTime(self: Helper): number
	return ClassCalculators.CalculateLoadTime(DEFAULTS.BaseLoadTime, self.Level)
end
-- //!SECTION

-- //SECTION - Generators
function Helper.GenerateJobCategory(self: Helper): number
	local jobs = FFGEnum.JOBS
	return jobs[math.random(1, #jobs)]
end

function Helper.GenerateStats(self: Helper)
	--
end

function Helper.DefineQuality(self: Helper): number?
	local function getRandomQuality()
		local totalWeight = 0
		for _, data in pairs(FFGEnum.QUALITIES) do
			totalWeight += data.DropChance
		end

		local randomValue = math.random() * totalWeight
		local cumulative = 0

		for qualityId, data in pairs(FFGEnum.QUALITIES) do
			cumulative += data.DropChance
			if randomValue <= cumulative then return qualityId end
		end

		return nil, nil
	end

	local qualityId = getRandomQuality()
	return qualityId
end
-- //!SECTION

-- //SECTION - Handling Fish
function Helper.AddFish(self: Helper, amount: number): ()
	local availableStorage = self.CurrentMaxStorage - self.FishInStorage
	local calcAmount = math.min(availableStorage, amount)

	self.FishInStorage += calcAmount

	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:Save()
end

function Helper.RemoveFish(self: Helper, amount: number): ()
	self.FishInStorage -= amount
	self:UpdateStorageStatus(false)
	self:Save()
end

function Helper.UpdateStorageStatus(self: Helper, status: boolean): ()
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - UI Setup
function Helper.Initialize(self: Helper): ()
	self:Show()
	self:CanCollide()
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Helper.Show(self: Helper): ()
	ClassVisualizer.Show(self.VisualRoot)
end

function Helper.Hide(self: Helper): ()
	ClassVisualizer.Hide(self.VisualRoot)
end

function Helper.CanCollide(self: Helper): ()
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Helper.CannotCollide(self: Helper): ()
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION -  Helper Utilities
function Helper.GetName(self: Helper): string
	return NAME[self.CategoryFocus]
end

function Helper.CanUpgrade(self: Helper): boolean
	return self.Level < self.MaxLevel
end

function Helper.IsStorageFull(self: Helper): boolean
	local status = self.FishInStorage == self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Helper.Serialize(self: Helper): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
		Tier = self.Tier,
		Name = self.Name,
		Level = self.Level,
		QualityId = self.QualityId,
		MaxLevel = self.MaxLevel,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		BaseStorage = self.BaseStorage,
		UpgradeStage = self.UpgradeStage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
		CurrentTravelTime = self.CurrentTravelTime,
		LoadTime = self.LoadTime,
	}
end

function Helper.Save(self: Helper): ()
	-- //TODO -
	-- DataService.SaveBoatState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Event Listeners
function Helper.AttachEventListeners(self: Helper)
	-- //TODO -
	-- EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function Helper.Destroy(self: Helper)
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return Helper
