local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local HelperCalculators = require(ServerScriptService.Server.Classes.Modules.HelperCalculators)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

-- //SECTION - Helper Data
local NAME = {
	Fishing = "Fisher", -- [Job]: Name
	Woodcutting = "Woodcutter",
	Mining = "Miner",
	Transport = "Hauler",
}

local helperFolder = game.Workspace:WaitForChild("Helpers")
local helperModel: Model
if helperFolder then
	helperModel = helperFolder:FindFirstChild("HelperTemplate")
	if not helperModel then error("Unable to locate the helperModel") end
end

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Helper,
	RealmId = 1,
	Name = "Unnamed Helper",
	Level = 1,
	MaxLevel = 100,
	UpgradeStage = 1,
	StorageFull = false,
	BaseCost = Formulas.HELPER.BaseCost,
	IsPurchased = false,
}

-- local ANIMATIONS = {
-- 	WaterBob = "WaterBob",
-- }
-- //!SECTION

local Helper = {}
Helper.__index = Helper

type Helper = typeof(setmetatable({} :: HelperType.HelperData, Helper))

-- //SECTION - Helpers for generating only stats for Shop
local function chooseJob()
	local jobs = {}

	local index = 1
	for k, v in pairs(FFGEnum.JOB_CATEGORY) do
		jobs[index] = v
		index += 1
	end

	return jobs[math.random(1, #jobs)]
end

local function grabName(jobCategory)
	return NAME[jobCategory]
end

local function chooseQuality()
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

local function generateStats(jobCategory, level, qualityId)
	return HelperCalculators.CalculateStats(jobCategory, level, qualityId)
end
-- //!SECTION

-- //SECTION - Constructor
function Helper.New(state: HelperType.HelperData, player: Player, teamId: number): Helper
	local self = setmetatable({} :: HelperType.HelperData, Helper)

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
	self.Entity = state.Entity or self.Entity or DEFAULTS.Entity
	self.Player = player
	self.RealmId = state.RealmId
	self.Owner = state.Owner or self.Owner or player.UserId
	self.Model = state.IsPurchased and (helperModel and helperModel:Clone())
	self.Id = state.Id
	self.TeamId = teamId
	self.JobCategory = state.JobCategory
	self.ItemImage = state.ItemImage
	self.Name = self:GetName()

	-- Define quality first
	self.QualityId = state.QualityId
	self.Quality = FFGEnum.QUALITIES[self.QualityId]

	-- Calculate default stats based on quality and job
	self.Stats = state.Stats or generateStats(self.JobCategory, self.Level, self.QualityId)
	self.BaseCost = state.BaseCost or ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.QualityId, self.RealmId)
	self.UpgradeCost = state.UpgradeCost or ClassCalculators.CalculateUpgradeCost(self.BaseCost, self.Level, self.QualityId, self.RealmId)

	self.CurrentAssignment = state.CurrentAssignment

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Static to generate data for shops
function Helper.CreateStateData(player: Player, currencyType: string)
	local state = {} :: HelperType.HelperData

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		state[key] = value
	end

	-- Calculate derived properties
	state.Player = player
	state.Owner = player.UserId
	state.Id = HttpService:GenerateGUID(false)
	state.JobCategory = chooseJob()
	state.Name = grabName(state.JobCategory)
	state.CurrencyType = currencyType

	-- Define quality first
	state.QualityId = chooseQuality()
	state.Quality = FFGEnum.QUALITIES[state.QualityId]

	-- Get correct image
	state.ItemImage = FFGEnum.JOB_ASSETS[state.JobCategory]

	-- Calculate default stats based on quality and job
	state.Stats = generateStats(state.JobCategory, 1, state.QualityId)
	state.BaseCost = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, state.QualityId, state.RealmId)
	state.UpgradeCost = ClassCalculators.CalculateUpgradeCost(state.BaseCost, state.Level, state.QualityId, state.RealmId)

	state.IsPurchased = false

	state.CurrentAssignment = FFGEnum.JOB_ASSIGNMENTS.NotOwned

	return state
end
-- //!SECTION

-- //SECTION - Assignments
function Helper.GetAssignments()
	return
end
-- //!SECTION

-- //SECTION - Core Helper Actions
function Helper.Purchase(self: Helper & HelperType.HelperData): ()
	self.IsPurchased = true
	self.Model = self._cleaner and self._cleaner:Add(helperModel and helperModel:Clone())
	self.CurrentAssignment = FFGEnum.JOB_ASSIGNMENTS.Unassigned

	self:Save()

	if self.Tier == 1 then Tutorial.Update(self.Player, self.TeamId) end
end

function Helper.Upgrade(self: Helper & HelperType.HelperData): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then self:IncreaseUpgradeStage(stage) end

	self.Stats = self:CalculateStats()

	self:Save()
end

function Helper.IncreaseUpgradeStage(self: Helper & HelperType.HelperData, stage: number): ()
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Helper.GenerateJobCategory(self: Helper & HelperType.HelperData): number
	return chooseJob()
end

function Helper.CalculateStats(self: Helper & HelperType.HelperData)
	return generateStats(self.JobCategory, self.Level, self.QualityId)
end

function Helper.DefineQuality(self: Helper & HelperType.HelperData): number?
	return chooseQuality()
end
-- //!SECTION

-- //SECTION - Handling Resources
function Helper.AddResource(self: Helper & HelperType.HelperData, amount: number): ()
	local availableStorage = (self.Stats and self.Stats.Storage) - self.ResourceInStorage
	local calcAmount = math.min(availableStorage, amount)

	self.ResourceInStorage += calcAmount

	if self.ResourceInStorage >= self.Stats and self.Stats.Storage then
		self.ResourceInStorage = self.Stats and self.Stats.Storage
		self:UpdateStorageStatus(true)
	end

	self:Save()
end

function Helper.RemoveResource(self: Helper & HelperType.HelperData, amount: number): ()
	self.ResourceInStorage -= amount
	self:UpdateStorageStatus(false)
	self:Save()
end

function Helper.UpdateStorageStatus(self: Helper & HelperType.HelperData, status: boolean): ()
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - Setup
function Helper.Initialize(self: Helper & HelperType.HelperData): ()
	self:Show()
	self:CanCollide()
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Helper.Show(self: Helper & HelperType.HelperData): ()
	ClassVisualizer.Show(self.VisualRoot)
end

function Helper.Hide(self: Helper & HelperType.HelperData): ()
	ClassVisualizer.Hide(self.VisualRoot)
end

function Helper.CanCollide(self: Helper & HelperType.HelperData): ()
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Helper.CannotCollide(self: Helper & HelperType.HelperData): ()
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION -  Helper Utilities
function Helper.GetName(self: Helper & HelperType.HelperData): string
	return NAME[self.JobCategory]
end

function Helper.CanUpgrade(self: Helper & HelperType.HelperData): boolean
	return self.Level < self.MaxLevel
end

function Helper.IsStorageFull(self: Helper & HelperType.HelperData): boolean
	local status = self.ResourceInStorage == self.Stats and self.Stats.Storage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Helper.Serialize(self: Helper & HelperType.HelperData): HelperType.HelperData
	return {
		Entity = self.Entity,
		Id = self.Id,
		RealmId = self.RealmId,
		Owner = self.Owner,
		Name = self.Name,
		Level = self.Level,
		MaxLevel = self.MaxLevel,
		CurrencyType = self.CurrencyType,
		ItemImage = self.ItemImage,
		JobCategory = self.JobCategory,
		QualityId = self.QualityId,
		Stats = self.Stats,
		UpgradeStage = self.UpgradeStage,
		ResourceInStorage = self.ResourceInStorage,
		StorageFull = self.StorageFull,
		CurrentAssignment = self.CurrentAssignment,
		IsPurchased = self.IsPurchased,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
	}
end

function Helper.Save(self: Helper & HelperType.HelperData): ()
	if self.IsTutorialHelper then
		DataService.SaveTutorialHelper(self.Player, self:Serialize())
	else
		DataService.SaveHelper(self.Player, self:Serialize())
	end
end
-- //!SECTION

-- //SECTION - Event Listeners
function Helper.AttachEventListeners(self: Helper & HelperType.HelperData)
	-- //TODO -
	-- EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function Helper.Destroy(self: Helper & HelperType.HelperData)
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
