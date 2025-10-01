local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local PurchaseBoard = require(ServerScriptService.Server.Classes.Modules.PurchaseBoard)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local Buffs = require(ServerScriptService.Server.Math.Buffs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local ResizeFromEdge = require(ServerScriptService.Server.Modules.Tweens.ResizeFromEdge)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Types
type Storage = PortStorageType.Storage
type StorageProps = PortStorageType.StorageProps
type StorageInstance = PortStorageType.StorageInstance
-- //!SECTION

-- //SECTION - Data
local NAME = {
	[1] = "Driftwood Crates",
	[2] = "Fisher’s Shack",
	[3] = "Salted Net Loft",
	[4] = "Harbor Shed",
	[5] = "Guild Granary",
	[6] = "Stone Wharfhouse",
	[7] = "Ironclad Warehouse",
	[8] = "Lord’s Storehall",
	[9] = "Grand Harbor Vault",
	[10] = "Dragonbone Strongroom",
	[11] = "The Crown’s Keep",
}

local DESCRIPTION = "Timber sheds line the dock, smelling faintly of salt and tar. \n\n- Expands how much fish you can store before selling."

local DEFAULTS: StorageProps = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.PortStorage,
	RealmId = 1,
	Tier = 1,
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.STORAGE.BaseCost,
	isPurchased = false,
	BaseStorage = Formulas.STORAGE.BaseStorage,
	UpgradeStage = 1,
	FishInStorage = 0,
	StorageFull = false,
}

local PORTSTORAGE_BUFFS = {
	PortStorage_Percent = FFGEnum.BUFFS.STORAGE.Port_Percent,
}
-- //!SECTION

local PortStorage = {} :: StorageInstance
PortStorage.__index = PortStorage

-- //SECTION - Constructor
function PortStorage.New(state, player: Player, model: Model): Storage
	local self: StorageInstance = setmetatable({}, PortStorage)

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
	self.Entity = self.Entity or DEFAULTS.Entity
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Name = self:GetName()
	self.VisualRoot = DeepWait(model, "Storage", "VisualRoot")
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

	self:AttachEventListeners()

	-- Tweens
	self.ProgressTween = nil
	self.FishModel = DeepWait(self.Model, "FishInStorage", "Base") :: UnionOperation

	self._cleaner = CleanerService.new()

	self:UpdateVisualModel()

	return self
end
-- //!SECTION

-- //SECTION - Buffs
function PortStorage:GetBuffs()
	return Buffs.GetBuffs(self.Player, PORTSTORAGE_BUFFS)
end

function PortStorage:UpdateBuffs()
	self.Buffs = self:GetBuffs()
end

function PortStorage:RecalculateAll()
	self:UpdateBuffs()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:UpdatePurchaseBoardUI()
end
-- //!SECTION

-- //SECTION - Core Actions
function PortStorage:Purchase()
	self.isPurchased = true

	self.TakeFishPrompt = self:SetupFishRemovalPrompt()
	self:UpdateBuffs()
	self:UpdateVisualModel()
	self:Save()
end

function PortStorage:Upgrade()
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
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function PortStorage:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end

function PortStorage:AddFish(amount: number)
	self.FishInStorage += amount
	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:UpdatePurchaseBoardUI()
	self:UpdateFishModel()
end

function PortStorage:RemoveFish(amount: number)
	self.FishInStorage = math.max(self.FishInStorage :: number - amount, 0)
	self:UpdateStorageStatus(false)

	self:UpdatePurchaseBoardUI()
	self:UpdateFishModel()

	self:Save()
end

function PortStorage:UpdateFishModel()
	local part: BasePart = self.FishModel
	if not part or not part.Parent then return end

	local maxHeight = 9
	local minHeight = 0.5
	local max: number = self.CurrentMaxStorage or 0
	local current: number = self.FishInStorage or 0

	local ratio = (max > 0) and math.clamp(current / max, 0, 1) or 0

	ResizeFromEdge.ResizeByRatio(part, ratio, maxHeight, { from = "bottom", cleaner = self._cleaner, minHeight = minHeight })
end
-- //!SECTION

-- //SECTION - Calculations
function PortStorage:CalculateBaseCost()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function PortStorage:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end

function PortStorage:CalculateBaseStorage()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function PortStorage:CalculateMaxStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end
	local storagePercentBuff = self.Buffs[PORTSTORAGE_BUFFS.PortStorage_Percent] and self.Buffs[PORTSTORAGE_BUFFS.PortStorage_Percent].CurrentValue or nil

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level, storagePercentBuff)
end
-- //!SECTION

-- //SECTION - UI Setup
function PortStorage:Initialize()
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
	if self.isPurchased then self.TakeFishPrompt = self:SetupFishRemovalPrompt() end
	self:UpdateFishModel()
end

function PortStorage:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	return PurchaseBoard.CreatePB(purchaseBoard, self)
end

function PortStorage:UpdatePurchaseBoardUI()
	PurchaseBoard.UpdatePB(self)
end

function PortStorage:SetupProximityPrompt(purchaseBoard: Part)
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	ProximityPrompt.CreatePP(proximityPrompt, self)
end

function PortStorage:SetupFishRemovalPrompt()
	-- Create the proximity prompt
	local parent = self.Model.Storage.Panel
	local proximityPrompt = Instance.new("ProximityPrompt", parent)

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = ""
	proximityPrompt.ActionText = "Take Fish"
	proximityPrompt.UIOffset = Vector2.new(-100, 0)

	-- Handle not showing the prompt if the user is not the owner
	proximityPrompt.PromptShown:Connect(function(player: Player)
		if player.UserId ~= self.Owner then return end
	end)

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
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
	end)
end

function PortStorage:ShowStorageFullBillboard()
	local billboard: BillboardGui = game.Workspace.BillBoards:FindFirstChild("StorageFullAlert", true)
	local existing = self.PurchaseBoard:FindFirstChild("StorageFullAlert_Clone", true)
	if billboard and not existing then
		local clone: BillboardGui = billboard:Clone()
		clone.Parent = self.PurchaseBoard.PrimaryPart
		clone.Adornee = self.PurchaseBoard.PrimaryPart
		clone.Name = "StorageFullAlert_Clone"

		local canvasGroup: CanvasGroup = clone:FindFirstChild("CanvasGroup")
		canvasGroup.Visible = true
	end
end

function PortStorage:DestroyStorageFullBillboard()
	local clonedBillboard = nil
	if self.Model then clonedBillboard = self.Model:FindFirstChild("StorageFullAlert_Clone", true) end

	if clonedBillboard then clonedBillboard:Destroy() end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function PortStorage:Show()
	ClassVisualizer.Show(self.Model.FishInStorage)
	ClassVisualizer.Show(self.Model.Storage)
end

function PortStorage:Hide()
	ClassVisualizer.Hide(self.Model.FishInStorage)
	ClassVisualizer.Hide(self.Model.Storage)
end

function PortStorage:CanCollide()
	ClassVisualizer.CanCollide(self.Model.FishInStorage)
	ClassVisualizer.CanCollide(self.Model.Storage)
end

function PortStorage:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.FishInStorage)
	ClassVisualizer.CannotCollide(self.Model.Storage)
end
-- //!SECTION

-- //SECTION -  Boat Utilities
function PortStorage:GetName()
	return NAME[self.UpgradeStage]
end

function PortStorage:CanUpgrade()
	return self.Level < self.MaxLevel
end

function PortStorage:IsStorageFull()
	local status = self.FishInStorage >= self.CurrentMaxStorage
	if self.StorageFull ~= status then self:UpdateStorageStatus(status) end
	return status
end

function PortStorage:UpdateStorageStatus(status)
	self.StorageFull = status

	if status then
		self:ShowStorageFullBillboard()
	else
		self:DestroyStorageFullBillboard()
	end
end
-- //!SECTION

-- //SECTION - Event Listeners
function PortStorage:AttachEventListeners()
	EventListeners.Attach(self)
end
-- //!SECTION

-- //SECTION - Loading and Saving
function PortStorage:Serialize()
	return {
		Entity = self.Entity,
		Description = self.Description,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
		Name = self.Name,
		Tier = self.Tier,
		Level = self.Level,
		MaxLevel = self.MaxLevel,
		BaseCost = self.BaseCost,
		UpgradeCost = self.UpgradeCost,
		isPurchased = self.isPurchased,
		BaseStorage = self.BaseStorage,
		CurrentMaxStorage = self.CurrentMaxStorage,
		NextLvlMaxStorage = self.NextLvlMaxStorage,
		FishInStorage = self.FishInStorage,
		StorageFull = self.StorageFull,
	}
end

function PortStorage:Save()
	DataService.SaveStorageState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function PortStorage:GetVisualModels()
	local modelsFolder = DeepWait(game.Workspace, "Storage", "VisualStages")
	local models = modelsFolder:GetChildren()

	local templateModels: { [number]: Model } = {}
	for i, model in ipairs(models) do
		templateModels[tonumber(model.Name)] = model
	end

	return templateModels
end

function PortStorage:RemovePreviousVisualModel()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function PortStorage:UpdateVisualModel()
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

-- //SECTION - Cleanup
function PortStorage:Destroy()
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	self._cleaner:clean()
	self._cleaner = nil

	self.Player = nil
	self.Model = nil
end
-- //!SECTION

return PortStorage
