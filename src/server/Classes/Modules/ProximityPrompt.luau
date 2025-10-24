local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)

local PP = {}

type Boat = BoatType.BoatInstance
type Tender = TenderType.TenderInstance
type PortStorage = PortStorageType.StorageInstance
type Building = BuildingType.BuildingInstance

function PP.CreatePP(proximityPrompt: ProximityPrompt, class: Boat | Tender | PortStorage | Building)
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
		typedClass = class
	else
		error("Invalid entity passed to CreatePB")
	end

	proximityPrompt.HoldDuration = 0
	proximityPrompt.MaxActivationDistance = typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Shop and 5 or 15
	proximityPrompt.MaxIndicatorDistance = proximityPrompt.MaxActivationDistance * 5
	proximityPrompt.ObjectText = "Open"
	proximityPrompt.ActionText = `{class.Entity}`

	if typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Shop then
		class._cleaner:Add(proximityPrompt.Triggered:Connect(function(player)
			if player.UserId ~= class.Owner then
				print("Not the owner", player.UserId, class.Owner)
				return
			end
			if class.Level == class.MaxLevel then
				print("max level")
				return
			end

			Events.FireEvent(Events.RemoteNames.OpenEntityDetails, class.Player, typedClass)
		end))
	else
		class._cleaner:Add(proximityPrompt.Triggered:Connect(function(player)
			if player.UserId ~= class.Owner then
				print("Not the owner", player.UserId, class.Owner)
				return
			end

			local shopInventory = typedClass.Inventory or {}
			Events.FireEvent(Events.RemoteNames.OpenHelperShop, class.Player, HttpService:JSONEncode(shopInventory))
		end))
	end

	return proximityPrompt
end

return PP
