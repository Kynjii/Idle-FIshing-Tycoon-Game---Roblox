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
local NAME = FFGEnum.JOB_NAMES

local DESCRIPTION = {
	Fishing = "A crew member specialized in Fishing and transporting Fish.",
	Woodcutting = "A crew member specialized in Woodcutting and transporting Wood.",
	Mining = "A crew member specialized in Mining and transporting Ore.",
	Transporting = "A crew member specialized in Transporting Fish from the Port to the Market.",
}

local helperFolder: Instance = game.Workspace:WaitForChild("Helpers")
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

	local index: number = 1
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
		local totalWeight: number = 0
		for _, data in pairs(FFGEnum.QUALITIES) do
			totalWeight += data.DropChance
		end

		local randomValue: number = math.random() * totalWeight
		local cumulative: number = 0

		for qualityId, data in pairs(FFGEnum.QUALITIES) do
			cumulative += data.DropChance
			if randomValue <= cumulative then return qualityId end
		end

		return nil, nil
	end

	local qualityId: number = getRandomQuality()
	return qualityId
end

local function generateStats(jobCategory: string, level: number, qualityId: number?)
	return HelperCalculators.CalculateStats(jobCategory, level, qualityId)
end
-- //!SECTION

-- //SECTION - Constructor
function Helper.New(state: HelperType.HelperData, player: Player, teamId: number): Helper
	local self = setmetatable({} :: HelperType.HelperInstance, Helper)

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
	self.Description = state.Description or DESCRIPTION[self.JobCategory]

	-- Define quality first
	self.QualityId = state.QualityId
	self.Quality = FFGEnum.QUALITIES[self.QualityId]

	-- Calculate default stats based on quality and job
	self.Stats = state.Stats or generateStats(self.JobCategory, self.Level, self.QualityId) :: HelperType.HelperStats
	self.BaseCost = state.BaseCost or ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.QualityId, self.RealmId)
	self.UpgradeCost = state.UpgradeCost or ClassCalculators.CalculateUpgradeCost(self.BaseCost, self.Level, self.QualityId, self.RealmId)

	self.CurrentAssignment = state.CurrentAssignment

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Static to generate data for shops
function Helper.CreateStateData(player: Player, currencyType: string, existingState: HelperType.HelperData?)
	local state: HelperType.HelperData = {}

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		state[key] = value
	end

	-- used for tutorial helpers that come with some pre-defined stats
	if existingState then
		for key, value in pairs(existingState) do
			state[key] = value
		end
	end

	-- Calculate derived properties
	state.Player = state.Player or player
	state.Owner = state.Owner or player.UserId
	state.Id = state.Id or HttpService:GenerateGUID(false)
	state.JobCategory = state.JobCategory or chooseJob()
	state.Name = state.Name or grabName(state.JobCategory)
	state.CurrencyType = state.CurrencyType or currencyType
	state.Description = state.Description or DESCRIPTION[state.JobCategory]

	print(state.Description, DESCRIPTION, DESCRIPTION[state.JobCategory], state.JobCategory)

	-- Define quality first
	state.QualityId = state.QualityId or chooseQuality()
	state.Quality = FFGEnum.QUALITIES[state.QualityId]

	-- Get correct image
	state.ItemImage = state.ItemImage or FFGEnum.JOB_ASSETS[state.JobCategory]

	-- Calculate default stats based on quality and job
	state.Stats = state.Stats or generateStats(state.JobCategory, 1, state.QualityId)
	print(state.Stats)
	state.BaseCost = state.BaseCost or ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, state.QualityId, state.RealmId)
	state.UpgradeCost = state.UpgradeCost or ClassCalculators.CalculateUpgradeCost(state.BaseCost, state.Level, state.QualityId, state.RealmId)

	state.IsPurchased = state.IsPurchased or false

	state.CurrentAssignment = state.CurrentAssignment or FFGEnum.JOB_ASSIGNMENTS.NotOwned

	return state
end
-- //!SECTION

-- //SECTION - Assignments
function Helper.GetAssignments()
	return
end
-- //!SECTION

-- //SECTION - Core Helper Actions
function Helper.Purchase(self: Helper): ()
	self.IsPurchased = true
	self.Model = self._cleaner and self._cleaner:Add(helperModel and helperModel:Clone())
	self.CurrentAssignment = FFGEnum.JOB_ASSIGNMENTS.Unassigned

	self:Save()

	if self.Tier == 1 then Tutorial.Update(self.Player, self.TeamId) end
end

function Helper.Upgrade(self: Helper): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage: number = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then self:IncreaseUpgradeStage(stage) end

	self.Stats = self:CalculateStats()

	self:Save()
end

function Helper.IncreaseUpgradeStage(self: Helper, stage: number): ()
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Helper.GenerateJobCategory(self: Helper): number
	return chooseJob()
end

function Helper.CalculateStats(self: Helper)
	return generateStats(self.JobCategory, self.Level, self.QualityId)
end

function Helper.DefineQuality(self: Helper): number?
	return chooseQuality()
end
-- //!SECTION

-- //SECTION - Handling Resources
function Helper.AddResource(self: Helper, amount: number): ()
	local availableStorage = (self.Stats and self.Stats.Storage) - self.ResourceInStorage
	local calcAmount: number = math.min(availableStorage, amount)

	self.ResourceInStorage += calcAmount

	if self.ResourceInStorage >= (self.Stats and self.Stats.Storage) then
		self.ResourceInStorage = self.Stats and self.Stats.Storage
		self:UpdateStorageStatus(true)
	end

	self:Save()
end

function Helper.RemoveResource(self: Helper, amount: number): ()
	self.ResourceInStorage -= amount
	self:UpdateStorageStatus(false)
	self:Save()
end

function Helper.UpdateStorageStatus(self: Helper, status: boolean): ()
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - Setup
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
	return NAME[self.JobCategory]
end

function Helper.CanUpgrade(self: Helper): boolean
	return self.Level < self.MaxLevel
end

function Helper.IsStorageFull(self: Helper): boolean
	local status: boolean = self.ResourceInStorage == (self.Stats and self.Stats.Storage)
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Helper.Serialize(self: Helper): { [string]: any }
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
		Description = self.Description,
	}
end

function Helper.Save(self: Helper): ()
	if self.IsTutorialHelper then
		DataService.SaveTutorialHelper(self.Player, self:Serialize())
	else
		DataService.SaveHelper(self.Player, self:Serialize())
	end
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
