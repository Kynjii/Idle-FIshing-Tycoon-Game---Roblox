local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local PopUp = require(ServerScriptService.Server.Modules.Tweens.PopUp)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local BuffType = require(ReplicatedStorage.Shared.Types.BuffType)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)

-- //SECTION - Boat Types
type BoatInstance = BoatType.BoatInstance
type BoatData = BoatType.BoatData
type BuffState = BuffType.BuffState
-- //!SECTION

-- //SECTION - Boat Data
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

local DESCRIPTION = "A sturdy fishing boat, your faithful companion at sea. \n\n- Passively catches fish each second (FPS)."

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Boat,
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
}

local ANIMATIONS = {
	WaterBob = "WaterBob",
}

local BOAT_BUFFS = {
	BoatStorage_Percent = FFGEnum.BUFFS.STORAGE.Boat_Percent,
	FPS_Percent = FFGEnum.BUFFS.FPS.FPS_Percent,
}
-- //!SECTION

local Boat = {}
Boat.__index = Boat

type Boat = typeof(setmetatable({} :: BoatData, Boat))

-- //SECTION - Constructor
function Boat.New(state: { [string]: any }?, player: Player, model: Model): Boat
	local self = setmetatable({} :: BoatData, Boat)

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
	self.VisualRoot = model:FindFirstChild("VisualRoot", true)
	self.Name = self:GetName()
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.Buffs = self:GetBuffs()

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()
	self.BaseFPS = self:CalculateBaseFPS()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentFPS, self.NextFPS = self:CalculateFPS()

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()

	self:AttachEventListeners()

	self._cleaner = Trove.new()

	self.FishingInterval = nil

	self:UpdateVisualModel()
	self:StartAnimation()

	return self
end
-- //!SECTION

-- //SECTION - Buffs
function Boat.GetBuffs(self: Boat)
	return Buffs.GetBuffs(self.Player, BOAT_BUFFS)
end

function Boat.UpdateBuffs(self: Boat): ()
	self.Buffs = self:GetBuffs()
end

function Boat.RecalculateAll(self: Boat): ()
	self:UpdateBuffs()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseFPS = self:CalculateBaseFPS()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentFPS, self.NextFPS = self:CalculateFPS()

	self:UpdatePurchaseBoardUI()
end
-- //!SECTION

-- //SECTION - Core Boat Actions
function Boat.Purchase(self: Boat): ()
	self.isPurchased = true
	if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, true) end

	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()
end

function Boat.Upgrade(self: Boat): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			self:UpdateVisualModel()
			break
		end
	end

	self:UpdateBuffs()
	self.CurrentFPS, self.NextFPS = self:CalculateFPS()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Boat.IncreaseUpgradeStage(self: Boat, stage: number): ()
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Boat.CalculateBaseCost(self: Boat): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Boat.CalculateUpgradeCost(self: Boat): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end

function Boat.CalculateBaseStorage(self: Boat): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Boat.CalculateMaxStorage(self: Boat): (number, number)
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end
	local storagePercentBuff = self.Buffs[BOAT_BUFFS.BoatStorage_Percent] and self.Buffs[BOAT_BUFFS.BoatStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end

function Boat.CalculateBaseFPS(self: Boat): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseFPS, self.Tier, self.RealmId)
	self.BaseFPS = base

	return base
end

function Boat.CalculateFPS(self: Boat): (number, number)
	local baseFPS = self.BaseFPS or DEFAULTS.BaseFPS
	if baseFPS == DEFAULTS.BaseFPS then baseFPS = self:CalculateBaseFPS() end
	local fpsPercentBuff = self.Buffs[BOAT_BUFFS.FPS_Percent] and self.Buffs[BOAT_BUFFS.FPS_Percent].CurrentValue or nil

	return ClassCalculators.CalculateFPS(baseFPS, self.Level, fpsPercentBuff)
end
-- //!SECTION

-- //SECTION - Handling Fish
function Boat.StartFishing(self: Boat): ()
	self.FishingInterval = SetInterval(function()
		if not self:IsStorageFull() then
			self:AddFish(self.CurrentFPS)
			self:UpdatePurchaseBoardUI()
		else
			self:UpdateStorageStatus(true)
		end
	end, 1)
	if self.FishingInterval and self._cleaner then self._cleaner:Add(self.FishingInterval) end
end

function Boat.AddFish(self: Boat, amount: number): ()
	local availableStorage = self.CurrentMaxStorage - self.FishInStorage
	local calcAmount = math.min(availableStorage, amount)

	self.FishInStorage += calcAmount

	self:ShowFishPopUp(calcAmount)
	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:Save()
end

function Boat.RemoveFish(self: Boat, amount: number): ()
	self.FishInStorage -= amount
	self:UpdateStorageStatus(false)
	self:Save()
end

function Boat.UpdateStorageStatus(self: Boat, status: boolean): ()
	self.StorageFull = status

	if status then
		self:ShowStorageFullBillboard()
	else
		self:DestroyStorageFullBillboard()
	end
end
-- //!SECTION

-- //SECTION - UI Setup
function Boat.Initialize(self: Boat): ()
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

	if self.isPurchased then task.delay(1, function()
		self:StartFishing()
	end) end
end

function Boat.SetupPurchaseBoard(self: Boat): (Model, { [string]: any })
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board") :: Model

	return PurchaseBoard.CreatePB(purchaseBoard, self :: any)
end

function Boat.UpdatePurchaseBoardUI(self: Boat): ()
	PurchaseBoard.UpdatePB(self :: any)
end

function Boat.SetupProximityPrompt(self: Boat, purchaseBoard: Model): ()
	local proximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Parent = purchaseBoard
	if self._cleaner then self._cleaner:Add(proximityPrompt) end

	return ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end

function Boat.ShowFishPopUp(self: Boat, amount: number): ()
	local billboard = self.Model:FindFirstChild("FishPopupTemplate", true) :: BillboardGui?
	if not billboard then return end

	local primaryPart = self.Model.PrimaryPart
	if not primaryPart then return end

	local clone = billboard:Clone()
	local container = primaryPart:FindFirstChild("Billboard")
	if container then
		clone.Parent = container
	else
		clone.Parent = primaryPart
	end

	clone.Adornee = primaryPart
	clone.Name = "Popup_Clone"
	PopUp.Animate(clone, amount, clone.Fish)
end

function Boat.ShowStorageFullBillboard(self: Boat): ()
	local billboard: BillboardGui = game.Workspace.BillBoards:FindFirstChild("StorageFullAlert", true)
	local existing = self.PurchaseBoard:FindFirstChild("StorageFullAlert_Clone", true)
	if billboard and not existing then
		local clone: BillboardGui = billboard:Clone()
		clone.Parent = self.PurchaseBoard.PrimaryPart
		if self.PurchaseBoard.PrimaryPart then clone.Adornee = self.PurchaseBoard.PrimaryPart end
		clone.Name = "StorageFullAlert_Clone"

		local canvasGroup = clone:FindFirstChild("CanvasGroup") :: CanvasGroup
		canvasGroup.Visible = true
	end
end

function Boat.DestroyStorageFullBillboard(self: Boat): ()
	local clonedBillboard = nil
	if self.Model then clonedBillboard = self.Model:FindFirstChild("StorageFullAlert_Clone", true) end

	if clonedBillboard then clonedBillboard:Destroy() end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Boat.Show(self: Boat): ()
	ClassVisualizer.Show(self.VisualRoot)
end

function Boat.Hide(self: Boat): ()
	ClassVisualizer.Hide(self.VisualRoot)
end

function Boat.CanCollide(self: Boat): ()
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Boat.CannotCollide(self: Boat): ()
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION -  Boat Utilities
function Boat.GetName(self: Boat): string
	return NAME[self.UpgradeStage]
end

function Boat.CanUpgrade(self: Boat): boolean
	return self.Level < self.MaxLevel
end

function Boat.IsStorageFull(self: Boat): boolean
	local status = self.FishInStorage == self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end

function Boat.ShowUpgradeStageUpgrade(self: Boat): boolean
	local nextStart = Formulas.PROMO_LEVEL[self.UpgradeStage + 1]
	if not nextStart then return false end
	return self.Level == (nextStart - 1)
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Boat.Serialize(self: Boat): { [string]: any }
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
		BaseFPS = self.BaseFPS,
		CurrentFPS = self.CurrentFPS,
		NextFPS = self.NextFPS,
	}
end

function Boat.Save(self: Boat): ()
	DataService.SaveBoatState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Boat.GetVisualModels(self: Boat): { [number]: Model }
	local modelsFolder = DeepWait(game.Workspace, "Boats", "VisualStages")
	local models = modelsFolder:GetChildren()

	local sortedModels = {}
	for k, v in pairs(models) do
		sortedModels[tonumber(v.Name)] = v
	end

	return sortedModels
end

function Boat.RemovePreviousVisualModel(self: Boat): ()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Boat.UpdateVisualModel(self: Boat): ()
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

			if self.isPurchased and part.Name ~= "Base" then FadeEffect.In(part) end
		end
	end

	self.CurrentVisualModel = updatedModel
end
-- //!SECTION

-- //SECTION - Animations
function Boat.StartAnimation(self: Boat): ()
	local animator: Animator = DeepWait(self.Model, "Boat", "AnimationController", "Animator")
	local animation: Animation = Animator.GetAnimation(ANIMATIONS.WaterBob)

	if animator then
		local animationTrack: AnimationTrack
		if self._cleaner then
			animationTrack = self._cleaner:Add(animator:LoadAnimation(animation))
		else
			animationTrack = animator:LoadAnimation(animation)
		end
		animationTrack.Looped = true

		task.wait(math.random(0.5, 1.5))
		animationTrack:Play()
	end
end
-- //!SECTION

-- //SECTION - Event Listeners
function Boat.AttachEventListeners(self: Boat)
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function Boat.ClearAllAttributes(self: Boat, instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Boat.Destroy(self: Boat)
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	self:ClearAllAttributes(self.Model.PrimaryPart)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return Boat
