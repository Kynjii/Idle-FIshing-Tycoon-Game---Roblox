local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local PopUp = require(ServerScriptService.Server.Modules.Tweens.PopUp)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Boat Types
type Boat = BoatType.Boat
type BoatProps = BoatType.BoatProps
type BoatInstance = BoatType.BoatInstance
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
}

local ANIMATIONS = {
	WaterBob = "WaterBob",
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
	self.VisualRoot = DeepWait(model, "Boat", "VisualRoot")
	self.Name = self:GetName()
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.Player = player

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.BaseStorage = self:CalculateBaseStorage()
	self.BaseFPS = self:CalculateBaseFPS()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()
	self.CurrentFPS, self.NextFPS = self:CalculateFPS()

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	self._cleaner = CleanerService.new()

	self.FishingInterval = nil
	if self.isPurchased and not self:IsStorageFull() then task.delay(1, function()
		self:StartFishing()
	end) end

	self:UpdateVisualModel()
	self:StartAnimation()

	return self
end
-- //!SECTION

-- //SECTION - Core Boat Actions
function Boat:Purchase()
	self.isPurchased = true
	self.Model.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isPurchased, true)

	self:UpdateVisualModel()
	self:Save()
end

function Boat:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			self:UpdateVisualModel()
			self.CurrentFPS, self.NextFPS = self:CalculateFPS()
			break
		end
	end

	self.UpgradeCost = self:CalculateUpgradeCost()
	self.CurrentMaxStorage, self.NextLvlMaxStorage = self:CalculateMaxStorage()

	self:Save()
end

function Boat:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Boat:CalculateBaseCost()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Boat:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end

function Boat:CalculateBaseStorage()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseStorage, self.Tier, self.RealmId)
	self.BaseStorage = base

	return base
end

function Boat:CalculateMaxStorage()
	local baseStorage = self.BaseStorage or DEFAULTS.BaseStorage
	if baseStorage == DEFAULTS.BaseStorage then baseStorage = self:CalculateBaseStorage() end

	return ClassCalculators.CalculateMaxStorage(baseStorage, self.Level)
end

function Boat:CalculateBaseFPS()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseFPS, self.Tier, self.RealmId)
	self.BaseFPS = base

	return base
end

function Boat:CalculateFPS()
	local baseFPS = self.BaseFPS or DEFAULTS.BaseFPS
	if baseFPS == DEFAULTS.BaseFPS then baseFPS = self:CalculateBaseFPS() end

	return ClassCalculators.CalculateFPS(baseFPS, self.UpgradeStage)
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
	if self.FishingInterval then self._cleaner:add(self.FishingInterval) end
end

function Boat:AddFish(amount)
	self.FishInStorage += amount

	self:ShowFishPopUp(amount)
	if self.FishInStorage >= self.CurrentMaxStorage then
		self.FishInStorage = self.CurrentMaxStorage
		self:UpdateStorageStatus(true)
	end

	self:Save()
end

function Boat:RemoveFish(amount)
	self.FishInStorage -= amount
	self:UpdateStorageStatus(false)
	self:Save()
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
		local qualityInfo = FFGEnum.QUALITY[self.UpgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not self.isPurchased then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = self:GetName()
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = self.isPurchased and "Level: " .. self.Level or "Purchase Boat"

		-- STORAGE Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and "Storage: " .. FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and "Next Lvl Storage: " .. FormatNumber(nextStorage) or ""

		-- FPS Stats
		pbDetails.CurrentFPSLabel.Text = self.isPurchased and "FPS: " .. FormatNumber(self.CurrentFPS) or ""
		if self:ShowUpgradeStageUpgrade() then pbDetails.NextFPSLabel.Text = self.isPurchased and "Next Lvl FPS: " .. FormatNumber(self.NextFPS) or "" end

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

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and "Storage: " .. FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and "Next Lvl Storage: " .. FormatNumber(self.NextLvlMaxStorage) or ""
	pbDetails.CurrentFPSLabel.Text = isPurchased and "FPS: " .. FormatNumber(self.CurrentFPS) or ""

	local showUpgradeStageUpgrade = self:ShowUpgradeStageUpgrade()
	if showUpgradeStageUpgrade then
		pbDetails.NextFPSLabel.Text = isPurchased and "Next Lvl FPS: " .. FormatNumber(self.NextFPS) or ""
		pbDetails.NextFPSLabel.Visible = true
	else
		pbDetails.NextFPSLabel.Visible = false
	end

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
	local proximityPrompt: ProximityPrompt = self._cleaner:add(Instance.new("ProximityPrompt", purchaseBoard))

	-- Check if boat is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)

	-- Handle proximity prompt triggered
	self._cleaner:add(proximityPrompt.Triggered:Connect(function(player)
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
	end))

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

function Boat:ShowFishPopUp(amount)
	local billboard: BillboardGui = self.Model.PrimaryPart.Billboard:WaitForChild("FishPopupTemplate")
	if billboard then
		local clone = billboard:Clone()
		clone.Parent = self.Model.PrimaryPart.Billboard
		clone.Adornee = self.Model.PrimaryPart
		clone.Name = "Popup_Clone"
		PopUp.Animate(clone, amount, clone.Fish)
	end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Boat:Show()
	ClassVisualizer.Show(self.Model.Boat.VisualRoot:GetChildren()[1])
end

function Boat:Hide()
	ClassVisualizer.Hide(self.Model.Boat.VisualRoot:GetChildren()[1])
end

function Boat:CanCollide()
	ClassVisualizer.CanCollide(self.Model.Boat.VisualRoot:GetChildren()[1])
end

function Boat:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.Boat.VisualRoot:GetChildren()[1])
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

function Boat:ShowUpgradeStageUpgrade()
	local nextStart = Formulas.PROMO_LEVEL[self.UpgradeStage + 1]
	if not nextStart then return false end
	return self.Level == (nextStart - 1)
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

function Boat:Save()
	DataService.SaveBoatState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Boat:GetVisualModels()
	local modelsFolder = DeepWait(game.Workspace, "Boats", "VisualStages")
	local models = modelsFolder:GetChildren()

	local templateModels: { [number]: Model } = {}
	for i, model in ipairs(models) do
		templateModels[tonumber(model.Name)] = model
	end

	return templateModels
end

function Boat:RemovePreviousVisualModel()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Boat:UpdateVisualModel()
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
function Boat:StartAnimation()
	local animator: Animator = DeepWait(self.Model, "Boat", "AnimationController", "Animator")
	local animation: Animation = Animator.GetAnimation(ANIMATIONS.WaterBob)

	local animationTrack: AnimationTrack = self._cleaner:add(animator:LoadAnimation(animation))
	animationTrack.Looped = true

	task.wait(math.random(0.5, 1.5))
	animationTrack:Play()
end
-- //!SECTION

-- //SECTION - Cleanup
function Boat:ClearAllAttributes(instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Boat:Destroy()
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	self:ClearAllAttributes(self.Model.PrimaryPart)

	if self._cleaner then
		self._cleaner:clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Model = nil
end
-- //!SECTION

return Boat
