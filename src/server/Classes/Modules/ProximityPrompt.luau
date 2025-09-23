local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local BoatType = require(ServerScriptService.Server.Classes.Types.Classes.BoatType)
local PortStorageType = require(ServerScriptService.Server.Classes.Types.Classes.PortStorageType)
local TenderType = require(ServerScriptService.Server.Classes.Types.Classes.TenderType)
local DataService = require(ServerScriptService.Server.Services.DataService)

local PP = {}

function PP.CreatePP(proximityPrompt: ProximityPrompt, class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	if class.Level == class.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
		return proximityPrompt
	end

	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 5
	proximityPrompt.ObjectText = class.isPurchased and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = class.isPurchased and "Gold: " .. FormatNumber(class.UpgradeCost) or "Gold: " .. FormatNumber(class.BaseCost)

	class._cleaner:add(proximityPrompt.Triggered:Connect(function(player)
		if player.UserId ~= class.Owner then return end
		if class.Level == class.MaxLevel then return end

		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not class.isPurchased and class.BaseCost or class.UpgradeCost) then
			Events.FireEvent(Events.RemoteNames.WarningMsg, class.Player, "Not enough gold!")
			class:UpdateProximityPromptUI(proximityPrompt)
			return
		end

		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not class.isPurchased and class.BaseCost or class.UpgradeCost)

		if class.isPurchased then
			class:Upgrade()
		else
			class:Purchase()
			class:Show()
			class:CanCollide()

			if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then class:StartFishing() end
		end

		-- Update UIs
		class:UpdateProximityPromptUI(proximityPrompt)
		class:UpdatePurchaseBoardUI()

		class:Save()
	end))

	return proximityPrompt
end

function PP.UpdatePP(proximityPrompt: ProximityPrompt, class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	if class.Level == class.MaxLevel then
		proximityPrompt.ObjectText = "Cannot Upgrade"
		proximityPrompt.ActionText = "Max Level Reached"
	else
		proximityPrompt.ObjectText = class.isPurchased and "Upgrade" or "Purchase"
		proximityPrompt.ActionText = class.isPurchased and "Gold: " .. FormatNumber(class.UpgradeCost) or "Gold: " .. FormatNumber(class.BaseCost)
	end
end

return PP
