local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
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
	[BOATEnum.isActive] = false,
	[BOATEnum.isPurchased] = false,
	[BOATEnum.UpgradeStage] = 1,
	[BOATEnum.StorageFull] = false,
	[BOATEnum.BaseCost] = 100,
	[BOATEnum.GrowthRate] = 1.1,
	[BOATEnum.CostGrowthRate] = 1.4,
	[BOATEnum.BaseStorage] = 100,
	[BOATEnum.BaseFPS] = 10,
	[BOATEnum.RealmId] = 1,
}

local BoatClass = {}
BoatClass.__index = BoatClass

-- //SECTION - Constructor
function BoatClass:New(state: FFGTypes.BoatState, player: Player, model: Model, currentrealm: number)
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
	instance[BOATEnum.RealmId] = instance[BOATEnum.RealmId] or currentrealm or STARTER_STATS.RealmId :: number
	instance[BOATEnum.Name] = instance[BOATEnum.Name] or instance:GetName() :: string
	instance[BOATEnum.BaseCost] = instance[BOATEnum.BaseCost] or instance:CalculateBaseCost() :: number
	instance[BOATEnum.UpgradeCost] = instance[BOATEnum.UpgradeCost] or instance:CalculateUpgradeCost() :: number

	local currentMaxStorage: number, nextLvlMaxStorage: number = instance:CalculateMaxStorage()
	instance[BOATEnum.CurrentMaxStorage] = instance[BOATEnum.CurrentMaxStorage] or currentMaxStorage :: number
	instance[BOATEnum.NextLvlMaxStorage] = instance[BOATEnum.NextLvlMaxStorage] or nextLvlMaxStorage :: number

	instance[BOATEnum.FPS] = instance[BOATEnum.FPS] or instance:CalculateFPS() :: number

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

	local growthRate = STARTER_STATS.GrowthRate
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self[BOATEnum.Tier]]
	local level = self[BOATEnum.Level] :: number

	local fpsCalc = baseFPS * math.pow(growthRate, level) * tierMultiplier
	local nextLvlFPS = baseFPS * math.pow(growthRate, level + 1) * tierMultiplier

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
	if self[BOATEnum.isActive] then
		FFGHelpers.PrintLog("The boat is already active, no need to start fishing.")
		return
	end

	self[BOATEnum.isActive] = true
end

function BoatClass:StopFishing()
	if not self[BOATEnum.isActive] then
		FFGHelpers.PrintLog("The boat is already not active, no need to stop fishing.")
		return
	end

	self[BOATEnum.isActive] = false
end

function BoatClass:AddFish(amount: number)
	--
end

function BoatClass:RemoveFish(amount: number)
	--
end

function BoatClass:IncreaseUpgradeStage(stage)
	self[BOATEnum.UpgradeStage] = stage
end

function BoatClass:GetName(): string
	return NAME[self[BOATEnum.UpgradeStage]]
end

-- //SECTION - Loading and Saving
function BoatClass:Serialize(): FFGTypes.BoatState
	return {
		[BOATEnum.Id] = self[BOATEnum.Id],
		[BOATEnum.Owner] = self[BOATEnum.Owner],
		[BOATEnum.Level] = self[BOATEnum.Level],
		[BOATEnum.Tier] = self[BOATEnum.Tier],
		[BOATEnum.isPurchased] = self[BOATEnum.isPurchased],
		[BOATEnum.isActive] = self[BOATEnum.isActive],
		[BOATEnum.UpgradeCost] = self[BOATEnum.UpgradeCost],
		[BOATEnum.UpgradeStage] = self[BOATEnum.UpgradeStage],
		[BOATEnum.MaxLevel] = self[BOATEnum.MaxLevel],
		[BOATEnum.BaseCost] = self[BOATEnum.BaseCost],
		[BOATEnum.BaseFPS] = self[BOATEnum.BaseFPS],
		[BOATEnum.BaseStorage] = self[BOATEnum.BaseStorage],
		[BOATEnum.CurrentMaxStorage] = self[BOATEnum.CurrentMaxStorage],
		[BOATEnum.FPS] = self[BOATEnum.FPS],
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
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

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

function BoatClass:UpdatePurchaseBoardUI()
	local isPurchased = self[BOATEnum.isPurchased]
	local purchaseBoard = self[BOATEnum.BoatModel]:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

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
