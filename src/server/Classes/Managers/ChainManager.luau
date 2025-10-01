local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Boat: Boat = require(ServerScriptService.Server.Classes.Boat)
local PortStorage: PortStorageType = require(ServerScriptService.Server.Classes.PortStorage)
local Tender: Tender = require(ServerScriptService.Server.Classes.Tender)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local ChainManagerType = require(ReplicatedStorage.Shared.Types.Managers.ChainManagerType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)

local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")
local taggedStorage = CollectionService:GetTagged("Storage")

type Boat = BoatType.Boat
type Tender = TenderType.Tender
type PortStorageType = PortStorageType.Storage
type ChainManager = ChainManagerType.ChainManagerInstance

local ChainManager = {} :: ChainManager
ChainManager.__index = ChainManager

function ChainManager.New(realmData, tier: number, player: Player, teamId: number, buildingClasses: { [number]: { [string]: any } })
	local self: ChainManager = setmetatable({}, ChainManager)

	local boatsArr = realmData.Boats
	local tendersArr = realmData.Tenders
	local storageArr = realmData.Storages

	self.Player = player
	self.Tier = tier
	self.TeamId = teamId
	self.Buildings = buildingClasses

	-- Create Boat
	self.BoatModel = self:FindBoatModel() :: Model
	if not self.BoatModel then return end
	local boatData = nil
	for k, v in pairs(boatsArr) do
		if v[FFGEnum.CLASS.PROPERTIES.Tier] == tier then boatData = v end
	end
	self.LaneBoat = Boat.New(boatData, player, self.BoatModel)

	-- Create Tender
	self.TenderModel = self:FindTenderModel() :: Model
	if not self.TenderModel then return end
	local tenderData = nil
	for k, v in pairs(tendersArr) do
		if v[FFGEnum.CLASS.PROPERTIES.Tier] == tier then tenderData = v end
	end
	self.LaneTender = Tender.New(tenderData, player, self.TenderModel, self.BoatModel)

	-- Create Port Storage
	self.StorageModel = self:FindStorageModel() :: Model
	if not self.StorageModel then return end
	local storageData = nil
	for k, v in pairs(storageArr) do
		if v[FFGEnum.CLASS.PROPERTIES.Tier] == tier then storageData = v end
	end
	self.LaneStorage = PortStorage.New(storageData, player, self.StorageModel)

	-- Attach listeners
	self.Signals = {
		PurchasedEvent = nil,
		UpgradedEvent = nil,
	}

	if self.LaneTender.isPurchased then self:StartTenderCycle() end

	return self
end

function ChainManager:FindBoatModel()
	for _, taggedBoat in ipairs(taggedBoats) do
		local taggedBoatTier = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedBoatTeamId = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedBoatTeamId == self.TeamId and taggedBoatTier == self.Tier then return taggedBoat end
	end

	return nil
end

function ChainManager:FindTenderModel()
	for _, taggedTender in ipairs(taggedTenders) do
		local taggedTenderTier = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedTenderTeamId = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedTenderTeamId == self.TeamId and taggedTenderTier == self.Tier then return taggedTender end
	end

	return nil
end

function ChainManager:FindStorageModel()
	for _, taggedStorageUnit in ipairs(taggedStorage) do
		local taggedStorageUnitTier = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedStorageUnitTeamId = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedStorageUnitTeamId == self.TeamId and taggedStorageUnitTier == self.Tier then return taggedStorageUnit end
	end

	return nil
end

function ChainManager:Initialize()
	self.LaneBoat:Initialize()
	self.LaneTender:Initialize()
	self.LaneStorage:Initialize()

	self:AttachAttListeners()
end

function ChainManager:AttachAttListeners()
	self.TenderModel.PrimaryPart.AttributeChanged:Connect(function(attributeName)
		-- isPurchased triggers the start of the cycle
		if attributeName == FFGEnum.ATTRIBUTES.isPurchased and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true and self.LaneBoat.isPurchased then
			self:StartTenderCycle()
			return
		end

		-- atBoat
		if attributeName == FFGEnum.ATTRIBUTES.atBoat and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
			self.LaneTender:ShowProgressBar()
			self:StartLoadingFish()
			return
		end

		-- finishedLoading
		if attributeName == FFGEnum.ATTRIBUTES.finishedLoading and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
			self.LaneTender:MoveToPort()
			return
		end

		-- atPort
		if attributeName == FFGEnum.ATTRIBUTES.atPort and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
			self:StartUnloadingFish()
			return
		end

		-- finishedUnloading
		if attributeName == FFGEnum.ATTRIBUTES.finishedUnloading and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
			self:StartTenderCycle()
			return
		end
	end)

	self.BoatModel.PrimaryPart.AttributeChanged:Connect(function(attributeName)
		-- isPurchased triggers the start of the cycle
		if attributeName == FFGEnum.ATTRIBUTES.isPurchased and self.BoatModel.PrimaryPart:GetAttribute(attributeName) == true and self.LaneTender.isPurchased then
			self:StartTenderCycle()
			return
		end
	end)

	for _, building in pairs(self.Buildings) do
		self.Signals.PurchasedEvent = building.Purchased:Connect(function(building)
			self:HandleBuildingEvent(building)
		end)
		self.Signals.UpgradedEvent = building.Upgraded:Connect(function(building)
			self:HandleBuildingEvent(building)
		end)
	end
end

-- //SECTION - Handle Building Events
function ChainManager:HandleBuildingEvent(building)
	if building.Owner ~= self.Player.UserId then return end

	local actions = {
		[FFGEnum.BUFFS.SCOPE.Boat] = function()
			self.LaneBoat:RecalculateAll()
		end,
		[FFGEnum.BUFFS.SCOPE.Tender] = function()
			self.LaneTender:RecalculateAll()
		end,
		[FFGEnum.BUFFS.SCOPE.PortStorage] = function()
			self.LaneStorage:RecalculateAll()
		end,
	}
	local scope = building.BuildingBuff.Scope or {}
	local action = actions[scope]
	if action then action() end
end
-- //!SECTION

-- //SECTION - Tender Travelling Cycle Functions used by the AttListeners
function ChainManager:ResetTravellingAttributes()
	local primary = self.TenderModel.PrimaryPart
	for name, _ in pairs(primary:GetAttributes()) do
		if name ~= FFGEnum.ATTRIBUTES.isPurchased then primary:SetAttribute(name, false) end
	end
end

function ChainManager:StartTenderCycle()
	self:ResetTravellingAttributes()

	local boatPos = self.BoatModel.PrimaryPart.CFrame * CFrame.new(0, -15, 0)
	self.LaneTender:MoveToBoat(boatPos)
end

function ChainManager:StartLoadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, false)

	local boat = self.LaneBoat
	local tender = self.LaneTender

	-- Snapshot the load duration at start (prevents mid-load buff exploits).
	local rawLoad = tender.LoadTime or 10
	local loadDuration = math.clamp(rawLoad, 0.5, math.huge)
	local startTime = os.clock()

	while true do
		-- Time-based progress 0..1
		local elapsed = os.clock() - startTime
		local p = math.clamp(elapsed / loadDuration, 0, 1)

		-- Dynamic capacity support (upgrades mid-load)
		local currentMaxStorage = tender.CurrentMaxStorage
		local fishInStorage = tender.FishInStorage

		-- If time is up, aim to be full once; otherwise aim for fraction of capacity
		local targetStorage = (p >= 1) and currentMaxStorage or math.floor(currentMaxStorage * p)

		-- Compute allowed transfer this tick
		local delta = targetStorage - fishInStorage
		local boatAmount = boat.FishInStorage
		local availableStorage = currentMaxStorage - fishInStorage
		local amount = math.clamp(delta, 0, math.min(boatAmount, availableStorage))

		if amount > 0 then
			boat:RemoveFish(amount)
			tender:AddFish(amount)
			if tender.Buffs then tender:UpdatePurchaseBoardUI() end
		end

		-- Finish either because time is up or storage is full
		if p >= 1 or tender:IsStorageFull() then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, true)
			break
		end

		task.wait(1)
	end
end

function ChainManager:StartUnloadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, false)

	local tender = self.LaneTender
	local storage = self.LaneStorage

	-- If there’s nothing to unload, finish immediately.
	if (tender.FishInStorage or 0) <= 0 then
		self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
		return
	end

	-- Snapshot unload duration at start, capacity stays dynamic.
	local rawUnload = tender.LoadTime or 10
	local unloadDuration = math.clamp(rawUnload, 0.5, math.huge)
	local startTime = os.clock()

	-- Snapshot how much the tender started with
	local initialCargo = tender.FishInStorage or 0

	while true do
		if not storage.isPurchased then
			task.wait(1)
			continue
		end

		-- 0..1 progress based on time
		local elapsed = os.clock() - startTime
		local p = math.clamp(elapsed / unloadDuration, 0, 1)

		-- Dynamic storage capacity/support mid-unload
		local currentMaxStorage = storage.CurrentMaxStorage
		local storageFree = currentMaxStorage - storage.FishInStorage

		-- Desired tender cargo at progress p (aim to be empty by p=1)
		local currentTenderFish = tender.FishInStorage
		local targetTenderFish = (p >= 1) and 0 or math.ceil(initialCargo * (1 - p))
		if targetTenderFish < 0 then targetTenderFish = 0 end

		-- Remove just enough to reach the target, bounded by storage space
		local deltaToRemove = currentTenderFish - targetTenderFish
		if deltaToRemove < 0 then deltaToRemove = 0 end

		local amount = math.clamp(deltaToRemove, 0, math.min(storageFree, currentTenderFish))
		if amount > 0 then
			tender:DestroyTenderStoppedBillboard()
			tender:RemoveFish(amount)
			storage:AddFish(amount)
			if tender.Buffs then tender:UpdatePurchaseBoardUI() end
		else
			tender:ShowTenderStoppedBillboard()
		end

		-- Finish ONLY when the tender is empty.
		if tender.FishInStorage <= 0 then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
			break
		end

		task.wait(1)
	end
end

-- //!SECTION

-- //SECTION - Cleanup
function ChainManager:Destroy()
	self.LaneBoat:Destroy()
	self.LaneTender:Destroy()
	self.LaneStorage:Destroy()

	for k, v in pairs(self.Signals) do
		if v.Connected then v:Destroy() end
	end
end
-- //!SECTION

return ChainManager
