local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Boat: Boat = require(ServerScriptService.Server.Classes.Boat)
local Tender: Tender = require(ServerScriptService.Server.Classes.Tender)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local BoatManagerType = require(ServerScriptService.Server.Classes.Types.BoatManagerType)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local DataService = require(ServerScriptService.Server.Services.DataService)

local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")

type Boat = BoatType.Boat
type Tender = TenderType.Tender
type BoatManager = BoatManagerType.BoatManagerInstance

local BoatManager = {} :: BoatManager
BoatManager.__index = BoatManager

function BoatManager.New(boatsArr: BoatType.BoatProps, tendersArr: TenderType.TenderProps, tier: number, player: Player)
	local self: BoatManager = setmetatable({}, BoatManager)

	self.Player = player
	self.Tier = tier
	self.BoatModel = self:FindBoatModel(player, tier) :: Model
	if not self.BoatModel then return end
	self.LaneBoat = Boat.New(boatsArr[tier], player, self.BoatModel)

	self.TenderModel = self:FindTenderModel(player, tier) :: Model
	self.LaneTender = Tender.New(tendersArr[tier], player, self.TenderModel, self.BoatModel)

	-- Tender Travelling props
	self.loadingTime = 1

	-- Attach listeners to handle the Tender Travelling Cycle
	self:AttachAttListeners()

	local firstRun = true
	if self.LaneTender.isPurchased then self:StartTenderCycle(firstRun) end

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

function BoatManager:Initialize()
	self.LaneBoat:Initialize()
	self.LaneTender:Initialize()
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

function BoatManager:StartTenderCycle(firstRun)
	if firstRun then
		self:ResetTravellingAttributes()
	else
		self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, true)
	end

	local boatPos = self.BoatModel.PrimaryPart.CFrame
	self.LaneTender:MoveToBoat(boatPos)
end

function BoatManager:StartLoadingFish()
	self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedUnloading, false)

	local storageFull = false
	while not storageFull do
		if self.LaneTender:IsStorageFull() then
			print("tender storage full, setting att and returning to port")
			self.TenderModel.PrimaryPart:SetAttribute(FFGEnum.ATTRIBUTES.finishedLoading, true)
			storageFull = true
		end

		local availableStorage = self.LaneTender.CurrentMaxStorage - self.LaneTender.FishInStorage
		-- //TODO - figure out the amount so that it takes a 10th of the max storage per tick (loadSpeed can be an upgradable prop later)
		local amount = math.min(availableStorage, self.LaneBoat.FishInStorage)

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
		DataService.Earn(self.Player, FFGEnum.CURRENCY_TYPES.Gold, amount)
		print("Earned:", amount)

		task.wait(1)
	end
end

-- //!SECTION

return BoatManager
