local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)

local taggedBoats = CollectionService:GetTagged("Boat")

local BOAT = {}

BOAT.SetupProximityPrompt = function(boat: Model, primaryPart: Part, purchaseBoard: Part)
	local currentState = {}
	currentState.IsPurchased = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased)
	currentState.Level = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level)
	currentState.Tier = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Tier)
	currentState.isActive = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isActive)
	currentState.UpgradeStage = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)

	-- Create the prompt and apply conditional text
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)
	proximityPrompt.HoldDuration = 1
	proximityPrompt.ObjectText = currentState.IsPurchased and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = currentState.IsPurchased and "Level: " .. tostring(currentState.Level + 1) or "Tier " .. currentState.Tier .. " Boat"

	proximityPrompt.TriggerEnded:Connect(function(player)
		-- //TODO - replace amount with the upgrade cost
		local upgradeCost = 1000
		if not DataManager.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		else
			DataManager.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)
		end

		if currentState.IsPurchased then
			currentState.Level += 1

			-- if the new level passes the threshold in quality promo, update the UpgradeStage
			for k, v in ipairs(FFGEnum.QUALITY_PROMOTION_LEVELS) do
				if currentState.Level == v + 1 then
					local newStage = k + 1
					BOAT.IncreaseUpgradeStage(player, primaryPart, newStage)
					currentState.UpgradeStage += 1
					break
				end
			end

			BOAT.UpdateLevel(player, primaryPart, currentState.Level)
			BOAT.UpdateName(player, primaryPart, currentState.UpgradeStage)
		else
			BOAT.Show(boat)
			BOAT.CanCollide(boat)
			BOAT.UpdateName(player, primaryPart, currentState.UpgradeStage)
			currentState.IsPurchased = true
			BOAT.UpdatePurchasedState(player, primaryPart, currentState.IsPurchased)
			currentState.isActive = true
			BOAT.UpdateActiveState(player, primaryPart, currentState.isActive)

			-- Add owner //TODO - need to figure out how to handle this later for multiple players
			-- perhaps all objects in the place/area are owned by the player assigned to that area/teamcolor
			BOAT.AddOwner(player, primaryPart)

			local actText = "Upgrade"
			local objText = "Level: " .. tostring(currentState.Level + 1)
			BOAT.UpdateProximityPromptUI(proximityPrompt, primaryPart, actText, objText)
		end
	end)

	return proximityPrompt
end

BOAT.UpdateProximityPromptUI = function(proximityPrompt: ProximityPrompt, primaryPart: Part, actText: string, objText: string)
	if proximityPrompt and primaryPart then
		proximityPrompt.ObjectText = actText or "Upgrade"
		proximityPrompt.ActionText = objText or "Null"
	end
end

BOAT.SetupUpgradeStore = function(boat: Model, primaryPart: Part)
	local purchaseBoard = boat:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel")
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel")

	if pbDetails then
		local upgradeStage = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)
		local level = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level)
		local qualityInfo = FFGEnum.QUALITY[upgradeStage]
		local color = qualityInfo.color
		pbDetails.NameLabel.TextColor3 = color

		if not primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = FFGEnum.BOAT.NAME[upgradeStage] or FFGEnum.ATTRIBUTES.BOAT.Name
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) and "Level: " .. level or "Purchase Boat"
	end

	return purchaseBoard
end

BOAT.UpdateBoardUI = function(primaryPart: Part, purchaseBoard: Part, attributeName)
	if not attributeName or not purchaseBoard then
		FFGHelpers.PrintLog("No attributeName or purchaseBoard found")
		return
	end

	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel")
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel")

	local level = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level)
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = FFGEnum.BOAT.NAME[currentUpgradeStage]

	if attributeName == FFGEnum.ATTRIBUTES.BOAT.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end

BOAT.SetupAttributeListeners = function(primaryPart: Part, purchaseBoard: Part)
	if not primaryPart and not purchaseBoard then return end

	-- Update Board UI
	primaryPart:GetAttributeChangedSignal(FFGEnum.ATTRIBUTES.BOAT.Level):Connect(function()
		BOAT.UpdateBoardUI(primaryPart, purchaseBoard, FFGEnum.ATTRIBUTES.BOAT.Level)
	end)

	primaryPart:GetAttributeChangedSignal(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage):Connect(function()
		BOAT.UpdateBoardUI(primaryPart, purchaseBoard, FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)
	end)

	primaryPart:GetAttributeChangedSignal(FFGEnum.ATTRIBUTES.BOAT.isPurchased):Connect(function()
		BOAT.UpdateBoardUI(primaryPart, purchaseBoard, FFGEnum.ATTRIBUTES.BOAT.isPurchased)
	end)
end

BOAT.SetupBoat = function(boat: Model, player: Player)
	local primaryPart = boat.PrimaryPart

	if not player then
		FFGHelpers.PrintLog("No local player found, unable to setup boat")
		return
	end

	local state = BOAT.GetBoatState(player)

	local attributes = nil
	task.delay(1, function()
		attributes = state or FFGDefaults.BOAT_STARTING_ATT

		FFGHelpers.PrintLog("Attempting to apply state to boat: ", state)

		for key, value in pairs(attributes) do
			primaryPart:SetAttribute(key, value)
		end

		if not primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) then
			BOAT.Hide(boat)
			BOAT.CannotCollide(boat)
		else
			BOAT.Show(boat)
			BOAT.CanCollide(boat)
		end

		-- Setup the purchase board info and attribute listeners
		local purchaseBoard = BOAT.SetupUpgradeStore(boat, primaryPart)
		if purchaseBoard then
			BOAT.SetupProximityPrompt(boat, primaryPart, purchaseBoard)
			BOAT.SetupAttributeListeners(primaryPart, purchaseBoard)
		end
	end)
end

BOAT.ResetBoat = function(profile)
	-- // TODO clear up boat data for the next player
end

BOAT.GetBoatState = function(player: Player)
	return DataManager.LoadBoatState(player)
end

BOAT.UpdateName = function(player: Player, primaryPart: Part, upgradeStage: number)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[upgradeStage])
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[upgradeStage])
end

BOAT.UpdateLevel = function(player: Player, primaryPart: Part, newValue: number)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level, newValue)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Level, newValue)
end

BOAT.UpdatePurchasedState = function(player: Player, primaryPart: Part, state: BoolValue)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased, state)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.isPurchased, state)
end

BOAT.UpdateActiveState = function(player: Player, primaryPart: Part, state: BoolValue)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isActive, state)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.isActive, state)
end

BOAT.AddOwner = function(player: Player, primaryPart: Part)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Owner, player.UserId)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Owner, player.UserId)
end

BOAT.IncreaseUpgradeStage = function(player: Player, primaryPart: Part, newStage: number)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage, newStage)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.UpgradeStage, newStage)
end

BOAT.Show = function(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
	end
end

BOAT.CanCollide = function(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if not part.CanCollide then part.CanCollide = true end
	end
end

BOAT.CannotCollide = function(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.CanCollide then part.CanCollide = false end
	end
end

BOAT.Hide = function(boat: Model)
	local boatParts = boat:GetChildren()
	for _, part in pairs(boatParts) do
		if part.Name == "Purchase_Board" then continue end
		if part.Transparency and part.Transparency == 0 then part.Transparency = 1 end
	end
end

BOAT.SetupTaggedBoats = function(player)
	if player then task.delay(1, function()
		for _, taggedBoat in ipairs(taggedBoats) do
			BOAT.SetupBoat(taggedBoat, player)
		end
	end) end
end

BOAT.ResetTaggedBoats = function(profile)
	if profile then
		for _, taggedBoat in ipairs(taggedBoats) do
			BOAT.ResetBoat(taggedBoat, profile)
		end
	end
end

return BOAT
