local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local TweenService = game:GetService("TweenService")
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)

-- //SECTION - Tender Types
type Tender = TenderType.Tender
type TenderProps = TenderType.TenderProps
type TenderInstance = TenderType.TenderInstance
-- //!SECTION

-- //SECTION -  Tender Data
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

local DEFAULTS: TenderProps = {
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Tender",
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.TENDER.BaseCost,
	isPurchased = false,
	BaseStorage = Formulas.TENDER.BaseStorage,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
	BaseTravelTime = 5, -- secs
	GrowthRate = Formulas.TENDER.GrowthRate,
	CostGrowthRate = Formulas.TENDER.CostGrowthRate,
}
-- //!SECTION

local Tender: TenderInstance = {}
Tender.__index = Tender

-- //SECTION - Constructor
function Tender.New(state, player: Player, model: Model)
	local self: TenderInstance = setmetatable({}, Tender)

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
	self.PortPos = model.PrimaryPart.CFrame
	self.Name = self:GetName()

	-- Had to take this approach for type checking to work
	if self.BaseCost == DEFAULTS.BaseCost then self.BaseCost = self:CalculateBaseCost() end
	if not self.UpgradeCost then self.UpgradeCost = self:CalculateUpgradeCost() end

	-- Apply attributes
	if self.isPurchased then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, self.isPurchased) end

	-- Storage calcs
	local curMaxStorage, nextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentMaxStorage = self.CurrentMaxStorage or curMaxStorage
	self.NextLvlMaxStorage = self.NextLvlMaxStorage or nextLvlMaxStorage

	-- Travel Time calcs
	local curTravelTime, nextLvlTravelTime = self:CalculateTravelTime()
	self.CurrentTravelTime = self.CurrentTravelTime or curTravelTime
	self.NextLvlTravelTime = self.NextLvlTravelTime or nextLvlTravelTime

	return self
end
-- //!SECTION

-- //SECTION - Core Tender Actions
function Tender:Purchase()
	self.isPurchased = true
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, true)
end

function Tender:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(TENDER_PROMOTION_LEVELS) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			break
		end
	end
	self.UpgradeCost = self:CalculateUpgradeCost()

	local curMaxStorage, nextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentMaxStorage = curMaxStorage
	self.NextLvlMaxStorage = nextLvlMaxStorage

	local curTravelTime, nextLvlTravelTime = self:CalculateTravelTime()
	self.CurrentTravelTime = curTravelTime
	self.NextLvlTravelTime = nextLvlTravelTime
end

function Tender:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Tender:CalculateBaseCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local base = baseCost * tierMultiplier * realmMultiplier

	self.BaseCost = base

	return base
end

function Tender:CalculateUpgradeCost(): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local growthRate = DEFAULTS.CostGrowthRate
	local cost = baseCost * math.pow(growthRate, self.Level :: number) * tierMultiplier * realmMultiplier

	-- //TODO - handle boosts

	return cost
end

function Tender:CalculateBaseStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local base = baseStorage * tierMultiplier * realmMultiplier

	self.BaseStorage = base

	return base
end

function Tender:CalculateMaxStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end

	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier] :: number
	local growthRate = DEFAULTS.GrowthRate + self.Tier * 0.02 :: number
	local maxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number) * tierMultiplier :: number
	local nextLvlMaxStorage = baseStorage * math.pow(growthRate :: number, self.Level :: number + 1) * tierMultiplier :: number

	-- //TODO - handle boosts

	return maxStorage, nextLvlMaxStorage
end

function Tender:CalculateTravelTime()
	local baseTime = self.BaseTravelTime

	local travelTime = math.max(0.5, baseTime - self.Level * 0.005)
	local nextLvlTravelTime = travelTime - math.max(0.5, baseTime - (self.Level + 1) * 0.005)

	return travelTime, nextLvlTravelTime
end
-- //!SECTION

-- //SECTION - Handle Travelling
function Tender:MoveToBoat(boatPos: CFrame)
	local tenderModel = self.Model

	local offset = CFrame.new(0, -12, 0)
	local tweenGoal = {
		CFrame = boatPos:ToWorldSpace(offset),
	}

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	tween.Completed:Connect(function(playbackState)
		self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, true)
	end)

	tween:Play()
end

function Tender:MoveToPort()
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, false)

	local tenderModel = self.Model
	local portPos = self.PortPos

	local tweenGoal = {
		CFrame = portPos,
	}

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	tween.Completed:Connect(function(playbackState)
		self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, true)
	end)

	tween:Play()
end

function Tender:AddFish(amount: number)
	FFGHelpers.PrintLog("Adding Fish", amount)
	self.FishInStorage += amount

	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end
end

function Tender:RemoveFish(amount: number)
	self.FishInStorage = math.max(self.FishInStorage - amount, 0)

	self:UpdateStorageStatus(false)
end

function Tender:UpdateStorageStatus(status)
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - UI Setup
function Tender:Initialize()
	-- Setup UI components
	local purchaseBoard = self:SetupPurchaseBoard()
	if purchaseBoard then self:SetupProximityPrompt(purchaseBoard) end

	-- Handle visibility based on purchase status
	if not self.isPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end
end

function Tender:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentTravelTime", "TextLabel") :: TextLabel
	pbDetails.NextTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextTravelTime", "TextLabel") :: TextLabel

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

		pbDetails.LevelLabel.Text = self.isPurchased and "Level: " .. level or "Purchase Tender"

		-- STORAGE Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and FormatNumber(nextStorage) or ""

		-- TRAVEL TIME Stats
		pbDetails.CurrentTravelTimeLabel.Text = self.isPurchased and self.CurrentTravelTime or ""
		pbDetails.NextTravelTimeLabel.Text = self.isPurchased and self.NextLvlTravelTime or ""
	end

	return purchaseBoard
end

function Tender:UpdatePurchaseBoardUI()
	local isPurchased = self.isPurchased
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.CurrentTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentTravelTime", "TextLabel") :: TextLabel
	pbDetails.NextTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextTravelTime", "TextLabel") :: TextLabel

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and FormatNumber(self.NextLvlMaxStorage) or ""
	-- //TODO - Hande updating travel time

	local level = self.Level
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self.UpgradeStage

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

function Tender:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if tender is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Tender" or "Purchase"
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
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, self.UpgradeCost)

		if self.isPurchased then
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

		DataService.SaveTenderState(player, self.Id, self:Serialize())
	end)

	return proximityPrompt
end

function Tender:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
	else
		proximityPrompt.ObjectText = self.isPurchased and "Upgrade Tender" or "Purchase"
		proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)
	end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Tender:Show()
	local model = self.Model :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

function Tender:Hide()
	local model = self.Model :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

function Tender:CanCollide()
	local model = self.Model :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

function Tender:CannotCollide()
	local model = self.Model :: Model
	local tenderParts = model:GetChildren()
	for _, part in pairs(tenderParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end
-- //!SECTION

-- //SECTION - Tender Utilities
function Tender:GetName()
	return NAME[self.UpgradeStage]
end

function Tender:CanUpgrade()
	return self.Level < self.MaxLevel
end

function Tender:IsStorageFull()
	local status = self.FishInStorage >= self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Tender:Serialize(): TenderProps
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
		CurrentTravelTime = self.CurrentTravelTime,
		NextLvlTravelTime = self.NextLvlTravelTime,
	}
end
-- //!SECTION

return Tender
