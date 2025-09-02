local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)

local Boat = require(ServerScriptService.Server.Classes.Boat)
type Base = Boat.BoatInstance

export type FishingBoatProps = {
	BaseFPS: number,
	CurrentFPS: number?,
	NextFPS: number?,
}

export type FishingBoat = Base & FishingBoatProps & {
	-- Props
	Model: Model,

	-- Calculations
	CalculateBaseFPS: (self: FishingBoat) -> number,
	CalculateFPS: (self: FishingBoat) -> (number, number),

	-- Fishing
	StartFishing: (self: FishingBoat) -> (),
	StopFishing: (self: FishingBoat) -> (),

	-- Visibility and collision
	Hide: (self: FishingBoat) -> (),
	CannotCollide: (self: FishingBoat) -> (),
	Show: (self: FishingBoat) -> (),
	CanCollide: (self: FishingBoat) -> (),

	-- UI Setup (new methods)
	Initialize: (self: FishingBoat) -> (),
	SetupPurchaseBoard: (self: FishingBoat) -> Part,
	UpdatePurchaseBoardUI: (self: FishingBoat) -> (),
	SetupProximityPrompt: (self: FishingBoat, purchaseBoard: Part) -> ProximityPrompt,
	UpdateProximityPromptUI: (self: FishingBoat, proximityPrompt: ProximityPrompt) -> (),

	-- Utilities
	GetName: (self: FishingBoat) -> string,

	-- Saving and Loading
	Serialize: (self: FishingBoat) -> FishingBoatProps,

	-- Intervals
	FishingInterval: thread,

	-- Cleanup
	Destroy: (self: FishingBoat) -> (),
}

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

local DEFAULTS: FishingBoatProps = {
	BaseFPS = 10,
}

local FishingBoat: FishingBoat = {}
FishingBoat.__index = FishingBoat
setmetatable(FishingBoat, { __index = Boat.Methods :: any })

-- //SECTION - Constructor
function FishingBoat.New(state, player: Player, model: Model)
	-- Create new instance of Boat
	local boat = Boat.New(state)

	-- Assign metatable for inheritence
	local self = setmetatable(boat, FishingBoat)

	-- Add derived properties
	self.Model = model

	return self
end
-- //!SECTION

function FishingBoat:CalculateBaseFPS(): number
	local baseFPS = self.BaseFPS or DEFAULTS.BaseFPS
	local tierMultiplier = Formulas.TIER_MULTIPLIER[self.Tier]
	local realmMultiplier = math.pow(self.RealmId :: number, 2.25) -- scaling curve
	local baseFPSCalc = baseFPS * tierMultiplier * realmMultiplier

	return baseFPSCalc
end

function FishingBoat:CalculateFPS(): number
	local baseFPS = self:CalculateBaseFPS()
	local growthRate = self.GrowthRate :: number
	local level = self.Level :: number

	local fpsCalc = baseFPS * math.pow(growthRate :: number, level)
	local nextLvlFPS = baseFPS * math.pow(growthRate :: number, level + 1)

	-- //TODO - handle boosts

	return fpsCalc, nextLvlFPS
end

function FishingBoat:StartFishing()
	self.FishingInterval = SetInterval(function()
		if not self.StorageFull then
			self:AddFish(self.CurrentFPS)
			self:UpdatePurchaseBoardUI()
		end
	end, 1)
end

function FishingBoat:StopFishing()
	if self.FishingInterval then
		task.cancel(self.FishingInterval)
		self.FishingInterval = nil
	end
end

function FishingBoat:GetName(): string
	return NAME[self.UpgradeStage]
end

-- //SECTION - Loading and Saving
function FishingBoat:Serialize(): FishingBoatProps
	local baseData = Boat.Serialize(self)

	-- //TODO - Add proper props here for the fishing boat
	baseData.Bleh = self.bleh

	return baseData
end
-- //!SECTION

-- //SECTION - UI Setup Methods
function FishingBoat:SetupPurchaseBoard()
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

		pbDetails.LevelLabel.Text = self.isPurchased and "Level: " .. level or "Purchase Boat"

		-- Storage Stats
		local currentStorage, nextStorage = self:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = self.isPurchased and FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = self.isPurchased and FormatNumber(nextStorage) or ""

		-- FPS Stats
		local currentFPS, nextFPS = self:CalculateFPS()
		pbDetails.CurrentFPSLabel.Text = self.isPurchased and FormatNumber(currentFPS) or ""
		pbDetails.NextFPSLabel.Text = self.isPurchased and FormatNumber(nextFPS) or ""

		-- Storage Progress Bar
		local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
		pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
	end

	return purchaseBoard
end

function FishingBoat:UpdatePurchaseBoardUI()
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

	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and FormatNumber(self.CurrentMaxStorage) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and FormatNumber(self.NextLvlMaxStorage) or ""
	pbDetails.CurrentFPSLabel.Text = isPurchased and FormatNumber(self.CurrentFPS) or ""
	pbDetails.NextFPSLabel.Text = isPurchased and FormatNumber(self.NextFPS) or ""

	local storageProgress = CalculateProgress(self.FishInStorage, self.CurrentMaxStorage)
	FFGHelpers.PrintLog("Progress", storageProgress)
	pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)

	FFGHelpers.PrintLog(pbDetails.StorageProgress.Size)

	local level = self.Level
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = self.UpgradeStage

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = self:GetName()

	if self.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

function FishingBoat:SetupProximityPrompt(purchaseBoard: Part)
	-- Create the proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)

	-- Check if boat is at max level
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0
	proximityPrompt.ObjectText = self.isPurchased and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = self.isPurchased and "Level: " .. tostring(self.Level + 1) or "Tier " .. self.Tier .. " Boat"

	-- Handle proximity prompt triggered
	proximityPrompt.Triggered:Connect(function(player)
		-- Check max level again
		if self.Level == self.MaxLevel then return end

		local upgradeCost = self.isPurchased and self.UpgradeCost or self.BaseCost

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		end

		-- Spend the currency
		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)

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

		DataService.SaveFishingBoatProps(player, self.Id, self:Serialize())
	end)

	return proximityPrompt
end

function FishingBoat:UpdateProximityPromptUI(proximityPrompt: ProximityPrompt)
	if self.Level == self.MaxLevel then
		proximityPrompt.ObjectText = "Max Level Reached"
		proximityPrompt.ActionText = ""
	else
		proximityPrompt.ObjectText = self.isPurchased and "Upgrade Boat" or "Purchase"
		proximityPrompt.ActionText = self.isPurchased and "Level: " .. tostring(self.Level + 1) or "Tier " .. self.Tier .. " Boat"
	end
end
-- //!SECTION

function FishingBoat:Destroy()
	-- //TODO - Test that this correctly stops the spawned task
	if self.FishingInterval then self.FishingInterval = nil end
end

return FishingBoat
