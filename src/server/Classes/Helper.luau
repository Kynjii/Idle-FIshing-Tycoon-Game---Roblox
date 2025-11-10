local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local HelperCalculators = require(ServerScriptService.Server.Classes.Modules.HelperCalculators)
local CollisionGroups = require(ServerScriptService.Server.Game.CollisionGroups.CollisionGroups)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local EntityNameplate = require(ServerScriptService.Server.Modules.EntityNameplate.EntityNameplate)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)

-- //SECTION - Helper Data
local NAME = FFGEnum.JOB_NAMES

local DESCRIPTION = {
	Fishing = "A crew member specialized in Fishing and transporting Fish.",
	Woodcutting = "A crew member specialized in Woodcutting and transporting Wood.",
	Mining = "A crew member specialized in Mining and transporting Ore.",
	Transporting = "A crew member specialized in Transporting Fish from the Port to the Market.",
}

local helperFolder: Instance = game.Workspace:WaitForChild("Helpers")
local helperModel
if helperFolder then
	helperModel = helperFolder:FindFirstChild("HelperTemplate") :: Model
	if not helperModel then error("Unable to locate the helperModel") end
end

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Helper,
	RealmId = 1,
	Name = "Unnamed Helper",
	Level = 1,
	MaxLevel = Formulas.MAX_LEVEL,
	UpgradeStage = 1,
	StorageFull = false,
	BaseCost = Formulas.HELPER.BaseCost,
	IsPurchased = false,
	ResourceInStorage = 0,
}
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
	local function getRandomQuality(): number?
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

		return nil
	end

	local qualityId: number? = getRandomQuality()
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
	self.Entity = state.Entity or DEFAULTS.Entity
	self.Player = player
	self.RealmId = state.RealmId
	self.Owner = state.Owner or self.Owner or player.UserId
	self.Model = nil
	self.Id = state.Id
	self.TeamId = teamId
	self.JobCategory = state.JobCategory
	self.ItemImage = state.ItemImage
	self.Name = self:GetName()
	self.Description = state.Description or DESCRIPTION[self.JobCategory]

	-- Define quality first
	self.QualityId = state.QualityId
	self.Quality = FFGEnum.QUALITIES[self.QualityId]

	self.ResourceType = state.ResourceType or FFGEnum.RESOURCE_TYPE[self.JobCategory]

	-- Calculate default stats based on quality and job
	self.Stats = state.Stats or generateStats(self.JobCategory, self.Level, self.QualityId) :: HelperType.HelperStats
	self.BaseCost = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.QualityId, self.RealmId)
	self.UpgradeCost = ClassCalculators.CalculateUpgradeCost(self.BaseCost, self.Level, self.QualityId, self.RealmId)

	self.CurrentAssignment = state.CurrentAssignment

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Static to generate data for shops
function Helper.CreateStateData(player: Player, currencyType: string)
	local state: HelperType.HelperData = {}

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		state[key] = value
	end

	-- Calculate derived properties
	state.Owner = state.Owner or player.UserId
	state.Id = state.Id or HttpService:GenerateGUID(false)
	state.JobCategory = state.JobCategory or chooseJob()
	state.Name = state.Name and state.Name ~= DEFAULTS.Name or grabName(state.JobCategory)
	state.CurrencyType = state.CurrencyType or currencyType
	state.Description = state.Description or DESCRIPTION[state.JobCategory]

	-- Define quality first
	state.QualityId = state.QualityId or chooseQuality()

	-- Get correct image
	state.ItemImage = state.ItemImage or FFGEnum.JOB_ASSETS[state.JobCategory]

	state.ResourceType = FFGEnum.RESOURCE_TYPE[state.JobCategory]

	-- Calculate default stats based on quality and job
	state.Stats = state.Stats or generateStats(state.JobCategory, 1, state.QualityId)
	state.BaseCost = state.BaseCost and state.BaseCost ~= DEFAULTS.BaseCost or ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, state.QualityId, state.RealmId)
	state.UpgradeCost = state.UpgradeCost or ClassCalculators.CalculateUpgradeCost(state.BaseCost, state.Level, state.QualityId, state.RealmId)

	state.IsPurchased = state.IsPurchased or false

	state.CurrentAssignment = state.CurrentAssignment or 0

	return state
end
-- //!SECTION

-- //SECTION - Assignments
function Helper.CanAssignJob(self: Helper, jobId: number): boolean
	local jobInfo = Jobs.Data[jobId]
	if not jobInfo then return false end

	return jobInfo.Category == self.JobCategory
end

function Helper.CreateModel(self: Helper)
	if self.Model then self.Model:Destroy() end
	local clonedModel = helperModel and helperModel:Clone()
	clonedModel.Name = `{self.Player}'s {self.Name} | Level {self.Level}`
	clonedModel.Parent = helperModel.Parent
	self.Model = self._cleaner and self._cleaner:Add(clonedModel)

	if clonedModel then
		local modelChildren = clonedModel:GetChildren()
		for _, part: Instance in pairs(modelChildren) do
			if part:IsA("MeshPart") or part:IsA("Part") then
				if part.Name ~= "HumanoidRootPart" then part.Transparency = 0 end
				part.Anchored = false
			end

			if part.Name == "Humanoid" then
				local humanoid: Humanoid = part
				humanoid.WalkSpeed = self.Stats and self.Stats.WalkSpeed
			end
		end

		local nameplate: BillboardGui = EntityNameplate.Create({
			EntityData = self,
			Adornee = clonedModel,
			HasProgressBar = false, -- //TODO -
		})
		nameplate.ExtentsOffsetWorldSpace = Vector3.new(0, 2, 0)
		nameplate.Enabled = true
		nameplate.Parent = clonedModel

		local hasProgressBar = nameplate:FindFirstChild("ProgressContainer")
		if not hasProgressBar then
			local progressContainer = ProgressBar.Create({ Color = "Blue", HasText = true, hasProgressBar = true, Adornee = nameplate })
			progressContainer.Size = UDim2.fromScale(1, 0.2)
			progressContainer.Position = UDim2.fromScale(0.5, 1)
			progressContainer.Parent = nameplate
			progressContainer.Visible = false
		end

		CollisionGroups.SetNpcCollisionGroup(clonedModel)
	end

	local startPos: Vector3 = Jobs.GetJobLocation(self.CurrentAssignment, self.TeamId)
	if startPos then
		self.Model:MoveTo(startPos)
		Events.FireBindableEvent(Events.BindableNames.HelperAtUnloadingLoc, { Id = self.Id, JobId = self.CurrentAssignment, Player = self.Player })
	end
end

function Helper.AssignJob(self: Helper, jobId: number, isNewJob: boolean): ()
	if jobId > 0 then
		if not self:CanAssignJob(jobId) then return end
	end

	if isNewJob then
		self.ResourceInStorage = 0
		self.CurrentAssignment = jobId
	end

	if self.CurrentAssignment > 0 then
		self:CreateModel()
	else
		if self.Model then self.Model:Destroy() end
	end

	self:Save()
end
-- //!SECTION

-- //SECTION - Core Helper Actions
function Helper.Purchase(self: Helper): ()
	self.IsPurchased = true

	self:Save()
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

function Helper.ClearStorage(self: Helper): ()
	self.ResourceInStorage = 0
	self:UpdateStorageStatus(true)
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

-- //SECTION - Event Listeners
function Helper.AttachEventListeners(self: Helper)
	local upgradeHelper = Events.GetRemote(Events.RemoteNames.UpgradeHelper)
	if upgradeHelper then
		self._cleaner:Add(upgradeHelper.OnServerEvent:Connect(function(player: Player, helperId: string)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if helperId ~= self.Id then return end

			if not DataService.CanAfford(self.Player, self.CurrencyType, self.BaseCost or 0) then
				-- //TODO - Send event to hud for a message
				return
			end
			DataService.Spend(self.Player, self.CurrencyType, self.BaseCost)

			self:Upgrade()
			local helperUpgradedEvent = Events.GetRemote(Events.RemoteNames.HelperUpgraded)
			if helperUpgradedEvent then helperUpgradedEvent:FireClient(player, self:Serialize()) end

			Events.FireBindableEvent(Events.BindableNames.HelperUpgraded, HttpService:JSONEncode(self:Serialize()))
		end))
	end
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Helper.Serialize(self: Helper): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		RealmId = self.RealmId,
		TeamId = self.TeamId,
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
	DataService.SaveHelper(self.Player, self:Serialize())
end
-- //!SECTION

-- //SECTION - Cleanup
function Helper.Destroy(self: Helper)
	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
end
-- //!SECTION

return Helper
