local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local DataService = require(ServerScriptService.Server.Services.DataService)
local EventListeners = {}

function EventListeners.Attach(class: BoatType.Boat | TenderType.Tender | PortStorageType.Storage | BuildingType.Building)
	local self = class
	local function handleStateUpdate(player)
		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost) then return end

		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not self.isPurchased and self.BaseCost or self.UpgradeCost)

		if self.isPurchased then
			self:Upgrade()
		else
			self:Purchase()
			self:Show()
			self:CanCollide()

			if self.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then self:StartFishing() end
		end

		-- Update UIs
		self:UpdatePurchaseBoardUI()

		self:Save()
	end

	-- Purchased Event
	local purchasedEvent = Events.GetRemote(Events.RemoteNames.EntityPurchased)
	if purchasedEvent then purchasedEvent.OnServerEvent:Connect(function(player, entityId)
		if self.Player ~= player or self.Owner ~= player.UserId then return end
		if self.Id ~= entityId then return end

		handleStateUpdate(player)
	end) end

	-- Upgraded Event
	local upgradedEvent = Events.GetRemote(Events.RemoteNames.EntityUpgraded)
	if upgradedEvent then upgradedEvent.OnServerEvent:Connect(function(player, entityId)
		if self.Player ~= player or self.Owner ~= player.UserId then return end
		if self.Id ~= entityId then return end

		handleStateUpdate(player)
	end) end
end

return EventListeners
