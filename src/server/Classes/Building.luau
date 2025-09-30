local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Building Types
type Building = BuildingType.Building
type BuildingProps = BuildingType.BuildingProps
type BuildingInstance = BuildingType.BuildingInstance
-- //!SECTION

-- //SECTION - Building Data
local NAME = {
	Market = {
		[1] = "Fish Stall",
		[2] = "Fish Cart",
		[3] = "Fishmonger’s Hut",
		[4] = "Wharf Stand",
		[5] = "Harbor Market",
		[6] = "Fisher’s Pavilion",
		[7] = "Dockside Bazaar",
		[8] = "Seafarer’s Market Hall",
		[9] = "Maritime Exchange",
		[10] = "Grand Harbor Market",
		[11] = "Oceanfront City Market",
	},
	BoatStorageUpgrader = {
		[1] = "Wooden Crates",
		[2] = "Carpenter’s Shack",
		[3] = "Timber Workshop",
		[4] = "Dockside Workshop",
		[5] = "Shipwright’s Lodge",
		[6] = "Pier Workshop",
		[7] = "Drydock Hall",
		[8] = "Harbor Shipyard",
		[9] = "Great Shipwright’s Yard",
		[10] = "Maritime Dockworks",
		[11] = "Royal Shipyard",
	},
	BoatFPSUpgrader = {
		[1] = "Fishing Nets",
		[2] = "Rope Weaver’s Corner",
		[3] = "Netting Shed",
		[4] = "Spinner’s Workshop",
		[5] = "Tangle Hall",
		[6] = "Knotcrafter’s Den",
		[7] = "Weaver’s Guildhouse",
		[8] = "Fisher’s Loom Hall",
		[9] = "Maritime Net Guild",
		[10] = "Grand Loomworks",
		[11] = "Oceanic Guild of Nets",
	},
	TenderTTUpgrader = {
		[1] = "Dockside Map Table",
		[2] = "Wayfinder’s Stand",
		[3] = "Courier’s Hut",
		[4] = "Pilot’s Booth",
		[5] = "Quay Relay Shed",
		[6] = "Harbor Waystation",
		[7] = "Lighthouse Signal House",
		[8] = "Port Dispatch Guild",
		[9] = "Chartmaker’s Hall",
		[10] = "Grand Pilotage Office",
		[11] = "Royal Admiralty Relay",
	},
	TenderLoadUpgrader = {
		[1] = "Dockside Pulley",
		[2] = "Porter’s Table",
		[3] = "Stevedore’s Stall",
		[4] = "Hoistman’s Shed",
		[5] = "Capstan House",
		[6] = "Winchwright’s Workshop",
		[7] = "Block-and-Tackle Hall",
		[8] = "Wharf Loading Yard",
		[9] = "Porters’ Guildhall",
		[10] = "Grand Hoistworks",
		[11] = "Royal Cargo Works",
	},
	TenderStorageUpgrader = {
		[1] = "Fish Baskets",
		[2] = "Fish Crate Pile",
		[3] = "Cold Cellar",
		[4] = "Timber Storehouse",
		[5] = "Stone Granary",
		[6] = "Dockside Warehouse",
		[7] = "Harbor Strongroom",
		[8] = "Seafarer’s Vault",
		[9] = "Maritime Storehall",
		[10] = "Grand Harbor Depot",
		[11] = "Royal Maritime Vault",
	},
	PortStorageUpgrader = {
		[1] = "Fish Barrels",
		[2] = "Cargo Shed",
		[3] = "Timber Warehouse",
		[4] = "Stone Storehouse",
		[5] = "Harbor Granary",
		[6] = "Dockside Depot",
		[7] = "Maritime Warehouse",
		[8] = "Harbor Stronghold",
		[9] = "Port Granary Hall",
		[10] = "Grand Maritime Depot",
		[11] = "Royal Port Storehouse",
	},
}

local DESCRIPTION = {
	Market = "Increases the value of Fish",
	BoatStorageUpgrader = "Increases Boat Storage",
	BoatFPSUpgrader = "Increases FPS",
	TenderTTUpgrader = "Increases Travel Time for your Tender",
	TenderLoadUpgrader = "Increases Load Times for your Tender",
	TenderStorageUpgrader = "Increases Tender Storage",
	PortStorageUpgrader = "Increases Port Storage",
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

local DEFAULTS: BuildingProps = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Building,
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Building",
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.BUILDING.BaseCost,
	isPurchased = false,
	UpgradeStage = 1,
}
-- //!SECTION

local Building = {} :: BuildingInstance
Building.__index = Building

-- //SECTION - Constructor
function Building.New(state, player: Player, model: Model, realmBuffs: { [string]: number }): Building
	local self: BuildingInstance = setmetatable({}, Building)

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
	self.VisualRoot = DeepWait(model, "Building", "VisualRoot")
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
	self.BuildingBuff.CurrentValue = self.isPurchased and Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff) or nil

	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()

	self:AttachEventListeners()

	self._cleaner = CleanerService.new()

	self.Upgraded = self._cleaner:add(Signal.new())
	self.Purchased = self._cleaner:add(Signal.new())

	self:UpdateVisualModel()

	return self
end
-- //!SECTION

-- //SECTION - Core Building Actions
function Building:Purchase()
	self.isPurchased = true
	self.BuildingBuff.CurrentValue = Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff)

	self:UpdateVisualModel()
	self:Save()

	self.Purchased:Fire(self)
end

function Building:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			self:UpdateVisualModel()
			break
		end
	end
	self:UpdateBuffValue()

	self:Save()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self:UpdatePurchaseBoardUI()
	self.Upgraded:Fire(self)
end

function Building:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Building:CalculateBaseCost()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Building:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end
-- //!SECTION

-- //SECTION - UI Setup
function Building:Initialize()
	-- Handle visibility based on purchase status
	if not self.isPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	-- Setup UI components
	if self.PurchaseBoard then self:SetupProximityPrompt(self.PurchaseBoard) end

	self:Save()
end

function Building:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	return PurchaseBoard.CreatePB(purchaseBoard, self)
end

function Building:UpdatePurchaseBoardUI()
	PurchaseBoard.UpdatePB(self)
end

function Building:SetupProximityPrompt(purchaseBoard: Part)
	local proximityPrompt: ProximityPrompt = self._cleaner:add(Instance.new("ProximityPrompt", purchaseBoard))

	ProximityPrompt.CreatePP(proximityPrompt, self)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Building:Show()
	ClassVisualizer.Show(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:Hide()
	ClassVisualizer.Hide(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:CanCollide()
	ClassVisualizer.CanCollide(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.Building.VisualRoot:GetChildren()[1])
end
-- //!SECTION

-- //SECTION - Buffs
function Building:UpdateBuffValue()
	self.BuildingBuff.CurrentValue = Buffs.CalculateLevelBuffValue(self.UpgradeStage, self.Level, self.BuildingBuff)
end
-- //!SECTION

-- //SECTION - Event Listeners
function Building:AttachEventListeners()
	EventListeners.Attach(self)
end
-- //!SECTION

-- //SECTION -  Building Utilities
function Building:GetName()
	return NAME[self.BuildingName][self.UpgradeStage]
end

function Building:CanUpgrade()
	return self.Level < self.MaxLevel
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Building:Serialize()
	return {
		Entity = self.Entity,
		Description = self.Description,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
		Tier = self.Tier,
		Name = self.Name,
		Level = self.Level,
		MaxLevel = self.MaxLevel,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		isPurchased = self.isPurchased,
		UpgradeStage = self.UpgradeStage,
		BuildingId = self.BuildingId,
		BuildingName = self.BuildingName,
	}
end

function Building:Save()
	if self.isPurchased then DataService.SaveBuffState(self.Player, self.BuildingBuff) end

	DataService.SaveBuildingState(self.Player, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Building:GetVisualModels()
	local modelsFolder = DeepWait(game.Workspace, "Buildings", "VisualStages", self.BuildingName)
	local models = modelsFolder:GetChildren()

	local templateModels: { [number]: Model } = {}
	for i, model in ipairs(models) do
		templateModels[tonumber(model.Name)] = model
	end

	return templateModels
end

function Building:RemovePreviousVisualModel()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Building:UpdateVisualModel()
	self:RemovePreviousVisualModel()

	local templateModel = self.VisualModels[self.UpgradeStage]
	local updatedModel = templateModel:Clone()

	updatedModel.Name = templateModel.Name .. "_Clone"
	updatedModel.Parent = self.VisualRoot
	updatedModel:PivotTo(self.VisualRoot.CFrame)

	for _, part in pairs(updatedModel:GetChildren()) do
		if part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Parent = part
			weld.Part0 = part
			weld.Part1 = self.VisualRoot
			part.Anchored = false

			if self.isPurchased then FadeEffect.In(part) end
		end
	end

	self.CurrentVisualModel = updatedModel
end
-- //!SECTION

-- //SECTION - Cleanup
function Building:ClearAllAttributes(instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Building:Destroy()
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	self:ClearAllAttributes(self.Model.PrimaryPart)

	if self._cleaner then
		self._cleaner:clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Model = nil
end
-- //!SECTION

return Building
