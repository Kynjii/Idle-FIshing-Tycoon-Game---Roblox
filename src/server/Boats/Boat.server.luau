local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)

local taggedBoats = CollectionService:GetTagged("Boat")

local BOAT = {}

BOAT.SetupProximityPrompt = function(boat: Model, primaryPart: Part, purchaseBoard: Part)
	-- Create the prompt and apply conditional text
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)
	proximityPrompt.HoldDuration = 1
	proximityPrompt.ObjectText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) and "Upgrade Boat" or "Purchase"
	proximityPrompt.ActionText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) and "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1) or "Boat"

	proximityPrompt.TriggerEnded:Connect(function(player)
		-- //TODO - replace amount with the upgrade cost
		if not DataManager.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, 200) then return end

		if primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) then
			-- update level
			local newValue = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level, newValue)
			DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Level, newValue)

			BOAT.UpdateNameState(player, primaryPart)

			-- if the new level matches the threshold in quality promo, update the UpgradeStage
			for k, v in ipairs(FFGEnum.QUALITY_PROMOTION_LEVELS) do
				if newValue == v + 1 then
					-- update boat name and upgrade stage
					local newStage = tonumber(k) + 1
					primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage, newStage)
					DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.UpgradeStage, newStage)

					primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[newStage])
					DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[newStage])
					break
				end
			end
		else
			BOAT.UpdateNameState(player, primaryPart)
			BOAT.UpdatePurchasedState(player, primaryPart)
			-- update isActive (begins fishing)
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isActive, true)
			DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.isActive, true)
			-- update owner //TODO - need to figure out how to handle this later
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Owner)
			DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Owner)

			proximityPrompt.ObjectText = "Upgrade"
			proximityPrompt.ActionText = "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1)

			local boatParts = boat:GetChildren()
			for _, part in pairs(boatParts) do
				if part.Transparency and part.Transparency == 1 then part.Transparency = 0 end
			end
		end
	end)

	return proximityPrompt
end

BOAT.UpdateProximityPromptUI = function(proximityPrompt: ProximityPrompt, primaryPart: Part)
	if proximityPrompt then proximityPrompt.ActionText = "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1) end
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

BOAT.SetupAttributeListeners = function(primaryPart: Part, purchaseBoard: Part, proximityPrompt: ProximityPrompt)
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

	-- Update ProximityPromt UI
	if proximityPrompt then primaryPart:GetAttributeChangedSignal(FFGEnum.ATTRIBUTES.BOAT.Level):Connect(function()
		BOAT.UpdateProximityPromptUI(proximityPrompt, primaryPart)
	end) end
end

BOAT.SetupBoat = function(boat: Model)
	local primaryPart = boat.PrimaryPart

	-- //TODO - get boat state or FFGDefaults.BOAT_STARTING_ATT
	local attributes = FFGDefaults.BOAT_STARTING_ATT

	-- apply attributes to boat Primary Part
	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end

	-- Setup the purchase board info and attribute listeners
	local purchaseBoard = BOAT.SetupUpgradeStore(boat, primaryPart)
	if purchaseBoard then
		local proximityPrompt = BOAT.SetupProximityPrompt(boat, primaryPart, purchaseBoard)
		BOAT.SetupAttributeListeners(primaryPart, purchaseBoard, proximityPrompt)
	end
end

BOAT.UpdateNameState = function(player: Player, primaryPart: Part)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)])
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.Name, FFGEnum.BOAT.NAME[primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.UpgradeStage)])
end

BOAT.UpdatePurchasedState = function(player: Player, primaryPart: Part)
	primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased, true)
	DataManager.UpdateBoatState(player, FFGEnum.ATTRIBUTES.BOAT.isPurchased, true)
end

for _, taggedBoat in ipairs(taggedBoats) do
	BOAT.SetupBoat(taggedBoat)
end

CollectionService:GetInstanceAddedSignal("Boat"):Connect(BOAT.SetupBoat)
