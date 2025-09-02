local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local TENDEREnum = FFGEnum.ATTRIBUTES.TENDER

export type TenderState = {
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
	FishInStorage: number?,
	StorageFull: boolean,
	GrowthRate: number,
	CostGrowthRate: number,
	BaseStorage: number,
}

export type TenderClass = TenderState & {
	-- Constructor
	New: (self: TenderClass, state: TenderState, ownerId: number, model: Model, currentrealm: number?) -> TenderClass,

	-- Core tender actions
	Purchase: (self: TenderClass) -> (),
	Upgrade: (self: TenderClass) -> (),

	-- Calculations
	CalculateBaseCost: (self: TenderClass) -> number,
	CalculateUpgradeCost: (self: TenderClass) -> number,
	GetMaxStorage: (self: TenderClass) -> number,

	-- Fishing
	AddFish: (self: TenderClass, amount: number) -> (),
	RemoveFish: (self: TenderClass, amount: number) -> (),

	-- Visibility and collision
	Hide: (self: TenderClass) -> (),
	CannotCollide: (self: TenderClass) -> (),
	Show: (self: TenderClass) -> (),
	CanCollide: (self: TenderClass) -> (),

	-- UI Setup (new methods)
	Initialize: (self: TenderClass) -> (),
	SetupPurchaseBoard: (self: TenderClass) -> Part,
	UpdatePurchaseBoardUI: (self: TenderClass) -> (),
	SetupProximityPrompt: (self: TenderClass, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: TenderClass, proximityPrompt: ProximityPrompt) -> (),

	-- Utilities
	GetName: (self: TenderClass) -> string,

	-- Saving and Loading
	Serialize: (self: TenderClass) -> TenderState,
}

local TENDER_PROMOTION_LEVELS = {
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
	[1] = "Wooden Cart-Barge",
	[2] = "Barrel Barge",
	[3] = "Oarsman’s Ferry",
	[4] = "Courier Skiff",
	[5] = "Windcloak Sloop",
	[6] = "Seawarden’s Tender",
	[7] = "Crate Hauler",
	[8] = "Knight’s Courier",
	[9] = "Harbormaster’s Crest",
	[10] = "Starlit Barge",
	[11] = "Little Lucy",
}

local STARTER_STATS: TenderState = {
	[TENDEREnum.Level] = 1,
	[TENDEREnum.MaxLevel] = 100,
	[TENDEREnum.Tier] = 1,
	[TENDEREnum.isPurchased] = false,
	[TENDEREnum.UpgradeStage] = 1,
	[TENDEREnum.BaseCost] = Formulas.TENDER.BaseCost,
	[TENDEREnum.GrowthRate] = Formulas.TENDER.GrowthRate,
	[TENDEREnum.CostGrowthRate] = Formulas.TENDER.CostGrowthRate,
	[TENDEREnum.BaseStorage] = Formulas.TENDER.BaseStorage,
	[TENDEREnum.RealmId] = 1,
	[TENDEREnum.FishInStorage] = 0,
	[TENDEREnum.BaseSpeed] = 5, -- secs
}

local TenderClass: TenderClass = {}
TenderClass.__index = TenderClass

-- //SECTION - Constructor
function TenderClass:New(state: TenderState, player: Player, model: Model)
	local instance = setmetatable({}, TenderClass)

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
	instance[TENDEREnum.Id] = instance[TENDEREnum.Id] or HttpService:GenerateGUID(false) :: string
	instance[TENDEREnum.Owner] = instance[TENDEREnum.Owner] or player.UserId :: number
	instance[TENDEREnum.TenderModel] = model :: Model
	instance[TENDEREnum.Name] = instance[TENDEREnum.Name] or instance:GetName() :: string
	instance[TENDEREnum.BaseCost] = instance[TENDEREnum.BaseCost] or instance:CalculateBaseCost() :: number
	instance[TENDEREnum.UpgradeCost] = instance[TENDEREnum.UpgradeCost] or instance:CalculateUpgradeCost() :: number

	local currentMaxStorage: number, nextLvlMaxStorage: number = instance:CalculateMaxStorage()
	instance[TENDEREnum.CurrentMaxStorage] = instance[TENDEREnum.CurrentMaxStorage] or currentMaxStorage :: number
	instance[TENDEREnum.NextLvlMaxStorage] = instance[TENDEREnum.NextLvlMaxStorage] or nextLvlMaxStorage :: number

	-- //TODO handle BaseSpeed calculation

	return instance
end
-- //!SECTION

function TenderClass:Upgrade()
	self[TENDEREnum.Level] += 1
	for k, v in ipairs(TENDER_PROMOTION_LEVELS) do
		if self[TENDEREnum.Level] == v then
			self:IncreaseUpgradeStage(k)
			break
		end
	end
	self[TENDEREnum.UpgradeCost] = self:CalculateUpgradeCost()
	self[TENDEREnum.Name] = self:GetName()

	local currentMaxStorage: number, nextLvlMaxStorage: number = self:CalculateMaxStorage()
	self[TENDEREnum.CurrentMaxStorage] = currentMaxStorage
	self[TENDEREnum.NextLvlMaxStorage] = nextLvlMaxStorage

	-- //TODO - Handle the BaseSpeed upgrade
end

function TenderClass:CalculateMaxStorage()
	local baseStorage = STARTER_STATS.BaseStorage
	local growthRate = STARTER_STATS.GrowthRate + self[TENDEREnum.Tier] * 0.02 :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[TENDEREnum.Tier]] :: number
	local maxStorage = baseStorage * math.pow(growthRate :: number, self[TENDEREnum.Level] :: number) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate :: number, self[TENDEREnum.Level] :: number + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

function TenderClass:CalculateBaseCost(): number
	local baseCost = STARTER_STATS.BaseCost

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[TENDEREnum.Tier]]
	local realmMultiplier = math.pow(self[TENDEREnum.RealmId] :: number, 2.25) -- scaling curve

	local cost = baseCost * tierMultiplier * realmMultiplier

	return cost
end

function TenderClass:CalculateUpgradeCost(): number
	local baseCost = self[TENDEREnum.BaseCost] or STARTER_STATS.BaseCost

	if baseCost <= 0 then
		FFGHelpers.PrintLog("Base cost is either 0 or below, returning")
		return
	end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[TENDEREnum.Tier]]

	local realmMultiplier = math.pow(self[TENDEREnum.RealmId] :: number, 2.25) -- scaling curve

	local growthRate = STARTER_STATS.CostGrowthRate

	local cost = baseCost * math.pow(growthRate, self[TENDEREnum.Level] :: number) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

function TenderClass:Purchase()
	self[TENDEREnum.isPurchased] = true
end

-- //TODO - Handle the travelling functions

function TenderClass:AddFish(amount: number)
	FFGHelpers.PrintLog("Adding Fish", amount)
	if self[TENDEREnum.StorageFull] then
		FFGHelpers.PrintLog("Storage is full")
		return
	end

	self[TENDEREnum.FishInStorage] += amount

	if self[TENDEREnum.FishInStorage] > self[TENDEREnum.CurrentMaxStorage] then
		self[TENDEREnum.FishInStorage] = self[TENDEREnum.CurrentMaxStorage]
		self[TENDEREnum.StorageFull] = true
	end
end

function TenderClass:RemoveFish(amount: number)
	-- //TODO - Handle moving the fish to pier storage
	self[TENDEREnum.FishInStorage] = math.max(self[TENDEREnum.FishInStorage] - amount, 0)

	self[TENDEREnum.StorageFull] = false
end

function TenderClass:IncreaseUpgradeStage(stage)
	self[TENDEREnum.UpgradeStage] = stage
end

function TenderClass:GetName(): string
	return NAME[self[TENDEREnum.UpgradeStage]]
end

-- //SECTION - Loading and Saving
function TenderClass:Serialize(): TenderState
	return {
		[TENDEREnum.Id] = self[TENDEREnum.Id],
		[TENDEREnum.Owner] = self[TENDEREnum.Owner],
		[TENDEREnum.Level] = self[TENDEREnum.Level],
		[TENDEREnum.Tier] = self[TENDEREnum.Tier],
		[TENDEREnum.isPurchased] = self[TENDEREnum.isPurchased],
		[TENDEREnum.UpgradeCost] = self[TENDEREnum.UpgradeCost],
		[TENDEREnum.UpgradeStage] = self[TENDEREnum.UpgradeStage],
		[TENDEREnum.MaxLevel] = self[TENDEREnum.MaxLevel],
		[TENDEREnum.BaseCost] = self[TENDEREnum.BaseCost],
		[TENDEREnum.BaseStorage] = self[TENDEREnum.BaseStorage],
		[TENDEREnum.CurrentMaxStorage] = self[TENDEREnum.CurrentMaxStorage],
		[TENDEREnum.BaseSpeed] = self[TENDEREnum.BaseSpeed],
		[TENDEREnum.CurrentSpeed] = self[TENDEREnum.CurrentSpeed],
		[TENDEREnum.NextSpeed] = self[TENDEREnum.NextSpeed],
		[TENDEREnum.FishInStorage] = self[TENDEREnum.FishInStorage],
		[TENDEREnum.Name] = self[TENDEREnum.Name],
		[TENDEREnum.NextLvlMaxStorage] = self[TENDEREnum.NextLvlMaxStorage],
		[TENDEREnum.RealmId] = self[TENDEREnum.RealmId],
	}
end
-- //!SECTION

-- //SECTION - Tender  Utilities
function TenderClass:Show()
	local model = self[TENDEREnum.TenderModel] :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function TenderClass:CanCollide()
	local model = self[TENDEREnum.TenderModel] :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function TenderClass:CannotCollide()
	local model = self[TENDEREnum.TenderModel] :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end

function TenderClass:Hide()
	local model = self[TENDEREnum.TenderModel] :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

-- //SECTION - UI Setup Methods
function TenderClass:Initialize()
	-- Handle visibility based on purchase status
	if not self[TENDEREnum.isPurchased] then
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

function TenderClass:SetupPurchaseBoard()
	local purchaseBoard = self[TENDEREnum.TenderModel]:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentSpeedLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentSpeed", "TextLabel") :: TextLabel
	pbDetails.NextSpeedLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextSpeed", "TextLabel") :: TextLabel

	if pbDetails then
		local upgradeStage = self[TENDEREnum.UpgradeStage]
		local level = self[TENDEREnum.Level]
		local qualityInfo = FFGEnum.QUALITY[upgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not self[TENDEREnum.isPurchased] then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = self:GetName()
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = self[TENDEREnum.isPurchased] and "Level: " .. level or "Purchase Tender"

		-- STORAGE Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self[TENDEREnum.isPurchased] and FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self[TENDEREnum.isPurchased] and FormatNumber(nextStorage) or ""

		-- //TODO - Hande updating speed
	end

	return purchaseBoard
end

function TenderClass:UpdatePurchaseBoardUI()
	local isPurchased = self[TENDEREnum.isPurchased]
	local purchaseBoard = self[TENDEREnum.TenderModel]:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentSpeedLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentSpeed", "TextLabel") :: TextLabel
	pbDetails.NextSpeedLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextSpeed", "TextLabel") :: TextLabel

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and FormatNumber(self[TENDEREnum.CurrentMaxStorage]) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and FormatNumber(self[TENDEREnum.NextLvlMaxStorage]) or ""
	-- //TODO - Hande updating speed

	local level = self[TENDEREnum.Level]
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self[TENDEREnum.UpgradeStage]

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self[TENDEREnum.isPurchased] then pbDetails.NameLabel.Parent.Visible = true end
end

function TenderClass:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if tender is at max level
	if self[TENDEREnum.Level] == self[TENDEREnum.MaxLevel] then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0
	proximityPrompt.ObjectText = self[TENDEREnum.isPurchased] and "Upgrade Tender" or "Purchase"
	proximityPrompt.ActionText = self[TENDEREnum.isPurchased] and "Level: " .. tostring(self[TENDEREnum.Level] + 1) or "Tier " .. self[TENDEREnum.Tier] .. " Tender"

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
		-- Check max level again
		if self[TENDEREnum.Level] == self[TENDEREnum.MaxLevel] then return end

		local upgradeCost = self[TENDEREnum.isPurchased] and self[TENDEREnum.UpgradeCost] or self[TENDEREnum.BaseCost]

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)

		if self[TENDEREnum.isPurchased] then
			-- Upgrade existing tender
			self:Upgrade()
		else
			-- Purchase tender
			self:Purchase()
			self:Show()
			self:CanCollide()
		end

		-- Update UIs
		self:UpdateProximityPromptUI(proximityPrompt)
		self:UpdatePurchaseBoardUI()

		DataService.SaveTenderState(player, self[TENDEREnum.Id], self:Serialize())
	end)

	return proximityPrompt
end

function TenderClass:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self[TENDEREnum.Level] == self[TENDEREnum.MaxLevel] then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
	else
		proximityPrompt.ObjectText = self[TENDEREnum.isPurchased] and "Upgrade Tender" or "Purchase"
		proximityPrompt.ActionText = self[TENDEREnum.isPurchased] and "Level: " .. tostring(self[TENDEREnum.Level] + 1) or "Tier " .. self[TENDEREnum.Tier] .. " Tender"
	end
end
-- //!SECTION

return TenderClass
