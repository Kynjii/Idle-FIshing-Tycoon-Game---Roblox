local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local TweenService = game:GetService("TweenService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local BuffType = require(ReplicatedStorage.Shared.Types.BuffType)
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local PopUp = require(ServerScriptService.Server.Modules.Tweens.PopUp)

-- //SECTION - Tender Types
type TenderInstance = TenderType.TenderInstance
type TenderData = TenderType.TenderData
type BuffState = BuffType.BuffState
-- //!SECTION

-- //SECTION -  Tender Data
local DESCRIPTION = "A nimble Tender, darting back and forth between port and sea. \n\n- Delivers your boat’s Fish with travel and load times that improve as you upgrade."

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Tender,
	RealmId = 1,
	Tier = 1,
	Name = "Transporter",
	Level = 1,
	MaxLevel = Formulas.MAX_LEVEL,
	BaseCost = Formulas.TENDER.BaseCost,
	IsPurchased = false,
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

local Tender = {}
Tender.__index = Tender

type Tender = typeof(setmetatable({} :: TenderData, Tender))

-- //SECTION - Constructor
function Tender.New(state: { [string]: any }?, player: Player, model: Model, teamId: number): Tender
	local self = setmetatable({} :: TenderData, Tender)

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
	self.TeamId = teamId
	self.Description = DESCRIPTION
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Entity = self.Entity or DEFAULTS.Entity
	self.VisualRoot = model:FindFirstChild("VisualRoot", true)
	self.PortPos = model.PrimaryPart and model.PrimaryPart.CFrame or CFrame.new()
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

	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()

	-- Warnings
	self.ClonedBillboard = nil

	-- Tweens
	self.ProgressTween = nil
	self.MoveTween = nil

	self._cleaner = Trove.new()

	self:AttachEventListeners()
	return self
end
-- //!SECTION

-- //SECTION - Buffs
function Tender.GetBuffs(self: Tender)
	local buffs = Buffs.GetBuffs(self.Player, TENDER_BUFFS)
	return buffs
end

function Tender.UpdateBuffs(self: Tender)
	self.Buffs = self:GetBuffs()
end

function Tender.RecalculateAll(self: Tender)
	self:UpdateBuffs()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.LoadTime = self:CalculateLoadTime()
	self.CurrentTravelTime = self:CalculateTravelTime()

	self:UpdatePurchaseBoardUI()
end
-- //!SECTION

-- //SECTION - Core Tender Actions
function Tender.Purchase(self: Tender)
	self.IsPurchased = true
	if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.IsPurchased, true) end

	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()

	if self.Tier == 1 then Tutorial.Update(self.Player, self.TeamId) end
end

function Tender.Upgrade(self: Tender)
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then
		self:IncreaseUpgradeStage(stage)
		self:UpdateVisualModel()
		self.CurrentTravelTime = self:CalculateTravelTime()
		self.LoadTime = self:CalculateLoadTime()
	end

	self:UpdateBuffs()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Tender.IncreaseUpgradeStage(self: Tender, stage: number)
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Tender.CalculateBaseCost(self: Tender): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Tender.CalculateUpgradeCost(self: Tender): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level, self.Tier, self.RealmId)

	self.UpgradeCost = cost

	return cost
end

function Tender.CalculateBaseStorage(self: Tender): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Tender.CalculateMaxStorage(self: Tender): (number, number)
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end
	local storagePercentBuff = self.Buffs[TENDER_BUFFS.TenderStorage_Percent] and self.Buffs[TENDER_BUFFS.TenderStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end

function Tender.CalculateTravelTime(self: Tender): number
	local travelTimeBuff = self.Buffs[TENDER_BUFFS.TenderTravelTime_Percent] and self.Buffs[TENDER_BUFFS.TenderTravelTime_Percent].CurrentValue or nil
	return ClassCalculators.CalculateTravelTime(DEFAULTS.BaseTravelTime, travelTimeBuff)
end

function Tender.CalculateLoadTime(self: Tender): number
	local loadTimeBuff = self.Buffs[TENDER_BUFFS.TenderLoadTime_Percent] and self.Buffs[TENDER_BUFFS.TenderLoadTime_Percent].CurrentValue or nil
	return ClassCalculators.CalculateLoadTime(DEFAULTS.BaseLoadTime, loadTimeBuff)
end
-- //!SECTION

-- //SECTION - Handle Travelling
function Tender.MoveToBoat(self: Tender, boatPos: CFrame)
	if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, false) end

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

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	self.MoveTween = tween
	if self._cleaner then
		self._cleaner:Add(tween)

		self._cleaner:Add(tween.Completed:Once(function(playbackState)
			if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, true) end
			if self.MoveTween == tween then self.MoveTween = nil end
		end))
	end

	tween:Play()
end

function Tender.MoveToPort(self: Tender)
	if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atBoat, false) end

	if self.MoveTween then pcall(function()
		self.MoveTween:Cancel()
		self.MoveTween = nil
	end) end

	local tenderModel = self.Model
	local portPos = self.PortPos

	local tweenGoal = {
		CFrame = portPos,
	}

	local tweenInfo = TweenInfo.new(self.CurrentTravelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(tenderModel.PrimaryPart, tweenInfo, tweenGoal)

	self.MoveTween = tween
	if self._cleaner then
		self._cleaner:Add(tween)

		self._cleaner:Add(tween.Completed:Once(function(playbackState)
			if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, true) end
			if self.MoveTween == tween then self.MoveTween = nil end
		end))
	end

	tween:Play()
end

function Tender.AddFish(self: Tender, amount: number)
	if self:IsStorageFull() then return end

	self.FishInStorage += amount

	self:ShowFishPopUp(amount)

	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:UpdatePurchaseBoardUI()
	self:Save()
end

function Tender.RemoveFish(self: Tender, amount: number)
	self.FishInStorage = math.max(self.FishInStorage - amount, 0)

	self:UpdateStorageStatus(false)
	self:UpdatePurchaseBoardUI()
	self:Save()
end

function Tender.UpdateStorageStatus(self: Tender, status: boolean)
	self.StorageFull = status
end
-- //!SECTION

-- //SECTION - UI Setup
function Tender.Initialize(self: Tender)
	-- Handle visibility based on purchase status
	if not self.IsPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	self:UpdateVisualModel()
	self:StartAnimation()

	-- Setup UI components
	if self.PurchaseBoard then self:SetupProximityPrompt(self.PurchaseBoard) end

	-- Apply attributes for ChainManager
	if self.IsPurchased then
		if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.IsPurchased, self.IsPurchased) end
	end
end

function Tender.SetupPurchaseBoard(self: Tender): (Model, { [string]: any })
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	return PurchaseBoard.CreatePB(purchaseBoard, self :: any)
end

function Tender.UpdatePurchaseBoardUI(self: Tender, reset: boolean?)
	if reset then
		PurchaseBoard.ResetPB(self.PurchaseBoard)
	else
		PurchaseBoard.UpdatePB(self :: any)
	end
end

function Tender.SetupProximityPrompt(self: Tender, purchaseBoard: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = purchaseBoard

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end

function Tender.ShowFishPopUp(self: Tender, amount: number)
	if not self.Model then return end

	local billboard: BillboardGui = game.Workspace:FindFirstChild("BillBoards"):FindFirstChild("FishPopupTemplate")
	if billboard and self.Model.PrimaryPart then
		local billboardFolder = self.Model.PrimaryPart:FindFirstChild("Billboard")
		if billboardFolder then
			local clone = billboard:Clone()
			clone.Parent = billboardFolder
			clone.Adornee = self.Model.PrimaryPart
			clone.Name = "Popup_Clone"
			PopUp.Animate(clone, amount, clone.Fish)
		end
	end
end

function Tender.ShowTenderStoppedBillboard(self: Tender): ()
	if self.ClonedBillboard then return end

	local billboard: BillboardGui = game.Workspace.BillBoards:FindFirstChild("TenderStopped", true)
	if billboard and self.PurchaseBoard.PrimaryPart then
		local clone: BillboardGui = billboard:Clone()
		clone.Parent = self.PurchaseBoard.PrimaryPart
		clone.Adornee = self.PurchaseBoard.PrimaryPart
		clone.Name = "TenderStopped_Clone"

		local canvasGroup: CanvasGroup = clone:FindFirstChild("CanvasGroup") :: CanvasGroup
		canvasGroup.Visible = true

		self.ClonedBillboard = clone
	end
end

function Tender.DestroyTenderStoppedBillboard(self: Tender): ()
	if not self.ClonedBillboard then return end

	self.ClonedBillboard:Destroy()
	self.ClonedBillboard = nil
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Tender.Show(self: Tender)
	ClassVisualizer.Show(self.VisualRoot)
end

function Tender.Hide(self: Tender)
	ClassVisualizer.Hide(self.VisualRoot)
end

function Tender.CanCollide(self: Tender)
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Tender.CannotCollide(self: Tender)
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION - Tender Utilities
function Tender.CanUpgrade(self: Tender): boolean
	return self.Level < self.MaxLevel
end

function Tender.IsStorageFull(self: Tender): boolean
	local status = self.FishInStorage >= self.CurrentMaxStorage
	self:UpdateStorageStatus(status)
	return status
end

function Tender.ShowUpgradeStageUpgrade(self: Tender): boolean
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
function Tender.Serialize(self: Tender): { [string]: any }
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
		BaseStorage = self.BaseStorage,
		UpgradeStage = self.UpgradeStage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
		CurrentTravelTime = self.CurrentTravelTime,
		LoadTime = self.LoadTime,
	}
end

function Tender.Save(self: Tender)
	DataService.SaveTenderState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Tender.GetVisualModels(self: Tender): { [number]: Model }
	local modelsFolder = DeepWait(game.Workspace, "Tenders", "VisualStages")
	local models = modelsFolder:GetChildren()

	local sortedModels = {}
	for k, v in pairs(models) do
		sortedModels[tonumber(v.Name)] = v
	end

	return sortedModels
end

function Tender.RemovePreviousVisualModel(self: Tender)
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Tender.UpdateVisualModel(self: Tender)
	self:RemovePreviousVisualModel()

	if not self.VisualModels then return end
	local templateModel = self.VisualModels[self.UpgradeStage]
	if not templateModel then return end
	local updatedModel = templateModel:Clone()

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

	if self.VisualRoot.Anchored == true then self.VisualRoot.Anchored = false end

	self.CurrentVisualModel = updatedModel
end
-- //!SECTION

-- //SECTION - Animations
function Tender.StartAnimation(self: Tender)
	local animator: Animator = DeepWait(self.Model, "Tender", "AnimationController", "Animator")
	local animation: Animation = Animator.GetAnimation(ANIMATIONS.WaterBob)

	local animationTrack = animator:LoadAnimation(animation)
	if not animationTrack then return end

	if self._cleaner then self._cleaner:Add(animationTrack) end
	animationTrack.Looped = true

	task.wait(math.random(0.5, 1.5))
	animationTrack:Play()
end
-- //!SECTION

-- //SECTION - Event Listeners
function Tender.AttachEventListeners(self: Tender)
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function Tender.ClearAllAttributes(self: Tender, instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		instance:SetAttribute(name, nil)
	end
end

function Tender.Destroy(self: Tender)
	self:MoveToPort()
	self:Hide()
	self:CannotCollide()
	self:RemovePreviousVisualModel()
	self:UpdatePurchaseBoardUI(true)
	self:DestroyTenderStoppedBillboard()

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
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end

-- //!SECTION

return Tender
