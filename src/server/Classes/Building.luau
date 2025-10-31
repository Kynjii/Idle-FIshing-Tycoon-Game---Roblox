local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local BuffType = require(ReplicatedStorage.Shared.Types.BuffType)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)

-- //SECTION - Building Types
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
type BuildingInstance = BuildingType.BuildingInstance
type BuildingData = BuildingType.BuildingData
-- //!SECTION

-- //SECTION - Building Data
local NAME = {
	Market = "Harbor Market",
	BoatStorageUpgrader = "Harbor Shipyard",
	BoatFPSUpgrader = "Fishing Nets",
	TenderTTUpgrader = "Transporter Workshop",
	TenderLoadUpgrader = "Transporter Shed",
	TenderStorageUpgrader = "Transporter Cellar",
	PortStorageUpgrader = "Storage Shed",
}

local DESCRIPTION = {
	Market = "Bustling with trade and salty gossip, your market boosts profits. \n\n- Increases the gold value of fish.",
	BoatStorageUpgrader = "Extra crates, sheds, and yards mean fewer wasted hauls. \n\n- Increases how much your boat can carry before unloading.",
	BoatFPSUpgrader = "Better nets and gear keep the fish flowing. \n\n- Increases your boat’s Fish Per Second (FPS).",
	TenderTTUpgrader = "Charts, signals, and waystations smooth every voyage. \n\n- Decreases your tender’s travel time.",
	TenderLoadUpgrader = "Hoists, pulleys, and strong arms at the dock. \n\n- Decreases your tender’s load/unload time.",
	TenderStorageUpgrader = "From baskets to vaults, there’s always room for more catch. \n\n- Increases your tender’s storage capacity.",
	PortStorageUpgrader = "The harbor swells with barrels, sheds, and warehouses. \n\n- Increases total port storage for fish and goods.",
}

local BUILDING_BUFFS = {
	Market = FFGEnum.BUFFS.FISH.Fish_Percent,
	BoatStorageUpgrader = FFGEnum.BUFFS.STORAGE.Boat_Percent,
	BoatFPSUpgrader = FFGEnum.BUFFS.FPS.FPS_Percent,
	TenderTTUpgrader = FFGEnum.BUFFS.TRAVEL_TIME.Tender_Percent,
	TenderLoadUpgrader = FFGEnum.BUFFS.LOAD_TIME.Tender_Percent,
	TenderStorageUpgrader = FFGEnum.BUFFS.STORAGE.Tender_Percent,
	PortStorageUpgrader = FFGEnum.BUFFS.STORAGE.Port_Percent,
}

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Building,
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Building",
	Level = 1,
	MaxLevel = Formulas.MAX_LEVEL,
	BaseCost = Formulas.BUILDING.BaseCost,
	IsPurchased = false,
	UpgradeStage = 1,
}
-- //!SECTION

local Building = {}
Building.__index = Building

-- Local type alias for internal method signatures
type Building = typeof(setmetatable({} :: BuildingData, Building))

-- //SECTION - Constructor
function Building.New(state: { [string]: any }?, player: Player, model: Model, realmBuffs: BuffType.BuffState): Building
	local self = setmetatable({} :: BuildingData, Building)

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
	self.Id = self.Id or HttpService:GenerateGUID(false)
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Entity = self.Entity or DEFAULTS.Entity
	self.VisualRoot = model:FindFirstChild("VisualRoot", true)
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.BuildingId = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.BuildingId)
	self.BuildingName = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.BuildingName)
	self.Description = DESCRIPTION[self.BuildingName]
	self.Name = self:GetName()
	self.Player = player

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	self.BuildingBuff = realmBuffs[BUILDING_BUFFS[self.BuildingName]]
	if not self.BuildingBuff.CurrentValue then self.BuildingBuff.CurrentValue = self.IsPurchased and Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff) or nil end

	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()

	self._cleaner = Trove.new()

	self.Upgraded = self._cleaner:Add(Signal.new())
	self.Purchased = self._cleaner:Add(Signal.new())

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Core Building Actions
function Building.Purchase(self: Building): ()
	self.IsPurchased = true
	if self.BuildingBuff then self.BuildingBuff.CurrentValue = Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff) end

	self:UpdateVisualModel()

	if self.Purchased then self.Purchased:Fire(self) end
	self:Save()
end

function Building.Upgrade(self: Building): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then
		self:IncreaseUpgradeStage(stage)
		self:UpdateVisualModel()
	end
	self:UpdateBuffValue()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self:UpdatePurchaseBoardUI()
	if self.Upgraded then self.Upgraded:Fire(self) end
	self:Save()
end

function Building.IncreaseUpgradeStage(self: Building, stage: number): ()
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Building.CalculateBaseCost(self: Building): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Building.CalculateUpgradeCost(self: Building): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level, self.Tier, self.RealmId)

	self.UpgradeCost = cost

	return cost
end
-- //!SECTION

-- //SECTION - UI Setup
function Building.Initialize(self: Building)
	-- Handle visibility based on purchase status
	if not self.IsPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	self:UpdateVisualModel()

	-- Setup UI components
	if self.PurchaseBoard then self:SetupProximityPrompt(self.PurchaseBoard) end

	self:Save()
end

function Building.SetupPurchaseBoard(self: Building): (Model, { [string]: any })
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board") :: Model
	return PurchaseBoard.CreatePB(purchaseBoard, self :: any)
end

function Building.UpdatePurchaseBoardUI(self: Building, reset: boolean?): ()
	if reset then
		PurchaseBoard.ResetPB(self.PurchaseBoard)
	else
		PurchaseBoard.UpdatePB(self :: any)
	end
end

function Building.SetupProximityPrompt(self: Building, purchaseBoard: Model): ()
	local proximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = purchaseBoard

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Building.Show(self: Building): ()
	ClassVisualizer.Show(self.VisualRoot)
end

function Building.Hide(self: Building): ()
	ClassVisualizer.Hide(self.VisualRoot)
end

function Building.CanCollide(self: Building): ()
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Building.CannotCollide(self: Building): ()
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION - Buffs
function Building.UpdateBuffValue(self: Building): ()
	if self.BuildingBuff then self.BuildingBuff.CurrentValue = Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff) end
end
-- //!SECTION

-- //SECTION - Event Listeners
function Building.AttachEventListeners(self: Building): ()
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION -  Building Utilities
function Building.GetName(self: Building): string
	return NAME[self.BuildingName]
end

function Building.CanUpgrade(self: Building): boolean
	return self.Level < self.MaxLevel
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Building.Serialize(self: Building): { [string]: any }
	return {
		Entity = self.Entity,
		Description = self.Description,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
		Tier = self.Tier,
		Name = self.Name,
		Level = self.Level,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		IsPurchased = self.IsPurchased,
		UpgradeStage = self.UpgradeStage,
		BuildingId = self.BuildingId,
		BuildingName = self.BuildingName,
	}
end

function Building.Save(self: Building): ()
	if self.IsPurchased then DataService.SaveBuffState(self.Player, self.BuildingBuff or nil) end

	DataService.SaveBuildingState(self.Player, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Building.GetVisualModels(self: Building): { [number]: Model }
	local modelsFolder = DeepWait(game.Workspace, "Buildings", "VisualStages", self.BuildingName)
	local models = modelsFolder:GetChildren()

	local sortedModels = {}
	for k, v in pairs(models) do
		sortedModels[tonumber(v.Name)] = v
	end

	return sortedModels
end

function Building.RemovePreviousVisualModel(self: Building): ()
	local visualModel = self.CurrentVisualModel :: Model
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Building.UpdateVisualModel(self: Building): ()
	self:RemovePreviousVisualModel()

	local templateModel = self.VisualModels and self.VisualModels[self.UpgradeStage]
	local updatedModel = templateModel:Clone() :: Model

	updatedModel.Name = templateModel.Name .. "_Clone"
	updatedModel.Parent = self.VisualRoot
	updatedModel:PivotTo(self.VisualRoot.CFrame)

	for _, part in pairs(updatedModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Parent = part
			weld.Part0 = part
			weld.Part1 = self.VisualRoot
			part.Anchored = false

			if self.IsPurchased then FadeEffect.In(part) end
		end
	end

	self.CurrentVisualModel = updatedModel
end
-- //!SECTION

-- //SECTION - Cleanup
function Building.ClearAllAttributes(self: Building, instance: Instance): ()
	for name, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Building.Destroy(self: Building): ()
	self:Hide()
	self:CannotCollide()
	self:RemovePreviousVisualModel()
	self:UpdatePurchaseBoardUI(true)

	pcall(function()
		self:Save()
	end)

	self:ClearAllAttributes(self.Model.PrimaryPart)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return Building
