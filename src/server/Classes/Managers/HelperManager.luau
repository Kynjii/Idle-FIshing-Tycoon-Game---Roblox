local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Helper = require(ServerScriptService.Server.Classes.Helper)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
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

function HelperManager.New(playerHelperData: { TutorialHelpers: { HelperType.HelperData }, HelpersOwned: { HelperType.HelperData } }, shopState: { [string]: any }, player: Player, teamId: number): HelperManager
	local self = setmetatable({}, HelperManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.Shop
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.ShopModel = self:FindShopModel(teamId)
	self.HelperModel = self:FindHelperModel(teamId)
	self.TutorialState = playerHelperData.TutorialHelpers
	self.HelpersOwned = playerHelperData.HelpersOwned
	self.ShopState = shopState

	self._cleaner = Trove.new()

	self:HandleTutorialState()

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

function HelperManager.Purchasehelper(self: HelperManager, helper: HelperType.HelperData): ()
	if not DataService.CanAfford(self.Player, helper.CurrencyType, helper.Stats and helper.Stats.BaseCost) then return end

	local completedTutorial = DataService.CompletedTutorial(self.Player)
	local helperClass = Helper.New(helper, self.Player, self.TeamId)
	helperClass:Purchase()
	helperClass:Save()

	if completedTutorial then self.HelpersOwned[helper.Id] = helperClass end

	DataService.Spend(self.Player, helperClass.CurrencyType, helperClass.Stats and helperClass.Stats.BaseCost)
end

-- //SECTION - Tutorial Handling
function HelperManager.HandleTutorialState(self)
	local isCompleted = DataService.CompletedTutorial(self.Player)
	if isCompleted then return end

	local numOfHelpersRemaining = 0
	for _, tutorialHelper in pairs(self.TutorialState) do
		if tutorialHelper.IsPurchased then return end
		numOfHelpersRemaining += 1

		if numOfHelpersRemaining == #self.TutorialState then
			isCompleted = true
			break
		end
	end

	if isCompleted then DataService.SaveTutorialState(self.Player, 4) end
end
-- //!SECTION

-- //SECTION - UI Setup
function HelperManager.Initialize(self: HelperManager): ()
	self:Show()
	self:CanCollide()

	-- Setup UI components
	if self.ShopModel then self:SetupProximityPrompt(self.ShopModel) end

	self.Player.CharacterAdded:Once(function()
		Events.FireEvent(Events.RemoteNames.PrepareHelperShop, self.Player, self.TutorialState)
	end)
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

	-- //TODO - Add save function to save current shop state (mainly to prevent players relogging to reroll the shop by checking the refresh status, helpers in stock etc.)

	self.Player = nil :: any
	self.ShopModel = nil :: any
end
-- //!SECTION

return HelperManager
