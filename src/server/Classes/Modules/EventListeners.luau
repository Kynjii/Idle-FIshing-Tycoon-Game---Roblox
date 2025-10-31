local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local DataService = require(ServerScriptService.Server.Services.DataService)

local EventListeners = {}

-- //SECTION - TYPES
type Boat = BoatType.BoatInstance
type Tender = TenderType.TenderInstance
type PortStorage = PortStorageType.StorageInstance
type Building = BuildingType.BuildingInstance
-- //!SECTION

function EventListeners.Attach(class: Boat | Tender | PortStorage | Building)
	local typedClass
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		typedClass = class :: Boat
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		typedClass = class :: Tender
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.PortStorage then
		typedClass = class :: PortStorage
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		typedClass = class :: Building
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Shop then
		-- //TODO - add type
		typedClass = class
	else
		error("Invalid entity passed to CreatePB")
	end

	local function checkTutorialState(player: Player): boolean
		if not DataService.CompletedTutorial(player) then
			-- If the class is either a building or not tier 1, return
			if typedClass.Tier ~= 1 or typedClass.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then return false end

			local tutorialOrder = {
				[1] = FFGEnum.CLASS.ENTITY_NAME.Boat,
				[2] = FFGEnum.CLASS.ENTITY_NAME.Tender,
				[3] = FFGEnum.CLASS.ENTITY_NAME.PortStorage,
				[4] = FFGEnum.CLASS.ENTITY_NAME.Shop,
			}

			-- Check to see if the entity matches the correct stage
			local currentTutorialStage = DataService.CurrentTutorialStage(player)
			if currentTutorialStage then
				local currentTutotialEntity = tutorialOrder[currentTutorialStage]

				if typedClass.Entity == currentTutotialEntity then
					return true
				else
					return false
				end
			else
				if typedClass.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
					return true
				else
					return false
				end
			end
		else
			return true
		end
	end

	-- //SECTION - Handle non-shop events
	if typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Shop then
		local function handleStateUpdate(player)
			local canProceed = checkTutorialState(player)
			if not canProceed then return end

			-- See if the player can afford the state update (purchase / upgrade)
			if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost) then return end

			DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost)

			if typedClass.IsPurchased then
				typedClass:Upgrade()
			else
				typedClass:Purchase()
				typedClass:Show()
				typedClass:CanCollide()

				if typedClass.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then typedClass:StartFishing() end
			end

			-- Update UIs
			typedClass:UpdatePurchaseBoardUI()
			typedClass:Save()
		end

		-- Purchased Event
		local purchasedEvent = Events.GetRemote(Events.RemoteNames.EntityPurchased)
		if purchasedEvent then typedClass._cleaner:Add(purchasedEvent.OnServerEvent:Connect(function(player: Player, entityId: string)
			if typedClass.Player ~= player or typedClass.Owner ~= player.UserId then return end
			if typedClass.Id ~= entityId then return end

			handleStateUpdate(player)
		end)) end

		-- Upgraded Event
		local upgradedEvent = Events.GetRemote(Events.RemoteNames.EntityUpgraded)
		if upgradedEvent then typedClass._cleaner:Add(upgradedEvent.OnServerEvent:Connect(function(player: Player, entityId: string)
			if typedClass.Player ~= player or typedClass.Owner ~= player.UserId then return end
			if typedClass.Id ~= entityId then return end

			handleStateUpdate(player)
		end)) end
		-- //!SECTION
	else
		-- Shop Item Purchased
		local itemPurchased = Events.GetRemote(Events.RemoteNames.HelperPurchased)
		if itemPurchased then typedClass._cleaner:Add(itemPurchased.OnServerEvent:Connect(function(player: Player, helperId: string)
			if typedClass.Player ~= player or typedClass.Owner ~= player.UserId then return end

			local canProceed = checkTutorialState(player)
			if not canProceed then return end

			typedClass:Purchasehelper(helperId)
		end)) end
	end
end

return EventListeners
