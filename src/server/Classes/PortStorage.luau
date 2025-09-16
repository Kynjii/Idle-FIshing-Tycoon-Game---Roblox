local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local PortStorageType = require(ServerScriptService.Server.Classes.Types.PortStorageType)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local ResizeFromEdge = require(ServerScriptService.Server.Modules.Tweens.ResizeFromEdge)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Types
type Storage = PortStorageType.Storage
type StorageProps = PortStorageType.StorageProps
type StorageInstance = PortStorageType.StorageInstance
-- //!SECTION

-- //SECTION - Data
local DEFAULTS: StorageProps = {
	RealmId = 1,
	Tier = 1,
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.STORAGE.BaseCost,
	isPurchased = false,
	BaseStorage = Formulas.STORAGE.BaseStorage,
	FishInStorage = 0,
	StorageFull = false,
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
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	-- Tweens
	self.ProgressTween = nil
	self.FishModel = DeepWait(self.Model, "FishInStorage", "Base") :: UnionOperation

	self._cleaner = CleanerService.new()

	return self
end
-- //!SECTION

-- //SECTION - Core Actions
function PortStorage:Purchase()
	self.isPurchased = true

	self:Save()
end

function PortStorage:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	self.UpgradeCost = self:CalculateUpgradeCost()

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
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

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level)
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
	local purchaseBoard = self:SetupPurchaseBoard()
	if purchaseBoard then self:SetupProximityPrompt(purchaseBoard) end

	-- Setup Sell Prompt (temp)
	-- //TODO - Replace so the player can remove the fish into their own backpack
	self:SetupFishRemovalPrompt()
	self:UpdateFishModel()
end

function PortStorage:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame

	if pbDetails then
		local level = self.Level

		pbDetails.LevelLabel.Text = self.isPurchased and "Level: " .. level or "Purchase Boat"

		-- STORAGE Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and "Storage: " .. FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and "Next Lvl Storage: " .. FormatNumber(nextStorage) or ""

		-- Storage Progress Bar
		local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
		pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
	end

	return purchaseBoard
end

function PortStorage:UpdatePurchaseBoardUI()
	local isPurchased = self.isPurchased
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and "Storage: " .. FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and "Next Lvl Storage: " .. FormatNumber(self.NextLvlMaxStorage) or ""

	local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
	pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)

	pbDetails.LevelLabel.Text = "Level: " .. self.Level
end

function PortStorage:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if storage is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Storage" or "Purchase"
	proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
		if player.UserId ~= self.Owner then return end

		-- Check max level again
		if self.Level == self.MaxLevel then return end

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", not self.isPurchased and self.BaseCost or self.UpgradeCost)
			self:UpdateProximityPromptUI(proximityPrompt)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost)

		if self.isPurchased then
			-- Upgrade existing
			self:Upgrade()
		else
			-- Purchase
			self:Purchase()
			self:Show()
			self:CanCollide()
		end

		-- Update UIs
		self:UpdateProximityPromptUI(proximityPrompt)
		self:UpdatePurchaseBoardUI()

		self:Save()
	end)

	return proximityPrompt
end

function PortStorage:SetupFishRemovalPrompt()
	-- Create the proximity prompt
	local parent = self.Model
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

function PortStorage:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
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
function PortStorage:Show()
	ClassVisualizer.Show(self.Model.FishInStorage:GetChildren()[1])
	ClassVisualizer.Show(self.Model.Storage)
end

function PortStorage:Hide()
	ClassVisualizer.Hide(self.Model.FishInStorage:GetChildren()[1])
	ClassVisualizer.Hide(self.Model.Storage)
end

function PortStorage:CanCollide()
	ClassVisualizer.CanCollide(self.Model.FishInStorage:GetChildren()[1])
	ClassVisualizer.CanCollide(self.Model.Storage)
end

function PortStorage:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.FishInStorage:GetChildren()[1])
	ClassVisualizer.CannotCollide(self.Model.Storage)
end
-- //!SECTION

-- //SECTION -  Boat Utilities
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
end
-- //!SECTION

-- //SECTION - Loading and Saving
function PortStorage:Serialize()
	return {
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
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

-- //SECTION - Cleanup
function PortStorage:Destroy()
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
