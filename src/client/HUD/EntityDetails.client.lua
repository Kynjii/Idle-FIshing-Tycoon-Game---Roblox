local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicaData = require(StarterPlayer.StarterPlayerScripts.Client.Modules.ReplicaData)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local entityDetailsUI: Frame = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer")

local currentState = {}

-- Get PlayerState Updates
ReplicaData.StateChanged:Connect(function(playerData)
	if playerData then
		currentState = playerData
		populateDetailsUI()
	end
end)

local details = {}
-- Defaults
details.NameLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "Name") :: TextLabel
details.LevelLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "Level") :: TextLabel
details.Description = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "Description") :: TextLabel

-- Boat
details.CurrentFPSLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "CurrentFPS") :: TextLabel
details.NextFPSLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "NextFPS") :: TextLabel

-- Tender
details.CurrentTravelTimeLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "CurrentTT") :: TextLabel
details.CurrentLoadTimeLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "CurrentLT") :: TextLabel

-- Non-Building
details.StorageProgress = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame
details.CurrentMaxStorageLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "CurrentMaxStorage") :: TextLabel
details.NextMaxStorageLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "NextMaxStorage") :: TextLabel

-- Building
details.BuffLabel = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "Buff") :: TextLabel

-- Buttons
details.upgradeButton = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "UpgradeButton") :: ImageButton

-- Open/Close EntityDetails
-- Default close
entityDetailsUI.Visible = false

local entityData = nil

local entityDetails = Events.GetRemote(Events.RemoteNames.OpenEntityDetails)
if entityDetails then entityDetails.OnClientEvent:Connect(function(data)
	if data then
		entityDetailsUI.Visible = true
		entityData = data
		populateDetailsUI()
		handleClosingEntityDetailsUI()
	end
end) end

function handleClosingEntityDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			entityDetailsUI.Visible = false
			break
		end

		task.wait(0.5)
	end
end

-- //TODO - Handle button state based on if the player can afford the upgrade/purchase

-- Populate the Details Page
function populateDetailsUI()
	if not entityData then return end
	local class: BoatType.BoatProps | TenderType.TenderProps | PortStorageType.StorageProps | BuildingType.BuildingProps = entityData

	-- Hide all elements by defaults except for progress bars
	for k, element in pairs(details) do
		if k ~= "ProgressBar" then element.Visible = false end
	end

	-- Name
	local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
	local color = qualityInfo.Color
	details.NameLabel.TextColor3 = color
	details.NameLabel.TextXAlignment = "Center"
	details.NameLabel.Text = class.Name
	details.NameLabel.Visible = true

	-- Level
	details.LevelLabel.Text = class.isPurchased and "Lvl: " .. class.Level or ""
	details.LevelLabel.Visible = true

	-- Description
	details.Description.Text = class.Description or ""
	details.Description.Visible = true

	-- Upgrade Button
	details.upgradeButton.TextLabel.Text = class.isPurchased and "Upgrade" or "Purchase"
	details.upgradeButton.Visible = true
	if currentState.Currencies and currentState.Currencies.Gold then
		local cost = class.isPurchased and class.UpgradeCost or class.BaseCost
		if currentState.Currencies.Gold < cost then
			details.upgradeButton.Active = false
			details.upgradeButton.ImageColor3 = Color3.fromHex("#3f3f3f")
		else
			details.upgradeButton.Active = true
			details.upgradeButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	-- Boat
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		details.CurrentFPSLabel.Text = class.isPurchased and "FPS: " .. FormatNumber(class.CurrentFPS) or ""
		details.NextFPSLabel.Text = class.isPurchased and "Next Lvl FPS: " .. FormatNumber(class.NextFPS) or ""

		details.CurrentFPSLabel.Visible = true
		details.NextFPSLabel.Visible = true
	end

	-- Tender
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		details.CurrentTravelTimeLabel.Text = class.isPurchased and "Travel Time: " .. FormatNumber(class.CurrentTravelTime) .. " secs" or ""
		details.CurrentLoadTimeLabel.Text = class.isPurchased and "Load Time: " .. FormatNumber(class.LoadTime) .. " secs" or ""

		details.CurrentTravelTimeLabel.Visible = true
		details.CurrentLoadTimeLabel.Visible = true
	end

	-- Non-Building
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		-- Progress Bar
		local storageProgress = CalculateProgress(class.FishInStorage, class.CurrentMaxStorage)
		details.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
		details.StorageProgress.Visible = class.isPurchased and true or false

		-- STORAGE Stats
		details.CurrentMaxStorageLabel.Text = class.isPurchased and "Storage: " .. FormatNumber(class.CurrentMaxStorage) or ""
		details.NextMaxStorageLabel.Text = class.isPurchased and "Next Lvl Storage: " .. FormatNumber(class.NextLvlMaxStorage) or ""

		details.CurrentMaxStorageLabel.Visible = true
		details.NextMaxStorageLabel.Visible = true
	end

	-- Building
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		if class.isPurchased and class.BuildingBuff then
			local isPlus = class.BuildingBuff.IsPlus
			if isPlus then
				details.BuffLabel.Text = "+" .. (FormatNumber(class.BuildingBuff.CurrentValue * 100)) .. "%" .. " " .. class.BuildingBuff.Label
			else
				details.BuffLabel.Text = "-" .. FormatNumber(class.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. class.BuildingBuff.Label
			end

			details.BuffLabel.TextColor3 = Color3.fromHex("#55ff00")
			details.BuffLabel.Visible = true
		end
	end
end

-- Upgrade Button
if details.upgradeButton then details.upgradeButton.Activated:Connect(function()
	handleUpgradeClick()
end) end

function handleUpgradeClick()
	if currentState.Currencies and currentState.Currencies.Gold then
		local cost = entityData.isPurchased and entityData.UpgradeCost or entityData.BaseCost
		if currentState.Currencies.Gold < cost then print("Cannot afford") end
	end

	local events = {
		Purchased = Events.GetRemote(Events.RemoteNames.EntityPurchased),
		Upgraded = Events.GetRemote(Events.RemoteNames.EntityUpgraded),
	}

	if not entityData.isPurchased then
		events.Purchased:FireServer(entityData[FFGEnum.CLASS.PROPERTIES.Id])
	else
		events.Upgraded:FireServer(entityData[FFGEnum.CLASS.PROPERTIES.Id])
	end

	-- write another listener for the server and client that handle upgrading
	-- client sends update event
	-- Server listens (teammanager i think) and upgrades correct class as well as setting it to show/upgrade and startFishing
	-- Server sends the latest class data for the UI to update
end
