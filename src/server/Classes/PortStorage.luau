local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local PopUp = require(ServerScriptService.Server.Modules.Tweens.PopUp)
local ResizeFromEdge = require(ServerScriptService.Server.Modules.Tweens.ResizeFromEdge)

-- //SECTION - Types
type StorageInstance = PortStorageType.StorageInstance
type PortStorageData = PortStorageType.PortStorageData
-- //!SECTION

-- //SECTION - Data
local DESCRIPTION = "Timber sheds line the dock, smelling faintly of salt and tar. \n\n- Expands how much fish you can store before selling."

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.PortStorage,
	RealmId = 1,
	Tier = 1,
	Name = "Fish Storage",
	Level = 1,
	MaxLevel = Formulas.MAX_LEVEL,
	BaseCost = Formulas.STORAGE.BaseCost,
	IsPurchased = false,
	BaseStorage = Formulas.STORAGE.BaseStorage,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
}

local PORTSTORAGE_BUFFS = {
	PortStorage_Percent = FFGEnum.BUFFS.STORAGE.Port_Percent,
}
-- //!SECTION

local PortStorage = {}
PortStorage.__index = PortStorage

-- Local type alias for internal method signatures
type PortStorage = typeof(setmetatable({} :: PortStorageData, PortStorage))

-- //SECTION - Constructor
function PortStorage.New(state: { [string]: any }?, player: Player, model: Model, teamId: number): PortStorage
	local self = setmetatable({} :: PortStorageData, PortStorage)

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
	self.Entity = self.Entity or DEFAULTS.Entity
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.VisualRoot = model:FindFirstChild("VisualRoot", true)
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.Buffs = self:GetBuffs()
	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self.TakeFishPrompt = nil

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	self.PurchaseBoard, self.PBDetails = self:SetupPurchaseBoard()

	-- Warnings
	self.ClonedBillboard = nil

	-- Tweens
	self.ProgressTween = nil
	self.FishModel = DeepWait(self.Model, "FishInStorage", "Base")

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end
-- //!SECTION

-- //SECTION - Buffs
function PortStorage.GetBuffs(self: PortStorage)
	return Buffs.GetBuffs(self.Player, PORTSTORAGE_BUFFS)
end

function PortStorage.UpdateBuffs(self: PortStorage)
	self.Buffs = self:GetBuffs()
end

function PortStorage.RecalculateAll(self: PortStorage)
	self:UpdateBuffs()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:UpdatePurchaseBoardUI()
end
-- //!SECTION

-- //SECTION - Core Actions
function PortStorage.Purchase(self: PortStorage): ()
	self.IsPurchased = true

	self.TakeFishPrompt = self:SetupFishRemovalPrompt()
	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()

	if self.Tier == 1 then Tutorial.Update(self.Player, self.TeamId) end
end

function PortStorage.Upgrade(self: PortStorage): ()
	if not self:CanUpgrade() then return end

	self.Level += 1
	local stage = Formulas.StageForLevel(self.Level)
	if self.UpgradeStage < stage then
		self:IncreaseUpgradeStage(stage)
		self:UpdateVisualModel()
	end

	self:UpdateBuffs()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self:IsStorageFull()

	self:Save()
end

function PortStorage.IncreaseUpgradeStage(self: PortStorage, stage: number): ()
	self.UpgradeStage = stage
end

function PortStorage.AddFish(self: PortStorage, amount: number): ()
	local availableStorage: number = self.CurrentMaxStorage - self.FishInStorage
	local calcAmount: number = math.min(availableStorage, amount)

	self.FishInStorage += calcAmount

	self:ShowFishPopUp(calcAmount)
	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:UpdatePurchaseBoardUI()
	self:UpdateFishModel()
end

function PortStorage.RemoveFish(self: PortStorage, amount: number): ()
	self.FishInStorage = math.max(self.FishInStorage :: number - amount, 0)
	self:UpdateStorageStatus(false)

	self:UpdatePurchaseBoardUI()
	self:UpdateFishModel()

	self:Save()
end

function PortStorage.UpdateFishModel(self: PortStorage): ()
	local part = self.FishModel
	if not part or not part.Parent then return end

	local maxHeight = 9
	local minHeight = 0.5
	local max: number = self.CurrentMaxStorage or 0
	local current: number = self.FishInStorage or 0

	local ratio = (max > 0) and math.clamp(current / max, 0, 1) or 0

	ResizeFromEdge.ResizeByRatio(part, ratio, maxHeight, { from = "bottom", cleaner = self._cleaner, minHeight = minHeight })
end

function PortStorage.ShowFishPopUp(self: PortStorage, amount: number): ()
	local billboard: BillboardGui = game.Workspace:FindFirstChild("BillBoards"):FindFirstChild("FishPopupTemplate")
	if not billboard then return end

	local primaryPart: BasePart = self.VisualRoot
	if not primaryPart then return end

	local clone: BillboardGui = billboard:Clone()
	local container: Instance = primaryPart:FindFirstChild("Billboard")
	if container then
		clone.Parent = container
	else
		clone.Parent = primaryPart
	end

	clone.Adornee = primaryPart
	clone.Name = "Popup_Clone"
	PopUp.Animate(clone, amount, clone.Fish)
end
-- //!SECTION

-- //SECTION - Calculations
function PortStorage.CalculateBaseCost(self: PortStorage): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function PortStorage.CalculateUpgradeCost(self: PortStorage): number
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level, self.Tier, self.RealmId)

	self.UpgradeCost = cost

	return cost
end

function PortStorage.CalculateBaseStorage(self: PortStorage): number
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function PortStorage.CalculateMaxStorage(self: PortStorage): (number, number)
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end
	local storagePercentBuff = self.Buffs[PORTSTORAGE_BUFFS.PortStorage_Percent] and self.Buffs[PORTSTORAGE_BUFFS.PortStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end
-- //!SECTION

-- //SECTION - UI Setup
function PortStorage.Initialize(self: PortStorage): ()
	-- Handle visibility based on purchase status
	if not self.IsPurchased then
		self:Hide()
		self:CannotCollide()
	else
		self:Show()
		self:CanCollide()
	end

	self:UpdateVisualModel()

	-- Setup UI components
	if self.PurchaseBoard then self:SetupProximityPrompt(self.PurchaseBoard) end
	if self.IsPurchased then self.TakeFishPrompt = self:SetupFishRemovalPrompt() end
	self:UpdateFishModel()
end

function PortStorage.SetupPurchaseBoard(self: PortStorage): (Model, { [string]: any })
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	return PurchaseBoard.CreatePB(purchaseBoard, self :: any)
end

function PortStorage.UpdatePurchaseBoardUI(self: PortStorage, reset: boolean?)
	if reset then
		PurchaseBoard.ResetPB(self.PurchaseBoard)
	else
		PurchaseBoard.UpdatePB(self :: any)
	end
end

function PortStorage.SetupProximityPrompt(self: PortStorage, purchaseBoard: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = purchaseBoard

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end

function PortStorage.SetupFishRemovalPrompt(self: PortStorage)
	-- Create the proximity prompt
	local parent = self.Model:FindFirstChild("Panel", true)
	local proximityPrompt
	if parent then
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.Parent = parent
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = ""
	proximityPrompt.ActionText = "Take Fish"
	proximityPrompt.UIOffset = Vector2.new(-100, 0)

	-- Handle not showing the prompt if the user is not the owner
	if self._cleaner then
		self._cleaner:Add(proximityPrompt.PromptShown:Connect(function(player: Player)
			if player.UserId ~= self.Owner then return end
		end))

		-- Handle proximity prompt triggered
		self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player)
			-- Another safety check
			if player.UserId ~= self.Owner then return end

			-- Remove the Fish
			local amount = math.min(self.FishInStorage, self.CurrentMaxStorage)
			if amount == 0 then return end

			self:RemoveFish(amount)

			-- Spend the currency
			DataService.Earn(player, FFGEnum.CURRENCY_TYPES.Gold, amount * 2)

			-- Save State
			self:Save()
		end))
	end
end

function PortStorage.ShowStorageFullBillboard(self: PortStorage): ()
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

function PortStorage.DestroyStorageFullBillboard(self: PortStorage): ()
	if not self.ClonedBillboard then return end

	self.ClonedBillboard:Destroy()
	self.ClonedBillboard = nil
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function PortStorage.Show(self: PortStorage)
	local fishStorage = self.Model:FindFirstChild("FishInStorage", true)
	local storage = self.Model:FindFirstChild("Storage", true)

	if fishStorage then ClassVisualizer.Show(fishStorage) end
	if storage then ClassVisualizer.Show(storage) end
end

function PortStorage.Hide(self: PortStorage)
	local fishStorage = self.Model:FindFirstChild("FishInStorage", true)
	local storage = self.Model:FindFirstChild("Storage", true)

	if fishStorage then ClassVisualizer.Hide(fishStorage) end
	if storage then ClassVisualizer.Hide(storage) end
end

function PortStorage.CanCollide(self: PortStorage)
	local fishStorage = self.Model:FindFirstChild("FishInStorage", true)
	local storage = self.Model:FindFirstChild("Storage", true)

	if fishStorage then ClassVisualizer.CanCollide(fishStorage) end
	if storage then ClassVisualizer.CanCollide(storage) end
end

function PortStorage.CannotCollide(self: PortStorage)
	local fishStorage = self.Model:FindFirstChild("FishInStorage", true)
	local storage = self.Model:FindFirstChild("Storage", true)

	if fishStorage then ClassVisualizer.CannotCollide(fishStorage) end
	if storage then ClassVisualizer.CannotCollide(storage) end
end
-- //!SECTION

-- //SECTION -  Boat Utilities
function PortStorage.CanUpgrade(self: PortStorage)
	return self.Level < self.MaxLevel
end

function PortStorage.IsStorageFull(self: PortStorage)
	local status = self.FishInStorage >= self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end

function PortStorage.UpdateStorageStatus(self: PortStorage, status)
	self.StorageFull = status

	if status then
		self:ShowStorageFullBillboard()
	else
		self:DestroyStorageFullBillboard()
	end
end
-- //!SECTION

-- //SECTION - Event Listeners
function PortStorage.AttachEventListeners(self: PortStorage)
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Loading and Saving
function PortStorage.Serialize(self: PortStorage): { [string]: any }
	return {
		Entity = self.Entity,
		Description = self.Description,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
		Name = self.Name,
		Tier = self.Tier,
		UpgradeStage = self.UpgradeStage,
		Level = self.Level,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		IsPurchased = self.IsPurchased,
		BaseStorage = self.BaseStorage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
	}
end

function PortStorage.Save(self: PortStorage)
	DataService.SaveStorageState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function PortStorage.GetVisualModels(self: PortStorage): { [number]: Model }
	local modelsFolder = DeepWait(game.Workspace, "Storage", "VisualStages")
	local models = modelsFolder:GetChildren()

	local sortedModels = {}
	for k, v in pairs(models) do
		sortedModels[tonumber(v.Name)] = v
	end

	return sortedModels
end

function PortStorage.RemovePreviousVisualModel(self: PortStorage)
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function PortStorage.UpdateVisualModel(self: PortStorage)
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

	self.CurrentVisualModel = updatedModel
end
-- //!SECTION

-- //SECTION - Cleanup
function PortStorage.Destroy(self: PortStorage)
	self:Hide()
	self:CannotCollide()
	self:RemovePreviousVisualModel()
	self:UpdatePurchaseBoardUI(true)
	self:DestroyStorageFullBillboard()

	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return PortStorage
