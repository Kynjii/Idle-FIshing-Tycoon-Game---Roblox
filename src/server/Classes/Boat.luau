local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)

-- //SECTION - Boat Types
type Boat = BoatType.Boat
type BoatProps = BoatType.BoatProps
type BoatInstance = BoatType.BoatInstance
-- //!SECTION

-- //SECTION - Boat Data
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

local DEFAULTS: BoatProps = {
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Boat",
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.BOAT.BaseCost,
	isPurchased = false,
	BaseStorage = Formulas.BOAT.BaseStorage,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
	BaseFPS = Formulas.BOAT.BaseFPS,
	GrowthRate = Formulas.BOAT.GrowthRate,
	CostGrowthRate = Formulas.BOAT.CostGrowthRate,
}
-- //!SECTION

local Boat = {} :: BoatInstance
Boat.__index = Boat

-- //SECTION - Constructor
function Boat.New(state, player: Player, model: Model): Boat
	local self: BoatInstance = setmetatable({}, Boat)

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
	self.Name = self:GetName()

	-- Had to take this approach for type checking to work
	if self.BaseCost == DEFAULTS.BaseCost then self.BaseCost = self:CalculateBaseCost() end
	if not self.UpgradeCost then self.UpgradeCost = self:CalculateUpgradeCost() end

	local curMaxStorage, nextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentMaxStorage = self.CurrentMaxStorage or curMaxStorage
	self.NextLvlMaxStorage = self.NextLvlMaxStorage or nextLvlMaxStorage

	local curFPS, nextFPS = self:CalculateFPS()
	self.CurrentFPS = self.CurrentFPS or curFPS
	self.NextFPS = self.NextFPS or nextFPS

	self.FishingInterval = nil
	if self.isPurchased and not self:IsStorageFull() then self:StartFishing() end

	return self
end
-- //!SECTION

-- //SECTION - Core Boat Actions
function Boat:Purchase()
	self.isPurchased = true
end

function Boat:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(BOAT_PROMOTION_LEVELS) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			break
		end
	end
	self.UpgradeCost = self:CalculateUpgradeCost()

	local curMaxStorage, nextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentMaxStorage = curMaxStorage
	self.NextLvlMaxStorage = nextLvlMaxStorage

	local curFPS, nextFPS = self:CalculateFPS()
	self.CurrentFPS = curFPS
	self.NextFPS = nextFPS
end

function Boat:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Boat:CalculateBaseCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local base = baseCost * tierMultiplier * realmMultiplier

	self.BaseCost = base

	return base
end

function Boat:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local growthRate = DEFAULTS.CostGrowthRate
	local cost = baseCost * math.pow(growthRate, self.Level :: number) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

function Boat:CalculateBaseStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local base = baseStorage * tierMultiplier * realmMultiplier

	self.BaseStorage = base

	return base
end

function Boat:CalculateMaxStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier] :: number
	local growthRate = DEFAULTS.GrowthRate + self.Tier * 0.02 :: number
	local maxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

function Boat:CalculateBaseFPS()
	local baseFPS = self.BaseFPS or DEFAULTS.BaseFPS
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local base = baseFPS * tierMultiplier * realmMultiplier

	self.BaseFPS = base

	return base
end

function Boat:CalculateFPS()
	local baseFPS = self.BaseFPS or DEFAULTS.BaseFPS
	if baseFPS == DEFAULTS.BaseCost then baseFPS = self:CalculateBaseFPS() end

	local growthRate = DEFAULTS.GrowthRate :: number
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local level = self.Level :: number

	local fpsCalc = baseFPS * math.pow(growthRate :: number, level) * tierMultiplier
	local nextLvlFPS = baseFPS * math.pow(growthRate :: number, level + 1) * tierMultiplier

	-- //TODO - handle boosts

	return fpsCalc, nextLvlFPS
end
-- //!SECTION

-- //SECTION - Handling Fish
function Boat:StartFishing()
	self.FishingInterval = SetInterval(function()
		if not self:IsStorageFull() then
			self:AddFish(self.CurrentFPS)
			self:UpdatePurchaseBoardUI()
		end
	end, 1)
end

function Boat:StopFishing()
	if self.FishingInterval then
		task.cancel(self.FishingInterval)
		self.FishingInterval = nil
	end
end

function Boat:AddFish(amount: number)
	self.FishInStorage += amount

	if self.FishInStorage > self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end
end

function Boat:RemoveFish(amount: number)
	self.FishInStorage = math.max(self.FishInStorage :: number - amount, 0)
	self:UpdateStorageStatus(false)
end

function Boat:UpdateStorageStatus(status)
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - UI Setup
function Boat:Initialize()
	-- Handle visibility based on purchase status
	if not self.isPurchased then
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

function Boat:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
	pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel
	pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame

	if pbDetails then
		local upgradeStage = self.UpgradeStage
		local level = self.Level
		local qualityInfo = FFGEnum.QUALITY[upgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not self.isPurchased then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = self:GetName()
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = self.isPurchased and "Level: " .. level or "Purchase Boat"

		-- STORAGE Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and FormatNumber(nextStorage) or ""

		-- FPS Stats
		local currentFPS, nextFPS = self:CalculateFPS()
		pbDetails.CurrentFPSLabel.Text = self.isPurchased and FormatNumber(currentFPS) or ""
		pbDetails.NextFPSLabel.Text = self.isPurchased and FormatNumber(nextFPS) or ""

		-- Storage Progress Bar
		local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
		pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
	end

	return purchaseBoard
end

function Boat:UpdatePurchaseBoardUI()
	local isPurchased = self.isPurchased
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
	pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel
	pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and FormatNumber(self.NextLvlMaxStorage) or ""
	pbDetails.CurrentFPSLabel.Text = isPurchased and FormatNumber(self.CurrentFPS) or ""
	pbDetails.NextFPSLabel.Text = isPurchased and FormatNumber(self.NextFPS) or ""

	local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
	pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)

	local level = self.Level
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self.UpgradeStage

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

function Boat:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if boat is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)

	-- Handle not showing the prompt if the user is not the owner
	proximityPrompt.PromptShown:Connect(function(player: Player)
		if player.UserId ~= self.Owner then return end
	end)

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
		-- Check max level again
		if self.Level == self.MaxLevel then return end

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, self.UpgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", self.UpgradeCost)
			self:UpdateProximityPromptUI(proximityPrompt)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, self.UpgradeCost)

		if self.isPurchased then
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

		DataService.SaveBoatState(player, self.Id, self:Serialize())
	end)

	return proximityPrompt
end

function Boat:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
	else
		proximityPrompt.ObjectText = self.isPurchased and "Upgrade Boat" or "Purchase"
		proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)
	end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Boat:Show()
	local model = self.Model :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function Boat:Hide()
	local model = self.Model :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

function Boat:CanCollide()
	local model = self.Model :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function Boat:CannotCollide()
	local model = self.Model :: Model
	local boatParts = model:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end
-- //!SECTION

-- //SECTION -  Boat Utilities
function Boat:GetName()
	return NAME[self.UpgradeStage]
end

function Boat:CanUpgrade()
	return self.Level < self.MaxLevel
end

function Boat:IsStorageFull()
	local status = self.FishInStorage == self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Boat:Serialize()
	return {
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
		BaseStorage = self.BaseStorage,
		UpgradeStage = self.UpgradeStage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
		BaseFPS = self.BaseFPS,
		CurrentFPS = self.CurrentFPS,
		NextFPS = self.NextFPS,
	}
end
-- //!SECTION

return Boat
