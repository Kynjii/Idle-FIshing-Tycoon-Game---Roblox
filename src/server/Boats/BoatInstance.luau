local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local Formulas = require(ServerScriptService.Server.Game.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local BOATEnum = FFGEnum.ATTRIBUTES.BOAT

local _BOAT_PROMOTION_LEVELS = {
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
	[BOATEnum.isActive] = false,
	[BOATEnum.isPurchased] = false,
	[BOATEnum.UpgradeStage] = 1,
	[BOATEnum.StorageFull] = false,
	[BOATEnum.BaseCost] = 100,
	[BOATEnum.GrowthRate] = 1.1,
	[BOATEnum.CostGrowthRate] = 1.4,
	[BOATEnum.BaseStorage] = 100,
	[BOATEnum.BaseFPS] = 10,
	[BOATEnum.RealmLevel] = 1,
}

local BoatInstance = {}
BoatInstance.__index = BoatInstance

-- //SECTION - Constructor
function BoatInstance:New(state: FFGTypes.BoatState, player: Player, model: Model, currentrealm: number)
	local instance = setmetatable({}, BoatInstance)

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
	instance[BOATEnum.Id] = instance[BOATEnum.Id] or HttpService:GenerateGUID(false)
	instance[BOATEnum.Owner] = instance[BOATEnum.Owner] or player.UserId
	instance[BOATEnum.BoatModel] = model
	instance[BOATEnum.RealmLevel] = instance[BOATEnum.RealmLevel] or currentrealm or STARTER_STATS.RealmLevel
	instance[BOATEnum.Name] = instance[BOATEnum.Name] or instance:GetName()
	instance[BOATEnum.BaseCost] = instance[BOATEnum.BaseCost] or instance:CalculateBaseCost()
	instance[BOATEnum.UpgradeCost] = instance[BOATEnum.UpgradeCost] or instance:CalculateUpgradeCost()

	local currentMaxStorage: number, nextLvlMaxStorage: number = instance:CalculateMaxStorage()
	instance[BOATEnum.CurrentMaxStorage] = instance[BOATEnum.CurrentMaxStorage] or currentMaxStorage
	instance[BOATEnum.NextLvlMaxStorage] = instance[BOATEnum.NextLvlMaxStorage] or nextLvlMaxStorage

	instance[BOATEnum.FPS] = instance[BOATEnum.FPS] or instance:CalculateFPS()

	return instance
end
-- //!SECTION

function BoatInstance:Upgrade()
	self[BOATEnum.Level] += 1
	for k, v in ipairs(_BOAT_PROMOTION_LEVELS) do
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
end

function BoatInstance:CalculateMaxStorage()
	local baseStorage = STARTER_STATS.BaseStorage
	local growthRate = STARTER_STATS.GrowthRate + self[BOATEnum.Tier] * 0.02 :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]] :: number
	local maxStorage = baseStorage * math.pow(growthRate, self[BOATEnum.Level]) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate, self[BOATEnum.Level] + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

function BoatInstance:CalculateBaseFPS(): number
	local baseFPS = STARTER_STATS.BaseFPS

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local realmMultiplier = math.pow(self[BOATEnum.RealmLevel], 2.25) -- scaling curve

	local baseFPSCalc = baseFPS * tierMultiplier * realmMultiplier

	return baseFPSCalc
end

function BoatInstance:CalculateFPS(): number
	local baseFPS = self:CalculateBaseFPS()

	local growthRate = STARTER_STATS.GrowthRate
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local level = self[BOATEnum.Level] :: number

	local fpsCalc = baseFPS * math.pow(growthRate, level) * tierMultiplier
	local nextLvlFPS = baseFPS * math.pow(growthRate, level + 1) * tierMultiplier

	-- //TODO - handle boosts

	return fpsCalc, nextLvlFPS
end

function BoatInstance:CalculateBaseCost(): number
	local baseCost = STARTER_STATS.BaseCost

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

	local growthRate = STARTER_STATS.CostGrowthRate

	local cost = baseCost * math.pow(growthRate, self[BOATEnum.Level]) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

function BoatInstance:Purchase()
	self[BOATEnum.isPurchased] = true
end

function BoatInstance:StartFishing()
	if self[BOATEnum.isActive] then
		FFGHelpers.PrintLog("The boat is already active, no need to start fishing.")
		return
	end

	self[BOATEnum.isActive] = true
end

function BoatInstance:StopFishing()
	if not self[BOATEnum.isActive] then
		FFGHelpers.PrintLog("The boat is already not active, no need to stop fishing.")
		return
	end

	self[BOATEnum.isActive] = false
end

function BoatInstance:AddFish(amount: number)
	--
end

function BoatInstance:RemoveFish(amount: number)
	--
end

function BoatInstance:IncreaseUpgradeStage(stage)
	self[BOATEnum.UpgradeStage] = stage
end

function BoatInstance:GetName(): string
	return NAME[self[BOATEnum.UpgradeStage]]
end

-- //SECTION - Loading and Saving
function BoatInstance:Serialize(): FFGTypes.BoatState
	return {
		id = self[BOATEnum.Id],
		ownerId = self[BOATEnum.Owner],
		level = self[BOATEnum.Level],
		tier = self[BOATEnum.Tier],
		isPurchased = self[BOATEnum.isPurchased],
		isActive = self[BOATEnum.isActive],
		upgradeCost = self[BOATEnum.UpgradeCost],
		upgradeStage = self[BOATEnum.UpgradeStage],
		maxLevel = self[BOATEnum.MaxLevel],
		baseCost = self[BOATEnum.BaseCost],
		baseFPS = self[BOATEnum.BaseFPS],
		baseStorage = self[BOATEnum.BaseStorage],
		currentMaxStorage = self[BOATEnum.CurrentMaxStorage],
		fishPerSecond = self[BOATEnum.FPS],
		fishInStorage = self[BOATEnum.FishInStorage],
		name = self[BOATEnum.Name],
		nextLvlMaxStorage = self[BOATEnum.NextLvlMaxStorage],
		realmLevel = self[BOATEnum.RealmLevel],
		storageFull = self[BOATEnum.StorageFull],
	}
end
-- //!SECTION

-- //SECTION - Boat  Utilities
function BoatInstance:IsStorageFull()
	return self[BOATEnum.StorageFull]
end

function BoatInstance:Show()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function BoatInstance:CanCollide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function BoatInstance:CannotCollide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end

function BoatInstance:Hide()
	local model = self[BOATEnum.BoatModel] :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

-- //SECTION - UI Setup Methods
function BoatInstance:Initialize()
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

function BoatInstance:SetupPurchaseBoard()
	local purchaseBoard = self[BOATEnum.BoatModel]:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

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

		-- Use instance methods for storage calculations
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self[BOATEnum.isPurchased] and tostring(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self[BOATEnum.isPurchased] and tostring(nextStorage) or ""
	end

	return purchaseBoard
end

function BoatInstance:UpdatePurchaseBoardUI()
	local isPurchased = self[BOATEnum.isPurchased]
	local purchaseBoard = self[BOATEnum.BoatModel]:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

	-- //TODO - use formatting helper
	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and tostring(self[BOATEnum.CurrentMaxStorage]) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and tostring(self[BOATEnum.NextLvlMaxStorage]) or ""

	local level = self[BOATEnum.Level]
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self[BOATEnum.UpgradeStage]

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self[BOATEnum.isPurchased] then pbDetails.NameLabel.Parent.Visible = true end
end

function BoatInstance:SetupProximityPrompt(purchaseBoard: Part)
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

		if not DataManager.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		end

		-- Spend the currency
		DataManager.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)

		if self[BOATEnum.isPurchased] then
			-- Upgrade existing boat
			self:Upgrade()
		else
			-- Purchase boat
			self:Purchase()
			self:Show()
			self:CanCollide()
		end

		-- Update UIs
		self:UpdateProximityPromptUI(proximityPrompt)
		self:UpdatePurchaseBoardUI()
	end)

	return proximityPrompt
end

function BoatInstance:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self[BOATEnum.Level] == self[BOATEnum.MaxLevel] then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
	else
		proximityPrompt.ObjectText = self[BOATEnum.isPurchased] and "Upgrade Boat" or "Purchase"
		proximityPrompt.ActionText = self[BOATEnum.isPurchased] and "Level: " .. tostring(self[BOATEnum.Level] + 1) or "Tier " .. self[BOATEnum.Tier] .. " Boat"
	end
end
-- //!SECTION

return BoatInstance
