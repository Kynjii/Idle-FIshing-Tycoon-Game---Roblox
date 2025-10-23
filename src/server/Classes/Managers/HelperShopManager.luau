local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Helper = require(ServerScriptService.Server.Classes.Helper)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local function dictCount(t)
	local n = 0
	for _ in pairs(t or {}) do
		n += 1
	end
	return n
end

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("HelperShop")
-- //!SECTION

local HelperShopManager = {}
HelperShopManager.__index = HelperShopManager

type HelperShopManager = typeof(setmetatable({}, HelperShopManager))

local REFRESH_INTERVAL: number = 60 * 15

local INVENTORY_AMOUNT: number = 6

type ShopState = {
	Inventory: { [string]: HelperType.HelperData },
}

function HelperShopManager.New(shopState: ShopState, player: Player, teamId: number, TutorialHelpers: { HelperType.HelperData }?): HelperShopManager
	local self = setmetatable({} :: HelperShopManager, HelperShopManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.Shop
	self.Id = shopState and shopState.Id or HttpService:GenerateGUID(false)
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.ShopModel = self:FindShopModel(teamId)
	self.TutorialState = TutorialHelpers

	self.CurrentPeriod = math.floor(os.time() / REFRESH_INTERVAL)
	self.PeriodEnd = (self.CurrentPeriod + 1) * REFRESH_INTERVAL
	self.TimeRemaining = self.PeriodEnd - os.time()
	self.Inventory = shopState and shopState.Inventory or {}
	self.CompletedTutorial = shopState and shopState.CompletedTutorial or self:HandleTutorialState()

	if dictCount(self.Inventory) == 0 then self:RestockShop() end

	self._cleaner = Trove.new()

	self:StartRefreshMonitor()

	self:AttachEventListeners()

	return self
end

function HelperShopManager.FindShopModel(self: HelperShopManager, teamId: number): Instance?
	for _, taggedShop: Instance in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

function HelperShopManager.Purchasehelper(self: HelperShopManager, helperState: HelperType.HelperData): ()
	if not DataService.CanAfford(self.Player, helperState.CurrencyType, helperState.BaseCost or 0) then return end

	local helperClass = Helper.New(helperState, self.Player, self.TeamId)
	helperClass:Purchase()
	helperClass:Save()

	DataService.Spend(self.Player, helperClass.CurrencyType, helperClass.BaseCost)
end

function HelperShopManager.GetTimeRemaining(self: HelperShopManager)
	print(self.TimeRemaining)
end

function HelperShopManager.SetCurrentPeriod(self: HelperShopManager)
	self.CurrentPeriod = math.floor(os.time() / REFRESH_INTERVAL)
end

function HelperShopManager.SetPeriodEnd(self: HelperShopManager)
	self.PeriodEnd = (self.CurrentPeriod + 1) * REFRESH_INTERVAL
end

function HelperShopManager.SetTimeRemaining(self: HelperShopManager)
	self.TimeRemaining = self.PeriodEnd - os.time()
end

function HelperShopManager.StartRefreshMonitor(self: HelperShopManager)
	self._cleaner:Add(SetInterval(function()
		self:SetCurrentPeriod()
		self:SetPeriodEnd()
		self:SetTimeRemaining()

		if self.TimeRemaining <= 0 then
			if not self.CompletedTutorial then return end
			self:RestockShop()
		end
	end, 1))
end

function HelperShopManager.RestockShop(self: HelperShopManager)
	self.Inventory = {}

	local preparedData = {}

	if not self.CompletedTutorial then
		for i, tutHelper in pairs(self.TutorialState) do
			local helper = Helper.CreateStateData(self.Player, "Gold", tutHelper)
			preparedData[helper.Id] = helper
		end
	else
		for i = 1, INVENTORY_AMOUNT do
			local helper = Helper.CreateStateData(self.Player, "Gold")
			preparedData[helper.Id] = helper
		end
	end

	self.Inventory = preparedData
	Events.FireEvent(Events.RemoteNames.PrepareHelperShop, self.Player, HttpService:JSONEncode(preparedData))
end

-- //SECTION - Tutorial Handling
function HelperShopManager.HandleTutorialState(self): boolean
	local isCompleted: boolean = DataService.CompletedTutorial(self.Player)
	if isCompleted then return true end

	local numOfHelpersRemaining: number = 0
	for _, tutorialHelper in pairs(self.TutorialState) do
		if tutorialHelper.IsPurchased then return end
		numOfHelpersRemaining += 1

		if numOfHelpersRemaining == 0 then
			isCompleted = true
			break
		end
	end

	if isCompleted then
		DataService.SaveTutorialState(self.Player, 4)
		return true
	end

	return false
end
-- //!SECTION

-- //SECTION - UI Setup
function HelperShopManager.Initialize(self: HelperShopManager): ()
	self:Show()
	self:CanCollide()

	-- Setup UI components
	if self.ShopModel then self:SetupProximityPrompt(self.ShopModel) end
end

function HelperShopManager.SetupProximityPrompt(self: HelperShopManager, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function HelperShopManager.Show(self: HelperShopManager): ()
	ClassVisualizer.Show(self.ShopModel)
end

function HelperShopManager.Hide(self: HelperShopManager): ()
	ClassVisualizer.Hide(self.ShopModel)
end

function HelperShopManager.CanCollide(self: HelperShopManager): ()
	ClassVisualizer.CanCollide(self.ShopModel)
end

function HelperShopManager.CannotCollide(self: HelperShopManager): ()
	ClassVisualizer.CannotCollide(self.ShopModel)
end
-- //!SECTION

-- //SECTION - Event Listeners
function HelperShopManager.AttachEventListeners(self: HelperShopManager): ()
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Saving and Loading
function HelperShopManager.Serialize(self: HelperShopManager): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		Owner = self.Owner,
		TutorialState = self.TutorialState,
		Inventory = self.Inventory,
		CompletedTutorial = self.CompletedTutorial,
	}
end

function HelperShopManager.Save(self: HelperShopManager)
	DataService.SaveHelperShop(self.Player, self:Serialize())
end

-- //!SECTION

-- //SECTION - Cleanup
function HelperShopManager.Destroy(self: HelperShopManager): ()
	self:Hide()
	self:CannotCollide()

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Save()

	self.Player = nil :: any
	self.ShopModel = nil :: any
end
-- //!SECTION

return HelperShopManager
