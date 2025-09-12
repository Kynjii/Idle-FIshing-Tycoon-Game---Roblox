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
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local ProgressBar = require(ServerScriptService.Server.Modules.ProgressBar)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Tender Types
type Tender = TenderType.Tender
type TenderProps = TenderType.TenderProps
type TenderInstance = TenderType.TenderInstance
-- //!SECTION

-- //SECTION -  Tender Data
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
	BaseTravelTime = 10, -- secs
}
-- //!SECTION

local Tender = {} :: TenderInstance
Tender.__index = Tender

-- //SECTION - Constructor
function Tender.New(state, player, model)
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
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()

	-- Apply attributes for BoatManager
	if self.isPurchased then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, self.isPurchased) end

	-- Storage calcs
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	-- Travel Time calcs
	self.CurrentTravelTime, self.NextLvlTravelTime = self:CalculateTravelTime()

	-- Progress Bars
	self.BillBoard = DeepWait(self.Model, "Base", "Billboard", "BillboardGui")
	self.ProgressBar = DeepWait(self.BillBoard, "ProgressBarBG", "ProgressBar")

	-- Tweens
	self.ProgressTween = nil
	self.MoveTween = nil

	self._cleaner = CleanerService.new()

	return self
end
-- //!SECTION

-- //SECTION - Core Tender Actions
function Tender:Purchase()
	self.isPurchased = true
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, true)

	self:Save()
end

function Tender:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)

			self.CurrentTravelTime, self.NextLvlTravelTime = self:CalculateTravelTime()
			break
		end
	end

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Tender:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Tender:CalculateBaseCost()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Tender:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end

function Tender:CalculateBaseStorage()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Tender:CalculateMaxStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level)
end

function Tender:CalculateTravelTime()
	return ClassCalculators.CalculateTravelTime(self.BaseTravelTime, self.UpgradeStage)
end
-- //!SECTION

-- //SECTION - Handle Travelling
function Tender:MoveToBoat(boatPos)
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, false)

	-- cancel any existing motion/progress tweens first
	if self.MoveTween then pcall(function()
		self.MoveTween:Cancel()
		self.MoveTween = nil
	end) end

	local tenderModel = self.Model

	local offset = CFrame.new(0, -12, 0)
	local tweenGoal = {
		CFrame = boatPos:ToWorldSpace(offset),
	}

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	self.MoveTween = tween
	self._cleaner:add(tween)

	self._cleaner:add(tween.Completed:Once(function(playbackState)
		self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, true)
		if self.MoveTween == tween then self.MoveTween = nil end
	end))

	tween:Play()
end

function Tender:MoveToPort()
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, false)

	if self.MoveTween then pcall(function()
		self.MoveTween:Cancel()
		self.MoveTween = nil
	end) end

	local tenderModel = self.Model
	local portPos = self.PortPos

	local tweenGoal = {
		CFrame = portPos,
	}

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	self.MoveTween = tween
	self._cleaner:add(tween)

	self._cleaner:add(tween.Completed:Once(function(playbackState)
		self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, true)
		if self.MoveTween == tween then self.MoveTween = nil end
	end))

	tween:Play()
end

function Tender:AddFish(amount)
	if self:IsStorageFull() then
		self:UpdateProgressBar()
		return
	end

	self.FishInStorage += math.max(amount)

	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:UpdateProgressBar()
	self:Save()
end

function Tender:RemoveFish(amount)
	self.FishInStorage = math.max(self.FishInStorage - amount, 0)

	self:UpdateStorageStatus(false)
	self:UpdateProgressBar()
	self:Save()
end

function Tender:UpdateStorageStatus(status)
	self.StorageFull = status
end

function Tender:ShowProgressBar()
	local billboard = self.BillBoard
	if billboard then ProgressBar.Show(billboard) end
end

function Tender:HideProgressBar()
	local billboard = self.BillBoard
	if billboard then ProgressBar.Hide(billboard) end
end

function Tender:UpdateProgressBar()
	if self.ProgressTween then
		pcall(function()
			self.ProgressTween:Cancel()
		end)
		self.ProgressTween = nil
	end

	local tween = ProgressBar.Update(self.ProgressBar, self.FishInStorage, self.CurrentMaxStorage)
	self.ProgressTween = tween

	tween.Completed:Once(function()
		if self.ProgressTween == tween then self.ProgressTween = nil end

		pcall(function()
			tween:Destroy()
		end)
	end)
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
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and "Storage: " .. FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and "Next Lvl Storage: " .. FormatNumber(nextStorage) or ""

		-- TRAVEL TIME Stats
		pbDetails.CurrentTravelTimeLabel.Text = self.isPurchased and "Travel Time: " .. self.CurrentTravelTime or ""
		if self:ShowUpgradeStageUpgrade() then pbDetails.NextTravelTimeLabel.Text = self.isPurchased and self.NextLvlTravelTime or "" end
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

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and "Storage: " .. FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and "Next Lvl Storage: " .. FormatNumber(self.NextLvlMaxStorage) or ""
	pbDetails.CurrentTravelTimeLabel.Text = isPurchased and "Travel Time: " .. FormatNumber(self.CurrentTravelTime) or ""

	local showUpgradeStageUpgrade = self:ShowUpgradeStageUpgrade()
	if showUpgradeStageUpgrade then
		pbDetails.NextTravelTimeLabel.Text = isPurchased and "Next Lvl Travel Time: " .. FormatNumber(self.NextLvlTravelTime)
		pbDetails.NextTravelTimeLabel.Visible = true
	else
		pbDetails.NextTravelTimeLabel.Visible = false
	end

	pbDetails.LevelLabel.Text = "Level: " .. self.Level

	local qualityInfo = FFGEnum.QUALITY[self.UpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

function Tender:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = self._cleaner:add(Instance.new("ProximityPrompt", purchaseBoard))

	-- Check if tender is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Tender" or "Purchase"
	proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)

	-- Handle proximity prompt triggered
	self._cleaner:add(proximityPrompt.Triggered:Connect(function(player)
		if player.UserId ~= self.Owner then return end

		-- Check max level again
		if self.Level == self.MaxLevel then return end

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", not self.isPurchased and self.BaseCost or self.UpgradeCost)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost)

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
	end))

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

function Tender:ShowUpgradeStageUpgrade()
	local threshold = Formulas.PROMO_LEVEL[self.UpgradeStage + 1] - 1
	if self.Level < 9 then return false end
	if self.Level == threshold then
		return true
	else
		return false
	end
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

function Tender:Save()
	DataService.SaveTenderState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Cleanup
function Tender:ClearAllAttributes(instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		instance:SetAttribute(name, nil)
	end
end

function Tender:Destroy()
	self:MoveToPort()
	self:Hide()

	pcall(function()
		self:Save()
	end)

	if self.MoveTween then
		pcall(function()
			self.MoveTween:Cancel()
		end)
		self.MoveTween = nil
	end

	if self.ProgressTween then
		pcall(function()
			self.ProgressTween:Cancel()
		end)
		self.ProgressTween = nil
	end

	self:ClearAllAttributes(self.Model.PrimaryPart)

	if self._cleaner then
		self._cleaner:clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Model = nil
end

-- //!SECTION

return Tender
