local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Helper = require(ServerScriptService.Server.Classes.Helper)
local Notification = require(ServerScriptService.Server.Classes.Modules.Notification)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
local SetInterval = require(ServerScriptService.Server.Modules.SetInterval)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local SecToMins = require(ReplicatedStorage.Shared.Utils.SecToMins)

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("HelperShop")
-- //!SECTION

local HelperShopManager = {}
HelperShopManager.__index = HelperShopManager

type HelperShopManager = typeof(setmetatable({}, HelperShopManager))

local REFRESH_INTERVAL: number = 60 * 5

local INVENTORY_AMOUNT: number = 10

type ShopState = {
	Inventory: { [string]: HelperType.HelperData },
	Entity: string,
	Id: string,
	Owner: number,
	CompletedTutorial: boolean,
	PeriodEnd: number,
}

function HelperShopManager.New(shopState: ShopState, player: Player, teamId: number): HelperShopManager
	local self = setmetatable({} :: HelperShopManager, HelperShopManager)

	self.Entity = FFGEnum.CLASS.ENTITY_NAME.Shop
	self.Id = shopState and shopState.Id or HttpService:GenerateGUID(false)
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.ShopModel = self:FindShopModel(teamId)

	self.CurrentPeriod = math.floor(os.time() / REFRESH_INTERVAL)
	self.PeriodEnd = (self.CurrentPeriod + 1) * REFRESH_INTERVAL
	self.TimeRemaining = self.PeriodEnd - os.time()

	self.Inventory = shopState and shopState.Inventory or nil
	self:HandleStock(shopState)

	self.CompletedTutorial = shopState and shopState.CompletedTutorial or DataService.CompletedTutorial(self.Player)

	self._cleaner = Trove.new()

	self.CountdownTimer = self:CreateRefreshBillboard()
	self:StartRefreshMonitor()

	self:AttachEventListeners()

	return self
end

function HelperShopManager.HandleStock(self: HelperShopManager, shopState): ()
	-- If for some reason the inventory didn't save or it's a first time player that has no saved data, stock the shop
	if not self.Inventory then
		self:RestockShop()
	else
		-- If the shop is within the same time period as when it was saved, don't restock (prevent exploits)
		if self.CurrentPeriod == shopState.CurrentPeriod then
			return
		else
			self:RestockShop()
		end
	end
end

function HelperShopManager.FindShopModel(self: HelperShopManager, teamId: number): Model?
	for _, taggedShop: Instance in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

function HelperShopManager.Purchasehelper(self: HelperShopManager, helperId: string): ()
	local helperInShop = TableUtil.Find(self.Inventory, function(helper: HelperType.HelperData)
		return helper.Id == helperId
	end) :: HelperType.HelperData

	if not helperInShop or helperInShop.IsPurchased then return end

	if not DataService.CanAfford(self.Player, helperInShop.CurrencyType, helperInShop.BaseCost or 0) then
		Notification.SendAlert(self.Player, "Not enough gold.")
		return
	end
	if not self.CompletedTutorial then
		Tutorial.Update(self.Player, self.TeamId)
		self.CompletedTutorial = DataService.CompletedTutorial(self.Player)
	end

	local helperClass = Helper.New(helperInShop, self.Player, self.TeamId)
	helperClass:Purchase()
	helperClass:Destroy()

	DataService.Spend(self.Player, helperClass.CurrencyType, helperClass.BaseCost)

	self.Inventory[helperId] = nil

	Events.FireEvent(Events.RemoteNames.UpdateHelperShopUI, self.Player, helperId)
	Events.FireBindableEvent(Events.BindableNames.PurchasedHelper, { Player = self.Player })

	self:Save()
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
		self:UpdateRefreshBillboard()

		if self.TimeRemaining <= 1 then self:RestockShop() end
	end, 1))
end

function HelperShopManager.RestockShop(self: HelperShopManager)
	self.Inventory = {}

	local preparedData = {}

	for i = 1, INVENTORY_AMOUNT do
		-- //TODO - TEMP until other job categories are in the game
		local isTransporter = false
		while not isTransporter do
			local helper = Helper.CreateStateData(self.Player, "Gold")

			if helper.JobCategory == FFGEnum.JOB_CATEGORY.Transporting then
				preparedData[helper.Id] = helper
				isTransporter = true
			end

			task.wait()
		end
	end

	self.Inventory = preparedData
	Events.FireEvent(Events.RemoteNames.PrepareHelperShop, self.Player, HttpService:JSONEncode(preparedData))

	self:Save()
end

function HelperShopManager.CreateRefreshBillboard(self: HelperShopManager)
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = self.ShopModel.PrimaryPart
	billboard.Size = UDim2.fromScale(10, 10)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.ResetOnSpawn = false
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.Parent = self.ShopModel.PrimaryPart

	local countdownTimer = Instance.new("TextLabel")
	countdownTimer.Size = UDim2.fromScale(1, 1)
	countdownTimer.Font = FFGEnum.THEME.bigFont
	countdownTimer.TextColor3 = FFGEnum.THEME.color.white
	countdownTimer.TextScaled = true
	countdownTimer.BackgroundTransparency = 1

	local timerText = SecToMins.GetString(self.TimeRemaining)
	countdownTimer.Text = timerText or ""
	countdownTimer.Parent = billboard

	return countdownTimer
end

function HelperShopManager.UpdateRefreshBillboard(self: HelperShopManager)
	local timerText = SecToMins.GetString(self.TimeRemaining)
	if self.CountdownTimer then self.CountdownTimer.Text = timerText or "" end
end

-- //SECTION - UI Setup
function HelperShopManager.Initialize(self: HelperShopManager): ()
	if self.ShopModel then self:SetupProximityPrompt(self.ShopModel) end
end

function HelperShopManager.SetupProximityPrompt(self: HelperShopManager, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	proximityPrompt.HoldDuration = 0
	proximityPrompt.MaxActivationDistance = self.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Shop and 5 or 15
	proximityPrompt.MaxIndicatorDistance = proximityPrompt.MaxActivationDistance * 5
	proximityPrompt.ObjectText = "Open"
	proximityPrompt.ActionText = `{self.Entity}`

	self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player)
		if player.UserId ~= self.Owner then return end

		local shopInventory = self.Inventory or {}
		Events.FireEvent(Events.RemoteNames.OpenHelperShop, self.Player, HttpService:JSONEncode(shopInventory))
	end))

	return proximityPrompt
end
-- //!SECTION

-- //SECTION - Event Listeners
function HelperShopManager.AttachEventListeners(self: HelperShopManager): ()
	local itemPurchased = Events.GetRemote(Events.RemoteNames.HelperPurchased)
	if itemPurchased then
		self._cleaner:Add(itemPurchased.OnServerEvent:Connect(function(player: Player, helperId: string)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			local canProceed = Tutorial.CheckTutorialState(player, self)
			if not canProceed then
				Notification.SendAlert(player, "Follow the Tutorial to unlock this!")
				return
			end

			self:Purchasehelper(helperId)
		end))
	end

	local updateInfoPanel = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanel then
		updateInfoPanel.OnServerEvent:Connect(function(player: Player, sentHelper: HelperType.HelperInstance)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			local helperInShop = TableUtil.Find(self.Inventory, function(helper: HelperType.HelperData)
				return helper.Id == sentHelper.Id
			end) :: HelperType.HelperData

			if not helperInShop then return end
			if helperInShop then Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, helperInShop) end
		end)
	end
end
-- //!SECTION

-- //SECTION - Saving and Loading
function HelperShopManager.Serialize(self: HelperShopManager): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		Owner = self.Owner,
		Inventory = self.Inventory,
		CompletedTutorial = self.CompletedTutorial,
		CurrentPeriod = self.CurrentPeriod,
	}
end

function HelperShopManager.Save(self: HelperShopManager)
	DataService.SaveHelperShop(self.Player, self:Serialize())
end

-- //!SECTION

-- //SECTION - Cleanup
function HelperShopManager.Destroy(self: HelperShopManager): ()
	pcall(function()
		self:Save()
	end)

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

return HelperShopManager
