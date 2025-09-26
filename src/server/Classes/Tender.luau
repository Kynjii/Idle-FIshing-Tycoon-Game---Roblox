local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local TweenService = game:GetService("TweenService")
local BuffType = require(ReplicatedStorage.Shared.Types.BuffType)
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local ProgressBar = require(ServerScriptService.Server.Modules.Tweens.ProgressBar)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local PopUp = require(ServerScriptService.Server.Modules.Tweens.PopUp)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Tender Types
type Tender = TenderType.Tender
type TenderProps = TenderType.TenderProps
type TenderInstance = TenderType.TenderInstance
type BuffState = BuffType.BuffState
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

local DESCRIPTION = "A Supply Vessel, it transports caught Fish back to Port over time."

local DEFAULTS: TenderProps = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Tender,
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
	BaseLoadTime = 10, -- secs
}

local ANIMATIONS = {
	WaterBob = "WaterBob",
}

local TENDER_BUFFS = {
	TenderStorage_Percent = FFGEnum.BUFFS.STORAGE.Tender_Percent,
	TenderTravelTime_Percent = FFGEnum.BUFFS.TRAVEL_TIME.Tender_Percent,
	TenderLoadTime_Percent = FFGEnum.BUFFS.LOAD_TIME.Tender_Percent,
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
	self.Description = DESCRIPTION
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Entity = self.Entity or DEFAULTS.Entity
	self.VisualRoot = DeepWait(model, "Tender", "VisualRoot")
	self.PortPos = model.PrimaryPart.CFrame
	self.Name = self:GetName()
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.Buffs = self:GetBuffs()

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	-- Storage calcs
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	-- Load Time calcs
	self.LoadTime = self:CalculateLoadTime()

	-- Travel Time calcs
	self.CurrentTravelTime = self:CalculateTravelTime()

	-- Progress Bars
	self.BillBoard = DeepWait(self.Model, "Tender", "Base", "Billboard", "BillboardGui")
	self.ProgressBar = DeepWait(self.BillBoard, "ProgressBarBG", "ProgressBar")

	self.PurchaseBoard, self.PBDetails = nil

	-- Tweens
	self.ProgressTween = nil
	self.MoveTween = nil

	self._cleaner = CleanerService.new()

	self:UpdateVisualModel()
	self:StartAnimation()

	return self
end
-- //!SECTION

-- //SECTION - Buffs
function Tender:GetBuffs()
	return Buffs.GetBuffs(self.Player, TENDER_BUFFS)
end

function Tender:UpdateBuffs()
	self.Buffs = self:GetBuffs()
end

function Tender:RecalculateAll()
	self:UpdateBuffs()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.LoadTime = self:CalculateLoadTime()
	self.CurrentTravelTime = self:CalculateTravelTime()

	self:UpdatePurchaseBoardUI()
end
-- //!SECTION

-- //SECTION - Core Tender Actions
function Tender:Purchase()
	self.isPurchased = true
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, true)

	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()
end

function Tender:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			self:UpdateVisualModel()
			self.CurrentTravelTime = self:CalculateTravelTime()
			self.LoadTime = self:CalculateLoadTime()
			break
		end
	end

	self:UpdateBuffs()
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
	local storagePercentBuff = self.Buffs[TENDER_BUFFS.TenderStorage_Percent] and self.Buffs[TENDER_BUFFS.TenderStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end

function Tender:CalculateTravelTime()
	local travelTimeBuff = self.Buffs[TENDER_BUFFS.TenderTravelTime_Percent] and self.Buffs[TENDER_BUFFS.TenderTravelTime_Percent].CurrentValue or nil
	return ClassCalculators.CalculateTravelTime(DEFAULTS.BaseTravelTime, travelTimeBuff)
end

function Tender:CalculateLoadTime()
	local loadTimeBuff = self.Buffs[TENDER_BUFFS.TenderLoadTime_Percent] and self.Buffs[TENDER_BUFFS.TenderLoadTime_Percent].CurrentValue or nil
	return ClassCalculators.CalculateLoadTime(DEFAULTS.BaseLoadTime, loadTimeBuff)
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

	self.FishInStorage += amount

	self:ShowFishPopUp(amount)

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
	-- Handle visibility based on purchase status
	if not self.isPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	-- Setup UI components
	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()
	if self.PurchaseBoard then self:SetupProximityPrompt(self.PurchaseBoard) end

	-- Apply attributes for ChainManager
	if self.isPurchased then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, self.isPurchased) end
end

function Tender:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	return PurchaseBoard.CreatePB(purchaseBoard, self)
end

function Tender:UpdatePurchaseBoardUI()
	PurchaseBoard.UpdatePB(self)
end

function Tender:SetupProximityPrompt(purchaseBoard: Model)
	local proximityPrompt = self._cleaner:add(Instance.new("ProximityPrompt", purchaseBoard))

	return ProximityPrompt.CreatePP(proximityPrompt, self)
end

function Tender:ShowFishPopUp(amount)
	local billboard: BillboardGui = self.Model.PrimaryPart.Billboard:WaitForChild("BoatPopupTemplate")
	if billboard then
		local clone = billboard:Clone()
		clone.Parent = self.Model.PrimaryPart.Billboard
		clone.Adornee = self.Model.PrimaryPart
		clone.Name = "Popup_Clone"
		PopUp.Animate(clone, amount, clone.Boat)
	end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Tender:Show()
	ClassVisualizer.Show(self.Model.Tender.VisualRoot:GetChildren()[1])
end

function Tender:Hide()
	ClassVisualizer.Hide(self.Model.Tender.VisualRoot:GetChildren()[1])
end

function Tender:CanCollide()
	ClassVisualizer.CanCollide(self.Model.Tender.VisualRoot:GetChildren()[1])
end

function Tender:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.Tender.VisualRoot:GetChildren()[1])
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
	self:UpdateStorageStatus(status)
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
		BaseStorage = self.BaseStorage,
		UpgradeStage = self.UpgradeStage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
		CurrentTravelTime = self.CurrentTravelTime,
	}
end

function Tender:Save()
	DataService.SaveTenderState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Tender:GetVisualModels()
	local modelsFolder = DeepWait(game.Workspace, "Tenders", "VisualStages")
	local models = modelsFolder:GetChildren()

	local templateModels: { [number]: Model } = {}
	for i, model in ipairs(models) do
		templateModels[tonumber(model.Name)] = model
	end

	return templateModels
end

function Tender:RemovePreviousVisualModel()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Tender:UpdateVisualModel()
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

-- //SECTION - Animations
function Tender:StartAnimation()
	local animator: Animator = DeepWait(self.Model, "Tender", "AnimationController", "Animator")
	local animation: Animation = Animator.GetAnimation(ANIMATIONS.WaterBob)

	local animationTrack: AnimationTrack = self._cleaner:add(animator:LoadAnimation(animation))
	animationTrack.Looped = true

	task.wait(math.random(0.5, 1.5))
	animationTrack:Play()
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
	self:CannotCollide()

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
