local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local ChainManagerType = require(ReplicatedStorage.Shared.Types.Managers.ChainManagerType)
local Boat = require(ServerScriptService.Server.Classes.Boat)
local PortStorage = require(ServerScriptService.Server.Classes.PortStorage)
local Tender = require(ServerScriptService.Server.Classes.Tender)

-- //SECTION -  ChainManager Types
type ChainManagerInstance = ChainManagerType.ChainManagerInstance
-- //!SECTION

-- //SECTION - Tagged Entities within Workspace
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
	self.LaneBoat = Boat.New(boatData, player, self.BoatModel, self.TeamId)

	-- Create Tender
	self.TenderModel = self:FindTenderModel() :: Model
	if not self.TenderModel then return end
	local tenderData = nil
	for k, v in pairs(tendersArr) do
		if v[FFGEnum.CLASS.PROPERTIES.Tier] == tier then tenderData = v end
	end
	self.LaneTender = Tender.New(tenderData, player, self.TenderModel, self.TeamId)

	-- Create Port Storage
	self.StorageModel = self:FindStorageModel() :: Model
	if not self.StorageModel then return end
	local storageData = nil
	for k, v in pairs(storageArr) do
		if v[FFGEnum.CLASS.PROPERTIES.Tier] == tier then storageData = v end
	end
	self.LaneStorage = PortStorage.New(storageData, player, self.StorageModel, self.TeamId)

	self._cleaner = Trove.new()

	if self.LaneTender.IsPurchased and self.LaneBoat.IsPurchased then self:StartTenderCycle() end

	return self
end

function ChainManager.FindBoatModel(self: ChainManagerInstance): Model?
	for _, taggedBoat in ipairs(taggedBoats) do
		local taggedBoatTier = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedBoatTeamId = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedBoatTeamId == self.TeamId and taggedBoatTier == self.Tier then return taggedBoat end
	end

	return nil
end

function ChainManager.FindTenderModel(self: ChainManagerInstance): Model?
	for _, taggedTender in ipairs(taggedTenders) do
		local taggedTenderTier = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedTenderTeamId = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedTenderTeamId == self.TeamId and taggedTenderTier == self.Tier then return taggedTender end
	end

	return nil
end

function ChainManager.FindStorageModel(self: ChainManagerInstance): Model?
	for _, taggedStorageUnit in ipairs(taggedStorage) do
		local taggedStorageUnitTier = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedStorageUnitTeamId = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedStorageUnitTeamId == self.TeamId and taggedStorageUnitTier == self.Tier then return taggedStorageUnit end
	end

	return nil
end

function ChainManager.Initialize(self: ChainManagerInstance)
	self.LaneBoat:Initialize()
	self.LaneTender:Initialize()
	self.LaneStorage:Initialize()

	self:AttachAttListeners()
end

type SendStorageFishData = {
	Player: Player,
	HelperId: string,
	JobId: number,
	Amount: number,
}

type GetStorageFishData = {
	Player: Player,
	JobId: number,
	TeamId: number,
	AvailableStorage: number,
	HelperId: string,
}

function ChainManager.AttachAttListeners(self: ChainManagerInstance)
	if self.TenderModel and self.TenderModel.PrimaryPart then
		if self._cleaner then
			self._cleaner:Add(self.TenderModel.PrimaryPart.AttributeChanged:Connect(function(attributeName)
				-- IsPurchased triggers the start of the cycle
				if attributeName == FFGEnum.ATTRIBUTES.IsPurchased and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true and self.LaneBoat.IsPurchased then
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
			end))
		end
	end

	if self.BoatModel and self.BoatModel.PrimaryPart then
		if self._cleaner then
			self._cleaner:Add(self.BoatModel.PrimaryPart.AttributeChanged:Connect(function(attributeName)
				-- IsPurchased triggers the start of the cycle
				if attributeName == FFGEnum.ATTRIBUTES.IsPurchased and self.BoatModel.PrimaryPart:GetAttribute(attributeName) == true and self.LaneTender.IsPurchased then
					self:StartTenderCycle()
					return
				end
			end))
		end
	end

	for _, building in pairs(self.Buildings) do
		if self._cleaner then
			self._cleaner:Add(building.Purchased:Connect(function(purchasedBuilding)
				self:HandleBuildingEvent(purchasedBuilding)
			end))

			self._cleaner:Add(building.Upgraded:Connect(function(upgradedBuilding)
				self:HandleBuildingEvent(upgradedBuilding)
			end))
		end
	end

	if self.LaneStorage then
		local getStorageFish = Events.GetBindableEvent(Events.BindableNames.GetStorageFish)
		if getStorageFish then
			getStorageFish.Event:Connect(function(request: GetStorageFishData)
				if request.Player ~= self.Player then return end
				if self.TeamId ~= request.TeamId then return end
				if self.Tier ~= request.JobId then return end

				local helperStorage = request.AvailableStorage
				local storage = self.LaneStorage
				local availableFishInStorage = storage.FishInStorage

				local amount = math.min(helperStorage, availableFishInStorage)
				storage:RemoveFish(amount)

				local data: SendStorageFishData = {
					Amount = amount,
					HelperId = request.HelperId,
					JobId = request.JobId,
					Player = request.Player,
				}
				Events.FireBindableEvent(Events.BindableNames.SendStorageFish, data)
			end)
		end
	end
end

-- //SECTION - Handle Building Events
function ChainManager.HandleBuildingEvent(self: ChainManagerInstance, building)
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
function ChainManager.ResetTravellingAttributes(self: ChainManagerInstance)
	local primary = self.TenderModel.PrimaryPart
	for name, _ in pairs(primary:GetAttributes()) do
		if name ~= FFGEnum.ATTRIBUTES.IsPurchased then primary:SetAttribute(name, false) end
	end
end

function ChainManager.StartTenderCycle(self: ChainManagerInstance)
	self:ResetTravellingAttributes()

	local boatPos = self.BoatModel.PrimaryPart.CFrame * CFrame.new(0, -15, 0)
	self.LaneTender:MoveToBoat(boatPos)
end

function ChainManager.StartLoadingFish(self: ChainManagerInstance)
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

function ChainManager.StartUnloadingFish(self: ChainManagerInstance)
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

	-- Simple approach: calculate fish per second and track remaining unload time
	local fishPerSecond = initialCargo / unloadDuration
	local remainingUnloadTime = unloadDuration

	while remainingUnloadTime > 0 and tender.FishInStorage > 0 do
		-- Check if we can unload
		local canUnload = storage.IsPurchased and not storage:IsStorageFull()

		if canUnload then
			tender:DestroyTenderStoppedBillboard()

			-- Calculate how much fish to unload this second
			local fishToUnload = math.min(fishPerSecond, tender.FishInStorage)
			local storageSpace = storage.CurrentMaxStorage - storage.FishInStorage
			local actualUnload = math.min(fishToUnload, storageSpace)

			if actualUnload > 0 then
				tender:RemoveFish(actualUnload)
				storage:AddFish(actualUnload)
			end

			-- Decrease remaining time only when actually unloading
			remainingUnloadTime = remainingUnloadTime - 1
		else
			-- Storage is full or not purchased - show stopped billboard but don't count time
			tender:ShowTenderStoppedBillboard()
		end

		task.wait(1)
	end

	-- Finished unloading
	tender:DestroyTenderStoppedBillboard()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
end
-- //!SECTION

-- //SECTION - Cleanup
function ChainManager.Destroy(self: ChainManagerInstance)
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.LaneBoat:Destroy()
	self.LaneTender:Destroy()
	self.LaneStorage:Destroy()

	self:ResetTravellingAttributes()
end
-- //!SECTION

return ChainManager
