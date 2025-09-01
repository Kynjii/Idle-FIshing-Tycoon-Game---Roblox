local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local BOATEnum = FFGEnum.ATTRIBUTES.BOAT

export type BoatState = {
	Id: string,
	Level: number,
	Tier: number,
	RealmId: number,
	BaseCost: number,
	UpgradeCost: number?,
	isPurchased: boolean,
	Name: string?,
	Owner: number?,
	MaxLevel: number,
	UpgradeStage: number,
	CurrentMaxStorage: number?,
	NextLvlMaxStorage: number?,
	CurrentFPS: number?,
	NextFPS: number?,
	FishInStorage: number?,
	StorageFull: boolean,
	GrowthRate: number,
	CostGrowthRate: number,
	BaseFPS: number,
	BaseStorage: number,
}

export type BoatClass = BoatState & {
	-- Constructor
	New: (self: BoatClass, state: BoatState, ownerId: number, model: Model, currentrealm: number?) -> BoatClass,

	-- Core boat actions
	Purchase: (self: BoatClass) -> (),
	Upgrade: (self: BoatClass) -> (),

	-- Calculations
	CalculateBaseCost: (self: BoatClass) -> number,
	CalculateUpgradeCost: (self: BoatClass) -> number,
	GetMaxStorage: (self: BoatClass) -> number,
	CalculateFPS: (self: BoatClass) -> number,

	-- Fishing
	StartFishing: (self: BoatClass) -> (),
	StopFishing: (self: BoatClass) -> (),
	AddFish: (self: BoatClass, amount: number) -> (),
	RemoveFish: (self: BoatClass, amount: number) -> (),

	-- Visibility and collision
	Hide: (self: BoatClass) -> (),
	CannotCollide: (self: BoatClass) -> (),
	Show: (self: BoatClass) -> (),
	CanCollide: (self: BoatClass) -> (),

	-- UI Setup (new methods)
	Initialize: (self: BoatClass) -> (),
	SetupPurchaseBoard: (self: BoatClass) -> Part,
	SetupProximityPrompt: (self: BoatClass, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: BoatClass, proximityPrompt: ProximityPrompt) -> (),

	-- Utilities
	GetName: (self: BoatClass) -> string,

	-- Saving and Loading
	Serialize: (self: BoatClass) -> BoatState,

	-- Intervals
	FishingInterval: thread,
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

local STARTER_STATS: BoatState = {
	[BOATEnum.Level] = 1,
	[BOATEnum.MaxLevel] = 100,
	[BOATEnum.Tier] = 1,
	[BOATEnum.isPurchased] = false,
	[BOATEnum.UpgradeStage] = 1,
	[BOATEnum.StorageFull] = false,
	[BOATEnum.BaseCost] = 100,
	[BOATEnum.GrowthRate] = 1.1,
	[BOATEnum.CostGrowthRate] = 1.4,
	[BOATEnum.BaseStorage] = 100,
	[BOATEnum.BaseFPS] = 10,
	[BOATEnum.RealmId] = 1,
	[BOATEnum.FishInStorage] = 0,
}

local BoatClass: BoatClass = {}
BoatClass.__index = BoatClass

-- //SECTION - Constructor
function BoatClass:New(state: BoatState, player: Player, model: Model, currentRealm: number)
	local instance = setmetatable({}, BoatClass)

	-- Start with default stats as base
	for key, value in pairs(STARTER_STATS) do
		instance[key] = value
	end

	-- Override with provided state values
	if state then
		for key, value in pairs(state) do
			instance[key] = value
		end
	end

	-- Calculate derived properties after instance is set up
	instance[BOATEnum.Id] = instance[BOATEnum.Id] or HttpService:GenerateGUID(false) :: string
	instance[BOATEnum.Owner] = instance[BOATEnum.Owner] or player.UserId :: number
	instance[BOATEnum.BoatModel] = model :: Model
	instance[BOATEnum.Name] = instance[BOATEnum.Name] or instance:GetName() :: string
	instance[BOATEnum.BaseCost] = instance[BOATEnum.BaseCost] or instance:CalculateBaseCost() :: number
	instance[BOATEnum.UpgradeCost] = instance[BOATEnum.UpgradeCost] or instance:CalculateUpgradeCost() :: number

	local currentMaxStorage: number, nextLvlMaxStorage: number = instance:CalculateMaxStorage()
	instance[BOATEnum.CurrentMaxStorage] = instance[BOATEnum.CurrentMaxStorage] or currentMaxStorage :: number
	instance[BOATEnum.NextLvlMaxStorage] = instance[BOATEnum.NextLvlMaxStorage] or nextLvlMaxStorage :: number

	local currentFPS: number, nextFPS: number = instance:CalculateFPS()
	instance[BOATEnum.CurrentFPS] = instance[BOATEnum.CurrentFPS] or currentFPS :: number
	instance[BOATEnum.NextFPS] = instance[BOATEnum.NextFPS] or nextFPS :: number

	instance[BOATEnum.FishingInterval] = nil
	if instance[BOATEnum.isPurchased] and not instance[BOATEnum.StorageFull] then instance[BOATEnum.FishingInterval] = instance:StartFishing() end

	return instance
end
-- //!SECTION

function BoatClass:Upgrade()
	self[BOATEnum.Level] += 1
	for k, v in ipairs(BOAT_PROMOTION_LEVELS) do
		if self[BOATEnum.Level] == v then
			self:IncreaseUpgradeStage(k)
			break
		end
	end
	self[BOATEnum.UpgradeCost] = self:CalculateUpgradeCost()
	self[BOATEnum.Name] = self:GetName()

	local currentMaxStorage: number, nextLvlMaxStorage: number = self:CalculateMaxStorage()
	self[BOATEnum.CurrentMaxStorage] = currentMaxStorage
	self[BOATEnum.NextLvlMaxStorage] = nextLvlMaxStorage

	local currentFPS: number, nextFPS: number = self:CalculateFPS()
	self[BOATEnum.CurrentFPS] = currentFPS
	self[BOATEnum.NextFPS] = nextFPS
end

function BoatClass:CalculateMaxStorage()
	local baseStorage = STARTER_STATS.BaseStorage
	local growthRate = STARTER_STATS.GrowthRate + self[BOATEnum.Tier] * 0.02 :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]] :: number
	local maxStorage = baseStorage * math.pow(growthRate :: number, self[BOATEnum.Level] :: number) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate :: number, self[BOATEnum.Level] :: number + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

function BoatClass:CalculateBaseFPS(): number
	local baseFPS = STARTER_STATS.BaseFPS

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local realmMultiplier = math.pow(self[BOATEnum.RealmId] :: number, 2.25) -- scaling curve

	local baseFPSCalc = baseFPS * tierMultiplier * realmMultiplier

	return baseFPSCalc
end

function BoatClass:CalculateFPS(): number
	local baseFPS = self:CalculateBaseFPS()

	local growthRate = STARTER_STATS.GrowthRate :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local level = self[BOATEnum.Level] :: number

	local fpsCalc = baseFPS * math.pow(growthRate :: number, level) * tierMultiplier
	local nextLvlFPS = baseFPS * math.pow(growthRate :: number, level + 1) * tierMultiplier

	-- //TODO - handle boosts

	return fpsCalc, nextLvlFPS
end

function BoatClass:CalculateBaseCost(): number
	local baseCost = STARTER_STATS.BaseCost

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local realmMultiplier = math.pow(self[BOATEnum.RealmId] :: number, 2.25) -- scaling curve

	local cost = baseCost * tierMultiplier * realmMultiplier

	return cost
end

function BoatClass:CalculateUpgradeCost(): number
	local baseCost = self[BOATEnum.BaseCost] or STARTER_STATS.BaseCost

	if baseCost <= 0 then
		FFGHelpers.PrintLog("Base cost is either 0 or below, returning")
		return
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]

	local realmMultiplier = math.pow(self[BOATEnum.RealmId] :: number, 2.25) -- scaling curve

	local growthRate = STARTER_STATS.CostGrowthRate

	local cost = baseCost * math.pow(growthRate, self[BOATEnum.Level] :: number) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

function BoatClass:Purchase()
	self[BOATEnum.isPurchased] = true
end

function BoatClass:StartFishing()
	self[BOATEnum.FishingInterval] = SetInterval(function()
		if not self[BOATEnum.StorageFull] then self:AddFish(self[BOATEnum.CurrentFPS]) end
	end, 1)
end

function BoatClass:StopFishing()
	if self[BOATEnum.FishingInterval] then
		task.cancel(self[BOATEnum.FishingInterval])
		self[BOATEnum.FishingInterval] = nil
	end
end

function BoatClass:AddFish(amount: number)
	FFGHelpers.PrintLog("Adding Fish", amount)
	if self[BOATEnum.StorageFull] then
		FFGHelpers.PrintLog("Storage is full")
		return
	end

	self[BOATEnum.FishInStorage] += amount

	if self[BOATEnum.FishInStorage] > self[BOATEnum.CurrentMaxStorage] then
		self[BOATEnum.FishInStorage] = self[BOATEnum.CurrentMaxStorage]
		self[BOATEnum.StorageFull] = true
	end
end

function BoatClass:RemoveFish(amount: number)
	self[BOATEnum.FishInStorage] = math.max(self[BOATEnum.FishInStorage] - amount, 0)

	self[BOATEnum.StorageFull] = false
end

function BoatClass:IncreaseUpgradeStage(stage)
	self[BOATEnum.UpgradeStage] = stage
end

function BoatClass:GetName(): string
	return NAME[self[BOATEnum.UpgradeStage]]
end

-- //SECTION - Loading and Saving
function BoatClass:Serialize(): BoatState
	return {
		[BOATEnum.Id] = self[BOATEnum.Id],
		[BOATEnum.Owner] = self[BOATEnum.Owner],
		[BOATEnum.Level] = self[BOATEnum.Level],
		[BOATEnum.Tier] = self[BOATEnum.Tier],
		[BOATEnum.isPurchased] = self[BOATEnum.isPurchased],
		[BOATEnum.UpgradeCost] = self[BOATEnum.UpgradeCost],
		[BOATEnum.UpgradeStage] = self[BOATEnum.UpgradeStage],
		[BOATEnum.MaxLevel] = self[BOATEnum.MaxLevel],
		[BOATEnum.BaseCost] = self[BOATEnum.BaseCost],
		[BOATEnum.BaseFPS] = self[BOATEnum.BaseFPS],
		[BOATEnum.BaseStorage] = self[BOATEnum.BaseStorage],
		[BOATEnum.CurrentMaxStorage] = self[BOATEnum.CurrentMaxStorage],
		[BOATEnum.CurrentFPS] = self[BOATEnum.CurrentFPS],
		[BOATEnum.NextFPS] = self[BOATEnum.NextFPS],
		[BOATEnum.FishInStorage] = self[BOATEnum.FishInStorage],
		[BOATEnum.Name] = self[BOATEnum.Name],
		[BOATEnum.NextLvlMaxStorage] = self[BOATEnum.NextLvlMaxStorage],
		[BOATEnum.RealmId] = self[BOATEnum.RealmId],
		[BOATEnum.StorageFull] = self[BOATEnum.StorageFull],
	}
end
-- //!SECTION

-- //SECTION - Boat  Utilities
function BoatClass:IsStorageFull()
	return self[BOATEnum.StorageFull]
end

function BoatClass:Show()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function BoatClass:CanCollide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function BoatClass:CannotCollide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end

function BoatClass:Hide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

-- //SECTION - UI Setup Methods
function BoatClass:Initialize()
	-- Handle visibility based on purchase status
	if not self[BOATEnum.isPurchased] then
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

function BoatClass:SetupPurchaseBoard()
	local purchaseBoard = self[BOATEnum.BoatModel]:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
	pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel

	if pbDetails then
		local upgradeStage = self[BOATEnum.UpgradeStage]
		local level = self[BOATEnum.Level]
		local qualityInfo = FFGEnum.QUALITY[upgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not self[BOATEnum.isPurchased] then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = self:GetName()
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = self[BOATEnum.isPurchased] and "Level: " .. level or "Purchase Boat"

		-- STORAGE STATS
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self[BOATEnum.isPurchased] and FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self[BOATEnum.isPurchased] and FormatNumber(nextStorage) or ""

		-- FPS STATS
		local currentFPS, nextFPS = self:CalculateFPS()
		pbDetails.CurrentFPSLabel.Text = self[BOATEnum.isPurchased] and FormatNumber(currentFPS) or ""
		pbDetails.NextFPSLabel.Text = self[BOATEnum.isPurchased] and FormatNumber(nextFPS) or ""
	end

	return purchaseBoard
end

function BoatClass:UpdatePurchaseBoardUI()
	local isPurchased = self[BOATEnum.isPurchased]
	local purchaseBoard = self[BOATEnum.BoatModel]:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
	pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel

	-- //TODO - use formatting helper
	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and FormatNumber(self[BOATEnum.CurrentMaxStorage]) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and FormatNumber(self[BOATEnum.NextLvlMaxStorage]) or ""
	pbDetails.CurrentFPSLabel.Text = isPurchased and FormatNumber(self[BOATEnum.CurrentFPS]) or ""
	pbDetails.NextFPSLabel.Text = isPurchased and FormatNumber(self[BOATEnum.NextFPS]) or ""

	local level = self[BOATEnum.Level]
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self[BOATEnum.UpgradeStage]

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self[BOATEnum.isPurchased] then pbDetails.NameLabel.Parent.Visible = true end
end

function BoatClass:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if boat is at max level
	if self[BOATEnum.Level] == self[BOATEnum.MaxLevel] then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0
	proximityPrompt.ObjectText = self[BOATEnum.isPurchased] and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = self[BOATEnum.isPurchased] and "Level: " .. tostring(self[BOATEnum.Level] + 1) or "Tier " .. self[BOATEnum.Tier] .. " Boat"

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
		-- Check max level again
		if self[BOATEnum.Level] == self[BOATEnum.MaxLevel] then return end

		local upgradeCost = self[BOATEnum.isPurchased] and self[BOATEnum.UpgradeCost] or self[BOATEnum.BaseCost]

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)

		if self[BOATEnum.isPurchased] then
			-- Upgrade existing boat
			self:Upgrade()
		else
			-- Purchase boat
			self:Purchase()
			self:StartFishing()
			self:Show()
			self:CanCollide()
		end

		-- Update UIs
		self:UpdateProximityPromptUI(proximityPrompt)
		self:UpdatePurchaseBoardUI()

		DataService.SaveBoatState(player, self[BOATEnum.Id], self:Serialize())
	end)

	return proximityPrompt
end

function BoatClass:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self[BOATEnum.Level] == self[BOATEnum.MaxLevel] then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
	else
		proximityPrompt.ObjectText = self[BOATEnum.isPurchased] and "Upgrade Boat" or "Purchase"
		proximityPrompt.ActionText = self[BOATEnum.isPurchased] and "Level: " .. tostring(self[BOATEnum.Level] + 1) or "Tier " .. self[BOATEnum.Tier] .. " Boat"
	end
end
-- //!SECTION

return BoatClass
