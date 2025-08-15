local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
local Calculators = require(ServerScriptService.Server.Game.Calculators)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local BoatEnums = FFGEnum.ATTRIBUTES.BOAT

local taggedBoats = CollectionService:GetTagged("Boat")

local BOAT = {}

-- //SECTION - BOAT SETUP (Boat, Purchase Board and Proximity Prompt)
BOAT.SetupTaggedBoats = function(player)
	if player then task.delay(1, function()
		for _, taggedBoat in ipairs(taggedBoats) do
			BOAT.SetupBoat(taggedBoat, player)
		end
	end) end
end

BOAT.SetupBoat = function(boat: Model, player: Player)
	local primaryPart = boat.PrimaryPart

	if not player then
		FFGHelpers.PrintLog("No local player found, unable to setup boat")
		return
	end

	local state = BOAT.GetBoatState(player)

	local attributes = nil
	attributes = state or FFGDefaults.BOAT_STARTING_ATT

	FFGHelpers.PrintLog("Attempting to apply state to boat: ", state)

	for key, value in pairs(attributes) do
		-- if the basecost is the default one, calculate and assign the appropriate baseCost
		if key == BoatEnums.BaseCost and value == FFGDefaults.BOAT_STARTING_ATT[BoatEnums.BaseCost] then
			local baseCost = BOAT.GetBaseCost(attributes[BoatEnums.Level], attributes[BoatEnums.Tier], attributes[BoatEnums.RealmLevel])

			if baseCost then primaryPart:SetAttribute(key, baseCost) end
		end
		primaryPart:SetAttribute(key, value)
	end

	if not primaryPart:GetAttribute(BoatEnums.isPurchased) then
		BOAT.Hide(boat)
		BOAT.CannotCollide(boat)
	else
		BOAT.Show(boat)
		BOAT.CanCollide(boat)
	end

	-- Setup the purchase board info and attribute listeners
	local purchaseBoard = BOAT.SetupPurchaseBoard(boat, primaryPart, state)
	if purchaseBoard then
		BOAT.SetupProximityPrompt(boat, primaryPart, purchaseBoard, state)
		BOAT.SetupAttributeListeners(primaryPart, purchaseBoard)
	end
end

-- STATE MANAGEMENT FOR BOAT - Proximity Prompt currently handles a lot of the management as it triggers all changes to the Boat
BOAT.SetupProximityPrompt = function(boat: Model, primaryPart: Part, purchaseBoard: Part, state: FFGTypes.BoatState)
	local currentState = {}
	if not state then
		for k, v in pairs(primaryPart:GetAttributes()) do
			currentState[k] = v
		end
	else
		currentState = state
	end

	-- Helper function to update cache and attribute together
	local function updateStateAndAttribute(key: string, value: any)
		currentState[key] = value
		primaryPart:SetAttribute(key, value)
	end

	-- Helper function to get fresh value and update cache
	local function getAndCacheAttribute(key: string)
		local value = primaryPart:GetAttribute(key)
		currentState[key] = value
		return value
	end

	-- Create the prompt and apply conditional text
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)
	proximityPrompt.HoldDuration = 1
	proximityPrompt.ObjectText = currentState[BoatEnums.isPurchased] and "Upgrade Boat" or "Purchase" :: string
	proximityPrompt.ActionText = currentState[BoatEnums.isPurchased] and "Level: " .. tostring(currentState.Level + 1) or "Tier " .. currentState.Tier .. " Boat" :: string

	proximityPrompt.TriggerEnded:Connect(function(player)
		-- Use cached values but refresh critical ones to be safe
		local isPurchased = getAndCacheAttribute(BoatEnums.isPurchased) :: boolean
		local upgradeCost = isPurchased and getAndCacheAttribute(BoatEnums.UpgradeCost) or getAndCacheAttribute(BoatEnums.BaseCost) :: number

		if not DataManager.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost) then
			FFGHelpers.PrintLog("Unable to afford upgrade, cost is: ", upgradeCost)
			return
		else
			DataManager.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, upgradeCost)
		end

		if isPurchased then
			-- Update level using cache-updating helper
			local currentLevel = currentState.Level
			updateStateAndAttribute(BoatEnums.Level, currentLevel + 1)

			-- if the new level passes the threshold in quality promo, update the UpgradeStage
			for k, v in ipairs(FFGEnum.QUALITY_PROMOTION_LEVELS) do
				if currentState.Level == v + 1 then
					local newStage = k + 1
					BOAT.IncreaseUpgradeStage(player, primaryPart, newStage)
					currentState.UpgradeStage += 1
					break
				end
			end

			BOAT.UpdateLevel(player, primaryPart, currentState)
			local newUpgradeCost = BOAT.GetUpgradeCost(currentState[BoatEnums.Level], currentState[BoatEnums.Tier], currentState[BoatEnums.RealmLevel], currentState[BoatEnums.BaseCost])
			currentState[BoatEnums.UpgradeCost] = newUpgradeCost
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

-- Set's the current state of the Boat on the Purchase Board
BOAT.SetupPurchaseBoard = function(boat: Model, primaryPart: Part, boatState: FFGTypes.BoatState)
	local purchaseBoard = boat:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

	local isPurchased = primaryPart:GetAttribute(BoatEnums.isPurchased)

	if pbDetails then
		local upgradeStage = primaryPart:GetAttribute(BoatEnums.UpgradeStage)
		local level = primaryPart:GetAttribute(BoatEnums.Level)
		local qualityInfo = FFGEnum.QUALITY[upgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not isPurchased then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = FFGEnum.BOAT.NAME[upgradeStage] or BoatEnums.Name
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = isPurchased and "Level: " .. level or "Purchase Boat"

		-- //TODO - use formatting helper
		local storage = {
			current = primaryPart:GetAttribute(BoatEnums.CurrentMaxStorage),
			next = primaryPart:GetAttribute(BoatEnums.NextLvlMaxStorage),
		}
		pbDetails.CurrentMaxStorageLabel.Text = isPurchased and tostring(storage.current) or ""
		pbDetails.NextMaxStorageLabel.Text = isPurchased and tostring(storage.next) or ""
	end

	return purchaseBoard
end

--  //!SECTION

-- //SECTION - UI Updates for Proximity Prompt and Purchase Board
BOAT.UpdateProximityPromptUI = function(proximityPrompt: ProximityPrompt, primaryPart: Part, actText: string, objText: string)
	if proximityPrompt and primaryPart then
		proximityPrompt.ObjectText = actText or "Upgrade"
		proximityPrompt.ActionText = objText or "Null"
	end
end

BOAT.UpdatePurchaseBoardUI = function(primaryPart: Part, purchaseBoard: Part, attributeName: string)
	if not attributeName or not purchaseBoard then
		FFGHelpers.PrintLog("No attributeName or purchaseBoard found")
		return
	end

	local isPurchased = primaryPart:GetAttribute(BoatEnums.isPurchased)

	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

	-- //TODO - use formatting helper
	local storage = {
		current = primaryPart:GetAttribute(BoatEnums.CurrentMaxStorage),
		next = primaryPart:GetAttribute(BoatEnums.NextLvlMaxStorage),
	}
	pbDetails.CurrentMaxStorageLabel.Text = isPurchased and tostring(storage.current) or ""
	pbDetails.NextMaxStorageLabel.Text = isPurchased and tostring(storage.next) or ""

	local level = primaryPart:GetAttribute(BoatEnums.Level)
	pbDetails.LevelLabel.Text = "Level: " .. level

	local currentUpgradeStage = primaryPart:GetAttribute(BoatEnums.UpgradeStage)

	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	pbDetails.NameLabel.TextColor3 = color
	pbDetails.NameLabel.Text = FFGEnum.BOAT.NAME[currentUpgradeStage]

	if attributeName == BoatEnums.isPurchased then pbDetails.NameLabel.Parent.Visible = true end
end
-- //!SECTION

-- //SECTION - Handles Boat calculations
BOAT.GetMaxStorage = function(level: number, tier: number)
	return Calculators.MaxStorage(FFGEnum.ENTITIES.Boat, level, tier)
end

BOAT.GetUpgradeCost = function(level: number, tier: number, realmLevel: number, baseCost: number)
	return Calculators.UpgradeCost(FFGEnum.ENTITIES.Boat, level, tier, realmLevel, baseCost)
end

BOAT.GetFPS = function()
	--
end

BOAT.GetBoosts = function()
	--
end

BOAT.GetBaseCost = function(level: number, tier: number, realmLevel: number)
	return Calculators.GetBaseCost(FFGEnum.ENTITIES.Boat, level, tier, realmLevel)
end

-- //!SECTION

-- //SECTION - ATTRIBUTE LISTENERS
BOAT.SetupAttributeListeners = function(primaryPart: Part, purchaseBoard: Part)
	if not primaryPart and not purchaseBoard then return end

	-- Update Board UI
	primaryPart:GetAttributeChangedSignal(BoatEnums.Level):Connect(function()
		BOAT.UpdatePurchaseBoardUI(primaryPart, purchaseBoard, BoatEnums.Level)
	end)

	primaryPart:GetAttributeChangedSignal(BoatEnums.UpgradeStage):Connect(function()
		BOAT.UpdatePurchaseBoardUI(primaryPart, purchaseBoard, BoatEnums.UpgradeStage)
	end)

	primaryPart:GetAttributeChangedSignal(BoatEnums.isPurchased):Connect(function()
		BOAT.UpdatePurchaseBoardUI(primaryPart, purchaseBoard, BoatEnums.isPurchased)
	end)
end
-- //!SECTION

-- //SECTION - Handles State updates for the boat
BOAT.GetBoatState = function(player: Player)
	return DataManager.LoadBoatState(player)
end

BOAT.UpdateName = function(player: Player, primaryPart: Part, upgradeStage: number)
	primaryPart:SetAttribute(BoatEnums.Name, FFGEnum.BOAT.NAME[upgradeStage])
	DataManager.UpdateBoatState(player, BoatEnums.Name, FFGEnum.BOAT.NAME[upgradeStage])
end

BOAT.UpdateLevel = function(player: Player, primaryPart: Part, currentState: FFGTypes.BoatState?)
	primaryPart:SetAttribute(BoatEnums.Level, currentState.Level)
	DataManager.UpdateBoatState(player, BoatEnums.Level, currentState.Level)

	-- do and set max storage calcs
	local current, nextValue = BOAT.GetMaxStorage(currentState.Level, currentState.Tier, currentState.RealmLevel)
	if current and nextValue then
		primaryPart:SetAttribute(BoatEnums.CurrentMaxStorage, current)
		DataManager.UpdateBoatState(player, BoatEnums.CurrentMaxStorage, current)

		primaryPart:SetAttribute(BoatEnums.NextLvlMaxStorage, nextValue)
		DataManager.UpdateBoatState(player, BoatEnums.NextLvlMaxStorage, nextValue)
	end

	-- do and set upgrade cost calcs
	local value = BOAT.GetUpgradeCost(currentState.Level, currentState.Tier, currentState.RealmLevel, currentState.BaseCost)
	if value then
		primaryPart:SetAttribute(BoatEnums.UpgradeCost, value)
		DataManager.UpdateBoatState(player, BoatEnums.UpgradeCost, value)
	else
		FFGHelpers.PrintLog("No value found for upgradeCost", value)
	end
end

BOAT.UpdatePurchasedState = function(player: Player, primaryPart: Part, state: BoolValue)
	primaryPart:SetAttribute(BoatEnums.isPurchased, state)
	DataManager.UpdateBoatState(player, BoatEnums.isPurchased, state)
end

BOAT.UpdateActiveState = function(player: Player, primaryPart: Part, state: BoolValue)
	primaryPart:SetAttribute(BoatEnums.isActive, state)
	DataManager.UpdateBoatState(player, BoatEnums.isActive, state)
end

BOAT.AddOwner = function(player: Player, primaryPart: Part)
	primaryPart:SetAttribute(BoatEnums.Owner, player.UserId)
	DataManager.UpdateBoatState(player, BoatEnums.Owner, player.UserId)
end

BOAT.IncreaseUpgradeStage = function(player: Player, primaryPart: Part, newStage: number)
	primaryPart:SetAttribute(BoatEnums.UpgradeStage, newStage)
	DataManager.UpdateBoatState(player, BoatEnums.UpgradeStage, newStage)
end
-- //!SECTION

-- //SECTION - Boat  Utilities
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

BOAT.ResetBoat = function(boat: Model, player: Player)
	local primaryPart = boat.PrimaryPart

	local attributes = FFGDefaults.BOAT_STARTING_ATT

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end

	FFGHelpers.PrintLog("Reset Attributes completed: ", primaryPart:GetAttributes())
end

BOAT.ResetTaggedBoats = function(player)
	if player then
		for _, taggedBoat in ipairs(taggedBoats) do
			BOAT.ResetBoat(taggedBoat, player)
		end
	end
end
-- //!SECTION

return BOAT
