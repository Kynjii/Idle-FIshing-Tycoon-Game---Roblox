local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local FadeEffect = require(ServerScriptService.Server.Modules.Tweens.FadeEffect)
local CleanerService = require(ServerScriptService.Server.Services.CleanerService)

-- //SECTION - Building Types
-- //!SECTION

-- //SECTION - Building Data
local NAME = {
	Market = {
		[1] = "Fishmonger’s Stall",
		[2] = "Fish Cart",
		[3] = "Fishmonger’s Hut",
		[4] = "Wharf Stand",
		[5] = "Harbor Market",
		[6] = "Fisher’s Pavilion",
		[7] = "Dockside Bazaar",
		[8] = "Seafarer’s Market Hall",
		[9] = "Maritime Exchange",
		[10] = "Grand Harbor Market",
		[11] = "Oceanfront City Market",
	},
	BoatStorageUpgrader = {
		[1] = "Boatwright’s Shed",
		[2] = "Carpenter’s Shack",
		[3] = "Timber Workshop",
		[4] = "Dockside Workshop",
		[5] = "Shipwright’s Lodge",
		[6] = "Pier Workshop",
		[7] = "Drydock Hall",
		[8] = "Harbor Shipyard",
		[9] = "Great Shipwright’s Yard",
		[10] = "Maritime Dockworks",
		[11] = "Royal Shipyard",
	},
	BoatFPSUpgrader = {
		[1] = "Net Spinner’s Hut",
		[2] = "Rope Weaver’s Corner",
		[3] = "Netting Shed",
		[4] = "Spinner’s Workshop",
		[5] = "Tangle Hall",
		[6] = "Knotcrafter’s Den",
		[7] = "Weaver’s Guildhouse",
		[8] = "Fisher’s Loom Hall",
		[9] = "Maritime Net Guild",
		[10] = "Grand Loomworks",
		[11] = "Oceanic Guild of Nets",
	},
}

local DEFAULTS = {
	RealmId = 1,
	Tier = 1,
	Name = "Unnamed Building",
	Level = 1,
	MaxLevel = 100,
	BaseCost = Formulas.BUILDING.BaseCost,
	isPurchased = false,
	UpgradeStage = 1,
}
-- //!SECTION

local Building = {}
Building.__index = Building

-- //SECTION - Constructor
function Building.New(state, player: Player, model: Model)
	local self = setmetatable({}, Building)

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
	self.VisualRoot = DeepWait(model, "Building", "VisualRoot")
	self.Tier = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.Tier) or DEFAULTS.Tier
	self.BuildingId = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.BuildingId)
	self.BuildingName = self.Model:GetAttribute(FFGEnum.ATTRIBUTES.BuildingName)
	self.Name = self:GetName()
	self.Player = player

	self.BaseCost = self:CalculateBaseCost()
	self.UpgradeCost = self:CalculateUpgradeCost()
	self.Boosts = {}

	self.VisualModels = self:GetVisualModels()
	self.CurrentVisualModel = nil

	self._cleaner = CleanerService.new()

	self:UpdateVisualModel()

	return self
end
-- //!SECTION

-- //SECTION - Core Building Actions
function Building:Purchase()
	self.isPurchased = true

	self:UpdateVisualModel()
	self:Save()
end

function Building:Upgrade()
	if not self:CanUpgrade() then return end

	self.Level += 1
	for k, v in ipairs(Formulas.PROMO_LEVEL) do
		if self.Level == v then
			self:IncreaseUpgradeStage(k)
			self:UpdateVisualModel()
			break
		end
	end

	self:Save()
end

function Building:IncreaseUpgradeStage(stage)
	self.UpgradeStage = stage
	self.Name = self:GetName()
end
-- //!SECTION

-- //SECTION - Calculations
function Building:CalculateBaseCost()
	local base = ClassCalculators.CalculateBaseValue(DEFAULTS.BaseCost, self.Tier, self.RealmId)
	self.BaseCost = base

	return base
end

function Building:CalculateUpgradeCost()
	local baseCost = self.BaseCost or DEFAULTS.BaseCost
	if baseCost == DEFAULTS.BaseCost then baseCost = self:CalculateBaseCost() end

	local cost = ClassCalculators.CalculateUpgradeCost(baseCost, self.Level)

	self.UpgradeCost = cost

	return cost
end
-- //!SECTION

-- //SECTION - UI Setup
function Building:Initialize()
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

function Building:SetupPurchaseBoard()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel

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

		pbDetails.LevelLabel.Text = self.isPurchased and "Lvl: " .. self.Level or "Purchase " .. self.Name
		pbDetails.LevelLabel.TextXAlignment = "Center"
	end

	return purchaseBoard
end

function Building:UpdatePurchaseBoardUI()
	local purchaseBoard = self.Model:WaitForChild("Purchase_Board")

	local pbDetails = {}
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel

	local level = self.Level
	pbDetails.LevelLabel.Text = "Lvl: " .. level

	local qualityInfo = FFGEnum.QUALITY[self.UpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

function Building:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt: ProximityPrompt = self._cleaner:add(Instance.new("ProximityPrompt", purchaseBoard))

	-- Check if Building is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 5
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade " .. self.Name or "Purchase"
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
			-- Upgrade existing Building
			self:Upgrade()
		else
			-- Purchase Building
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

function Building:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
	else
		proximityPrompt.ObjectText = self.isPurchased and "Upgrade Building" or "Purchase"
		proximityPrompt.ActionText = self.isPurchased and "Gold: " .. FormatNumber(self.UpgradeCost) or "Gold: " .. FormatNumber(self.BaseCost)
	end
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Building:Show()
	ClassVisualizer.Show(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:Hide()
	ClassVisualizer.Hide(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:CanCollide()
	ClassVisualizer.CanCollide(self.Model.Building.VisualRoot:GetChildren()[1])
end

function Building:CannotCollide()
	ClassVisualizer.CannotCollide(self.Model.Building.VisualRoot:GetChildren()[1])
end
-- //!SECTION

-- //SECTION -  Building Utilities
function Building:GetName()
	return NAME[self.BuildingName][self.UpgradeStage]
end

function Building:CanUpgrade()
	return self.Level < self.MaxLevel
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Building:Serialize()
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
		UpgradeStage = self.UpgradeStage,
		Boosts = self.Boosts,
	}
end

function Building:Save()
	DataService.SaveBuildingState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Visual Models
function Building:GetVisualModels()
	local modelsFolder = DeepWait(game.Workspace, "Buildings", "VisualStages", self.BuildingName)
	local models = modelsFolder:GetChildren()

	local templateModels: { [number]: Model } = {}
	for i, model in ipairs(models) do
		templateModels[tonumber(model.Name)] = model
	end

	return templateModels
end

function Building:RemovePreviousVisualModel()
	local visualModel = self.CurrentVisualModel
	if not visualModel then return end

	visualModel:Destroy()
	self.CurrentVisualModel = nil
end

function Building:UpdateVisualModel()
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
function Building:ClearAllAttributes(instance: Instance)
	for name, _ in pairs(instance:GetAttributes()) do
		if not string.find(name, "^RBX_") then instance:SetAttribute(name, nil) end
	end
end

function Building:Destroy()
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

return Building
