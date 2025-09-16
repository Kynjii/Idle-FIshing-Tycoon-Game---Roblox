local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Boat: Boat = require(ServerScriptService.Server.Classes.Boat)
local PortStorage = require(ServerScriptService.Server.Classes.PortStorage)
local Tender: Tender = require(ServerScriptService.Server.Classes.Tender)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local ChainManagerType = require(ServerScriptService.Server.Classes.Types.ChainManagerType)

local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")
local taggedStorage = CollectionService:GetTagged("Storage")

type Boat = BoatType.Boat
type Tender = TenderType.Tender
type ChainManager = ChainManagerType.ChainManagerInstance

local ChainManager = {} :: ChainManager
ChainManager.__index = ChainManager

function ChainManager.New(realmData, tier: number, player: Player, teamId: number)
	local self: ChainManager = setmetatable({}, ChainManager)

	local boatsArr = realmData.Boats
	local tendersArr = realmData.Tenders
	local storageArr = realmData.Storages

	self.Player = player
	self.Tier = tier
	self.TeamId = teamId

	-- Create Boat
	self.BoatModel = self:FindBoatModel() :: Model
	if not self.BoatModel then return end
	self.LaneBoat = Boat.New(boatsArr[tier], player, self.BoatModel)

	-- Create Tender
	self.TenderModel = self:FindTenderModel() :: Model
	self.LaneTender = Tender.New(tendersArr[tier], player, self.TenderModel, self.BoatModel)

	-- Create Port Storage
	self.StorageModel = self:FindStorageModel() :: Model
	self.LaneStorage = PortStorage.New(storageArr[tier], player, self.StorageModel)

	-- Tender Travelling props
	self.loadingTime = 1

	-- Attach listeners to handle the Tender Travelling Cycle
	self:AttachAttListeners()

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
end

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

	local storageFull = false
	while not storageFull do
		if self.LaneTender:IsStorageFull() then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, true)
			storageFull = true
			break
		end

		local availableStorage = self.LaneTender.CurrentMaxStorage - self.LaneTender.FishInStorage
		local tickAmount = self.LaneTender.CurrentMaxStorage / 10
		local tenderAmount = math.min(availableStorage, tickAmount)
		local boatAmount = math.min(self.LaneBoat.FishInStorage)
		local amount = math.min(tenderAmount, boatAmount)

		self.LaneBoat:RemoveFish(amount)
		self.LaneTender:AddFish(amount)

		task.wait(1)
	end
end

function ChainManager:StartUnloadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, false)

	while true do
		local tender = self.LaneTender
		local storage = self.LaneStorage

		local storageFree = storage.CurrentMaxStorage - storage.FishInStorage

		if storageFree <= 0 then
			task.wait(1)
		else
			local tickAmount = tender.CurrentMaxStorage / 10
			local amount = math.min(tickAmount, tender.FishInStorage, storageFree)

			tender:RemoveFish(amount)
			storage:AddFish(amount)
		end

		if tender.FishInStorage <= 0 then
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
			tender.FishInStorage = 0
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
end
-- //!SECTION

return ChainManager
