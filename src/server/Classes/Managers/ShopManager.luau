local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local ShopItems = require(ReplicatedStorage.Shared.Items.ShopItems)

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("Shop")
-- //!SECTION

local ShopManager = {}
ShopManager.__index = ShopManager

type ShopManager = typeof(setmetatable({}, ShopManager))

local shopCatalog: { ShopItems.ShopItem } = ShopItems

function ShopManager.New(playerItemData: { ShopItems.ShopItem }, player: Player, teamId: number): ShopManager
	local self = setmetatable({}, ShopManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.Shop
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.Model = self:FindShopModel(teamId)
	self.PlayerItemData = playerItemData
	self.ShopCatalog = shopCatalog

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function ShopManager.FindShopModel(self: ShopManager, teamId: number): Instance?
	for _, taggedShop in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

function ShopManager.PurchaseItem(self: ShopManager, itemId: number): ()
	local owned = self.PlayerItemData[itemId]
	if owned then return end

	local item = self.ShopCatalog[itemId]
	if not item then
		print("no item found", self.ShopCatalog, itemId)
		return
	end

	if not DataService.CanAfford(self.Player, item.currencyType, item.baseCost) then return end

	DataService.Spend(self.Player, item.currencyType, item.baseCost)
	self.PlayerItemData[itemId] = item
	DataService.SaveItem(self.Player, itemId, item)
end

-- //SECTION - UI Setup
function ShopManager:Initialize(): ()
	self:Show()
	self:CanCollide()

	-- Setup UI components
	if self.Model then self:SetupProximityPrompt(self.Model) end

	Events.FireEvent(Events.RemoteNames.PrepareShopItems, self.Player, self.PlayerItemData)
end

function ShopManager.SetupProximityPrompt(self: ShopManager, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function ShopManager.Show(self: ShopManager): ()
	ClassVisualizer.Show(self.Model)
end

function ShopManager.Hide(self: ShopManager): ()
	ClassVisualizer.Hide(self.Model)
end

function ShopManager.CanCollide(self: ShopManager): ()
	ClassVisualizer.CanCollide(self.Model)
end

function ShopManager.CannotCollide(self: ShopManager): ()
	ClassVisualizer.CannotCollide(self.Model)
end
-- //!SECTION

-- //SECTION - Event Listeners
function ShopManager.AttachEventListeners(self: ShopManager): ()
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function ShopManager.Destroy(self: ShopManager): ()
	self:Hide()
	self:CannotCollide()

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return ShopManager
