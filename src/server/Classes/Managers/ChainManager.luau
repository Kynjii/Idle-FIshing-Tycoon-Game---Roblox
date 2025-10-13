local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local ChainManagerType = require(ReplicatedStorage.Shared.Types.Managers.ChainManagerType)
local Boat = require(ServerScriptService.Server.Classes.Boat)
local PortStorage = require(ServerScriptService.Server.Classes.PortStorage)
local Tender = require(ServerScriptService.Server.Classes.Tender)

-- //SECTION -  ChainManager Types
type ChainManagerInstance = ChainManagerType.ChainManagerInstance
-- //!SECTION

-- //SECTION - Tagged Entities within Studio
local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")
local taggedStorage = CollectionService:GetTagged("Storage")
-- //!SECTION

local ChainManager = {}
ChainManager.__index = ChainManager

type ChainManager = typeof(setmetatable({} :: ChainManagerInstance, ChainManager))

function ChainManager.New(realmData, tier: number, player: Player, teamId: number, buildingClasses: { [number]: { [string]: any } })
	local self = setmetatable({} :: ChainManagerInstance, ChainManager)

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
	self.LaneTender = Tender.New(tenderData, player, self.TenderModel)

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

	if self.LaneTender.isPurchased and self.LaneBoat.isPurchased then self:StartTenderCycle() end

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
			if self.LaneTender.FishInStorage > 0 and not self.LaneStorage:IsStorageFull() then
				self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.atPort, true)
			else
				self:StartTenderCycle()
			end
			return
		end

		-- atBoat
		if attributeName == FFGEnum.ATTRIBUTES.atBoat and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
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
		self.Signals.PurchasedEvent = building.Purchased:Connect(function(purchasedBuilding)
			self:HandleBuildingEvent(purchasedBuilding)
		end)
		self.Signals.UpgradedEvent = building.Upgraded:Connect(function(upgradedBuilding)
			self:HandleBuildingEvent(upgradedBuilding)
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
		local boatAmount = math.max(0, boat.FishInStorage)
		local availableStorage = math.max(0, currentMaxStorage - fishInStorage)

		local maxTransfer = math.min(boatAmount, availableStorage)
		local amount = math.clamp(delta, 0, math.max(0, maxTransfer))

		if amount > 0 then
			boat:RemoveFish(amount)
			tender:AddFish(amount)
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

	if (tender.FishInStorage or 0) <= 0 then
		self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
		return
	end

	local rawUnload = tender.LoadTime or 10
	local unloadDuration = math.clamp(rawUnload, 0.5, math.huge)
	local initialCargo = tender.FishInStorage or 0

	local activeUnloadTime = 0
	local lastUpdateTime = os.clock()

	while true do
		local currentTime = os.clock()

		if not storage.isPurchased then
			tender:ShowTenderStoppedBillboard()
			lastUpdateTime = currentTime
			task.wait(1)
			continue
		end

		local deltaTime = currentTime - lastUpdateTime
		activeUnloadTime = activeUnloadTime + deltaTime
		lastUpdateTime = currentTime

		local p = math.clamp(activeUnloadTime / unloadDuration, 0, 1)

		local currentMaxStorage = storage.CurrentMaxStorage
		local storageFree = math.max(0, currentMaxStorage - storage.FishInStorage)

		local currentTenderFish = math.max(0, tender.FishInStorage or 0)
		local targetTenderFish = (p >= 1) and 0 or math.ceil(initialCargo * (1 - p))
		if targetTenderFish < 0 then targetTenderFish = 0 end

		local deltaToRemove = math.max(0, currentTenderFish - targetTenderFish)

		local maxAmount = math.min(storageFree, currentTenderFish)
		local amount = math.clamp(deltaToRemove, 0, math.max(0, maxAmount))

		if amount > 0 then
			tender:DestroyTenderStoppedBillboard()
			tender:RemoveFish(amount)
			storage:AddFish(amount)
		elseif amount <= 0 and storage:IsStorageFull() then
			tender:ShowTenderStoppedBillboard()
			lastUpdateTime = currentTime
		end

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
