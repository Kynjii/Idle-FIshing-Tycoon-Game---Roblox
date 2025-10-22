local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Helper = require(ServerScriptService.Server.Classes.Helper)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local TutorialHelpers = require(ServerScriptService.Server.Game.Tutorial.TutorialHelpers)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("HelperShop")
local taggedHelpers = CollectionService:GetTagged("Helper")
-- //!SECTION

local HelperManager = {}
HelperManager.__index = HelperManager

type HelperManager = typeof(setmetatable({}, HelperManager))

local tutorialHelpersCatalog: { HelperType.HelperData } = TutorialHelpers

function HelperManager.New(playerHelperData: { HelperType.HelperData }, player: Player, teamId: number): HelperManager
	local self = setmetatable({}, HelperManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.Shop
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.ShopModel = self:FindShopModel(teamId)
	self.HelperModel = self:FindHelperModel(teamId)
	self.tutorialHelpersCatalog = tutorialHelpersCatalog
	self.PlayerHelperData = playerHelperData

	self._cleaner = Trove.new()

	-- //TODO - if the player has the tutorial helper do not create statedata for it
	-- if the player has all the tutorial helpers, set tutorial state in player data
	-- if player has completed the tutorial and all helper stages, skip this part
	local helpers = {}
	local index = 1
	for _, k in pairs(self.tutorialHelpersCatalog) do
		helpers[index] = Helper.CreateStateData(player, "Gold")
		index += 1
	end

	print(helpers)

	self:AttachEventListeners()

	return self
end

function HelperManager.FindShopModel(self: HelperManager, teamId: number): Instance?
	for _, taggedShop in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

function HelperManager.FindHelperModel(self: HelperManager, teamId: number): Instance?
	for _, taggedHelper in ipairs(taggedHelpers) do
		local taggedHelperId = taggedHelper:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedHelperId == teamId then return taggedHelper end
	end

	return nil
end

function HelperManager.Purchasehelper(self: HelperManager, helperId: number): ()
	local owned = self.PlayerHelperData[helperId]
	if owned then return end

	local helper = TableUtil.Find(self.tutorialHelpersCatalog, function(helper)
		return helper.id == helperId
	end)
	if not helper then
		print("no helper found", self.tutorialHelpersCatalog, helperId)
		return
	end

	if not DataService.CanAfford(self.Player, helper.CurrencyType, helper.BaseCost) then return end

	DataService.Spend(self.Player, helper.CurrencyType, helper.BaseCost)
	self.PlayerHelperData[helperId] = helper
	DataService.SaveHelper(self.Player, helper)
end

-- //SECTION - UI Setup
function HelperManager.Initialize(self: HelperManager): ()
	self:Show()
	self:CanCollide()

	-- Setup UI components
	if self.ShopModel then self:SetupProximityPrompt(self.ShopModel) end

	Events.FireEvent(Events.RemoteNames.PrepareHelperShop, self.Player, self.PlayerHelperData)
end

function HelperManager.SetupProximityPrompt(self: HelperManager, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function HelperManager.Show(self: HelperManager): ()
	ClassVisualizer.Show(self.ShopModel)
end

function HelperManager.Hide(self: HelperManager): ()
	ClassVisualizer.Hide(self.ShopModel)
end

function HelperManager.CanCollide(self: HelperManager): ()
	ClassVisualizer.CanCollide(self.ShopModel)
end

function HelperManager.CannotCollide(self: HelperManager): ()
	ClassVisualizer.CannotCollide(self.ShopModel)
end
-- //!SECTION

-- //SECTION - Event Listeners
function HelperManager.AttachEventListeners(self: HelperManager): ()
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function HelperManager.Destroy(self: HelperManager): ()
	self:Hide()
	self:CannotCollide()

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.ShopModel = nil :: any
end
-- //!SECTION

return HelperManager
