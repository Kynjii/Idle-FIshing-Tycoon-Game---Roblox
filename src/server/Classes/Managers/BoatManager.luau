local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Boat: Boat = require(ServerScriptService.Server.Classes.Boat)
local PortStorage = require(ServerScriptService.Server.Classes.PortStorage)
local Tender: Tender = require(ServerScriptService.Server.Classes.Tender)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local BoatManagerType = require(ServerScriptService.Server.Classes.Types.BoatManagerType)

local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")
local taggedStorage = CollectionService:GetTagged("Storage")

type Boat = BoatType.Boat
type Tender = TenderType.Tender
type BoatManager = BoatManagerType.BoatManagerInstance

local BoatManager = {} :: BoatManager
BoatManager.__index = BoatManager

function BoatManager.New(realmData, tier: number, player: Player)
	local self: BoatManager = setmetatable({}, BoatManager)

	local boatsArr = realmData.Boats
	local tendersArr = realmData.Tenders
	local storageArr = realmData.Storages

	self.Player = player
	self.Tier = tier

	-- Create Boat
	self.BoatModel = self:FindBoatModel(player, tier) :: Model
	if not self.BoatModel then return end
	self.LaneBoat = Boat.New(boatsArr[tier], player, self.BoatModel)

	-- Create Tender
	self.TenderModel = self:FindTenderModel(player, tier) :: Model
	self.LaneTender = Tender.New(tendersArr[tier], player, self.TenderModel, self.BoatModel)

	-- Create Port Storage
	self.StorageModel = self:FindStorageModel(player, tier) :: Model
	self.LaneStorage = PortStorage.New(storageArr[tier], player, self.StorageModel)

	-- Tender Travelling props
	self.loadingTime = 1

	-- Attach listeners to handle the Tender Travelling Cycle
	self:AttachAttListeners()

	if self.LaneTender.isPurchased then self:StartTenderCycle() end

	return self
end

function BoatManager:FindBoatModel(player, tier)
	for _, taggedBoat in ipairs(taggedBoats) do
		local taggedBoatTier = taggedBoat:GetAttribute("Tier")
		if taggedBoatTier == tier then return taggedBoat end
	end

	return nil
end

function BoatManager:FindTenderModel(player, tier)
	for _, taggedTender in ipairs(taggedTenders) do
		local taggedTenderTier = taggedTender:GetAttribute("Tier")
		if taggedTenderTier == tier then return taggedTender end
	end

	return nil
end

function BoatManager:FindStorageModel(player, tier)
	for _, taggedStorageUnit in ipairs(taggedStorage) do
		local taggedStorageUnitTier = taggedStorageUnit:GetAttribute("Tier")
		if taggedStorageUnitTier == tier then return taggedStorageUnit end
	end

	return nil
end

function BoatManager:Initialize()
	self.LaneBoat:Initialize()
	self.LaneTender:Initialize()
	self.LaneStorage:Initialize()
end

function BoatManager:AttachAttListeners()
	self.TenderModel.PrimaryPart.AttributeChanged:Connect(function(attributeName)
		-- isPurchased triggers the start of the cycle
		if attributeName == FFGEnum.ATTRIBUTES.isPurchased and self.TenderModel.PrimaryPart:GetAttribute(attributeName) == true then
			self:StartTenderCycle()
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
end

-- //SECTION - Tender Travelling Cycle Functions used by the AttListeners
function BoatManager:ResetTravellingAttributes()
	local attributes = self.TenderModel.PrimaryPart:GetAttributes()
	for k, v in pairs(attributes) do
		if k == FFGEnum.ATTRIBUTES.isPurchased then return end

		v = false
	end
end

function BoatManager:StartTenderCycle()
	self:ResetTravellingAttributes()

	local boatPos = self.BoatModel.PrimaryPart.CFrame
	self.LaneTender:MoveToBoat(boatPos)
end

function BoatManager:StartLoadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, false)

	local storageFull = false
	while not storageFull do
		if self.LaneTender:IsStorageFull() then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, true)
			storageFull = true
		end

		local availableStorage = self.LaneTender.CurrentMaxStorage - self.LaneTender.FishInStorage
		local tickAmount = self.LaneTender.CurrentMaxStorage / 10
		local amount = math.min(availableStorage, tickAmount)

		self.LaneBoat:RemoveFish(amount)
		self.LaneTender:AddFish(amount)

		task.wait(1)
	end
end

function BoatManager:StartUnloadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, false)

	local storageEmpty = false
	while not storageEmpty do
		if self.LaneTender.FishInStorage <= 0 then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
			storageEmpty = true
		end

		local amount = self.LaneTender.CurrentMaxStorage / 10

		self.LaneTender:RemoveFish(amount)
		self.LaneStorage:AddFish(amount)

		task.wait(1)
	end
end

-- //!SECTION

return BoatManager
