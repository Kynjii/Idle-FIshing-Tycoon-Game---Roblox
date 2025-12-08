local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Notification = require(ServerScriptService.Server.Classes.Modules.Notification)
local FishingRods = require(ServerScriptService.Server.Data.FishingRods)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local RodType = require(ReplicatedStorage.Shared.Types.RodType)

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("FishingRodShop")
-- //!SECTION

local FishingRodShopManager = {}
FishingRodShopManager.__index = FishingRodShopManager

type FishingRodShopManager = typeof(setmetatable({}, FishingRodShopManager))

function FishingRodShopManager.New(player: Player, teamId: number): FishingRodShopManager
	local self = setmetatable({} :: FishingRodShopManager, FishingRodShopManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.FishingRodShop
	self.Id = HttpService:GenerateGUID(false)
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.ShopModel = self:FindShopModel(teamId)

	self.Inventory = self:GenerateInventory()

	self._cleaner = Trove.new()

	self:AttachEventListeners()
	self:Initialize()

	return self
end

function FishingRodShopManager.FindShopModel(self: FishingRodShopManager, teamId: number): Model?
	for _, taggedShop: Instance in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

function FishingRodShopManager.GenerateInventory(self: FishingRodShopManager)
	local copy = TableUtil.Copy(FishingRods, true)

	local playerRods = DataService.GetRods(self.Player)
	for _, rod in pairs(playerRods) do
		for key, rodCopy in pairs(copy) do
			if rodCopy.Id == rod.Id then
				copy[key] = nil
				break
			end
		end
	end

	return copy
end

function FishingRodShopManager.PurchaseRod(self: FishingRodShopManager, rodId: number): ()
	local rodInShop = TableUtil.Find(self.Inventory, function(rod)
		return rod.Id == rodId
	end) :: RodType.FishingRodType

	if not rodInShop then return end

	if not DataService.CanAfford(self.Player, rodInShop.CurrencyType, rodInShop.Cost or 0) then
		Notification.SendAlert(self.Player, "Not enough gold.")
		return
	end

	DataService.Spend(self.Player, rodInShop.CurrencyType, rodInShop.Cost)

	Events.FireBindableEvent(Events.BindableNames.PurchasedRod, { Player = self.Player, Rod = rodInShop })
	self.Inventory[rodInShop.Key] = nil

	Events.FireEvent(Events.RemoteNames.UpdateFishingRodShopUI, self.Player, self.Inventory)
end

-- //SECTION - UI Setup
function FishingRodShopManager.Initialize(self: FishingRodShopManager): ()
	if self.ShopModel then self:SetupProximityPrompt(self.ShopModel) end
end

function FishingRodShopManager.SetupProximityPrompt(self: FishingRodShopManager, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	proximityPrompt.HoldDuration = 0
	proximityPrompt.MaxActivationDistance = self.Entity ~= FFGEnum.CLASS.ENTITY_NAME.FishingRodShop and 5 or 15
	proximityPrompt.MaxIndicatorDistance = proximityPrompt.MaxActivationDistance * 5
	proximityPrompt.ObjectText = "Open"
	proximityPrompt.ActionText = `{self.Entity}`

	self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player)
		if player.UserId ~= self.Owner then return end

		Events.FireEvent(Events.RemoteNames.OpenFishingRodShop, self.Player, self.Inventory)
	end))

	return proximityPrompt
end
-- //!SECTION

-- //SECTION - Event Listeners
function FishingRodShopManager.AttachEventListeners(self: FishingRodShopManager): ()
	local itemPurchased = Events.GetRemote(Events.RemoteNames.RodPurchased)
	if itemPurchased then
		self._cleaner:Add(itemPurchased.OnServerEvent:Connect(function(player: Player, rodId: number)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			self:PurchaseRod(rodId)
		end))
	end

	local updateInfoPanel = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanel then
		updateInfoPanel.OnServerEvent:Connect(function(player: Player, data: { Item: RodType.FishingRodType, isFishDex: boolean? })
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if data.isFishDex then return end
			if not data.Item and data.Item.Entity == FFGEnum.CLASS.ENTITY_NAME.FishingRod then return end

			local rodInShop = TableUtil.Find(self.Inventory, function(rod: RodType.FishingRodType)
				return rod.Id == data.Item.Id
			end) :: RodType.FishingRodType

			if not rodInShop then return end

			Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, { Item = rodInShop })
		end)
	end
end
-- //!SECTION

-- //SECTION - Cleanup
function FishingRodShopManager.Destroy(self: FishingRodShopManager): ()
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
	self.TeamId = nil
	self.ShopModel = nil
end
-- //!SECTION

return FishingRodShopManager
