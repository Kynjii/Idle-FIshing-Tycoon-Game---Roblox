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
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
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
local DESCRIPTION = "A sturdy fishing boat, your faithful companion at sea. \n\n- Passively catches fish each second (FPS)."

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Boat,
	RealmId = 1,
	Tier = 1,
	Name = "Fishing Boat",
	Level = 1,
	MaxLevel = Formulas.MAX_LEVEL,
	BaseCost = Formulas.BOAT.BaseCost,
	IsPurchased = false,
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
function Boat.New(state: { [string]: any }?, player: Player, model: Model, teamId: number): Boat
	local self = setmetatable({} :: BoatData, Boat)

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		self[key] = value
	end

	-- Override with provided state values
	if state then
		for key: string, value: any in pairs(state) do
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

	-- Warnings
	self.ClonedBillboard = nil

	self._cleaner = Trove.new()

	self:AttachEventListeners()

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
	self.IsPurchased = true
	if self.Model.PrimaryPart then self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.IsPurchased, true) end

	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()

	if self.Tier == 1 then Tutorial.Update(self.Player, self.TeamId) end
end

function Boat.Upgrade(self: Boat): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage: number = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then
		self:IncreaseUpgradeStage(stage)
		self:UpdateVisualModel()
	end

	self:UpdateBuffs()
	self.CurrentFPS, self.NextFPS = self:CalculateFPS()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Boat.IncreaseUpgradeStage(self: Boat, stage: number): ()
	self.UpgradeStage = stage
end
-- //!SECTION

-- //SECTION - Calculations
function Boat.CalculateBaseCost(self: Boat): number
	local base: number = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Boat.CalculateUpgradeCost(self: Boat): number
	local baseCost: number = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost: number = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level, self.Tier, self.RealmId)

	self.UpgradeCost = cost

	return cost
end

function Boat.CalculateBaseStorage(self: Boat): number
	local base: number = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Boat.CalculateMaxStorage(self: Boat): (number, number)
	local baseStorage: number = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end
	local storagePercentBuff = self.Buffs[BOAT_BUFFS.BoatStorage_Percent] and self.Buffs[BOAT_BUFFS.BoatStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end

function Boat.CalculateBaseFPS(self: Boat): number
	local base: number = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseFPS, self.Tier, self.RealmId)
	self.BaseFPS = base

	return base
end

function Boat.CalculateFPS(self: Boat): (number, number)
	local baseFPS: number = self.BaseFPS or DEFAULTS.BaseFPS
	if baseFPS == DEFAULTS.BaseFPS then baseFPS = self:CalculateBaseFPS() end
	local fpsPercentBuff = self.Buffs[BOAT_BUFFS.FPS_Percent] and self.Buffs[BOAT_BUFFS.FPS_Percent].CurrentValue or nil

	return ClassCalculators.CalculateFPS(baseFPS, self.Level, fpsPercentBuff)
end
-- //!SECTION

-- //SECTION - Handling Fish
function Boat.StartFishing(self: Boat): ()
	if self._cleaner then self._cleaner:Add(SetInterval(function()
		if not self:IsStorageFull() then
			self:AddFish(self.CurrentFPS)
			self:UpdatePurchaseBoardUI()
		else
			self:UpdateStorageStatus(true)
		end
	end, 1)) end
end

function Boat.AddFish(self: Boat, amount: number): ()
	local availableStorage: number = self.CurrentMaxStorage - self.FishInStorage
	local calcAmount: number = math.min(availableStorage, amount)

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

	if self.IsPurchased then task.delay(1, function()
		self:StartFishing()
	end) end
end

function Boat.SetupPurchaseBoard(self: Boat): (Model, { [string]: any })
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board") :: Model

	return PurchaseBoard.CreatePB(purchaseBoard, self :: any)
end

function Boat.UpdatePurchaseBoardUI(self: Boat, reset: boolean?): ()
	if reset then
		PurchaseBoard.ResetPB(self.PurchaseBoard)
	else
		PurchaseBoard.UpdatePB(self :: any)
	end
end

function Boat.SetupProximityPrompt(self: Boat, purchaseBoard: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = purchaseBoard

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end

function Boat.ShowFishPopUp(self: Boat, amount: number): ()
	local billboard: BillboardGui = game.Workspace:FindFirstChild("BillBoards"):FindFirstChild("FishPopupTemplate")
	if not billboard then return end

	local primaryPart: BasePart? = self.Model.PrimaryPart
	if not primaryPart then return end

	local clone: BillboardGui = billboard:Clone()
	local container: Instance? = primaryPart:FindFirstChild("Billboard")
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
	if self.ClonedBillboard then return end

	local billboard: BillboardGui = game.Workspace.BillBoards:FindFirstChild("StorageFullAlert", true)
	if billboard and self.PurchaseBoard.PrimaryPart then
		local clone: BillboardGui = billboard:Clone()
		clone.Parent = self.PurchaseBoard.PrimaryPart
		clone.Adornee = self.PurchaseBoard.PrimaryPart
		clone.Name = "StorageFullAlert_Clone"

		local canvasGroup = clone:FindFirstChild("CanvasGroup") :: CanvasGroup
		canvasGroup.Visible = true

		self.ClonedBillboard = clone
	end
end

function Boat.DestroyStorageFullBillboard(self: Boat): ()
	if not self.ClonedBillboard then return end

	self.ClonedBillboard:Destroy()
	self.ClonedBillboard = nil
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
function Boat.CanUpgrade(self: Boat): boolean
	return self.Level < self.MaxLevel
end

function Boat.IsStorageFull(self: Boat): boolean
	local status: boolean = self.FishInStorage == self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
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
		IsPurchased = self.IsPurchased,
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

	local sortedModels: { Model } = {}
	for k, v in pairs(models) do
		sortedModels[tonumber(v.Name)] = v
	end

	return sortedModels
end

function Boat.RemovePreviousVisualModel(self: Boat): ()
	local visualModel: Model? = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Boat.UpdateVisualModel(self: Boat): ()
	self:RemovePreviousVisualModel()

	if not self.VisualModels then return end
	local templateModel: Model = self.VisualModels[self.UpgradeStage]
	if not templateModel then return end
	local updatedModel: Model = templateModel:Clone()

	updatedModel.Name = templateModel.Name .. "_Clone"
	updatedModel.Parent = self.VisualRoot
	updatedModel:PivotTo(self.VisualRoot.CFrame)

	for _, part: Instance in pairs(updatedModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local weld: WeldConstraint = Instance.new("WeldConstraint")
			weld.Parent = part
			weld.Part0 = part
			weld.Part1 = self.VisualRoot
			part.Anchored = false

			if self.IsPurchased and part.Name ~= "Base" then FadeEffect.In(part) end
		end
	end

	if self.VisualRoot.Anchored == true then self.VisualRoot.Anchored = false end

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
	for name: string, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Boat.Destroy(self: Boat)
	self:Hide()
	self:CannotCollide()
	self:RemovePreviousVisualModel()
	self:UpdatePurchaseBoardUI(true)
	self:DestroyStorageFullBillboard()

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
