local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Theme = require(ReplicatedStorage.Shared.Theme.Theme)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)

local player = Players.LocalPlayer
local entityDetailsUI: Frame = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer")

local currentState = {
	Currencies = {
		Gold = 0,
	},
	GlobalBuffs = {},
}

local details = {
	Defaults = {},
	Stats = {},
}
-- Defaults
details.Defaults.NameLabel = entityDetailsUI:FindFirstChild("EntityName", true) :: TextLabel
details.Defaults.LevelLabel = entityDetailsUI:FindFirstChild("Level", true) :: TextLabel
details.Defaults.Description = entityDetailsUI:FindFirstChild("Description", true) :: TextLabel

-- Boat
details.Stats.CurrentFPSLabel = entityDetailsUI:FindFirstChild("CurrentFPSLabel", true) :: TextLabel
details.Stats.CurrentFPSValue = entityDetailsUI:FindFirstChild("CurrentFPSValue", true) :: TextLabel
details.Stats.NextFPSLabel = entityDetailsUI:FindFirstChild("NextFPSLabel", true) :: TextLabel
details.Stats.NextFPSValue = entityDetailsUI:FindFirstChild("NextFPSValue", true) :: TextLabel

-- Tender
details.Stats.CurrentTravelTimeLabel = entityDetailsUI:FindFirstChild("CurrentTTLabel", true) :: TextLabel
details.Stats.CurrentTravelTimeValue = entityDetailsUI:FindFirstChild("CurrentTTValue", true) :: TextLabel
details.Stats.NextTravelTimeLabel = entityDetailsUI:FindFirstChild("NextTTLabel", true) :: TextLabel
details.Stats.NextTravelTimeValue = entityDetailsUI:FindFirstChild("NextTTValue", true) :: TextLabel
details.Stats.CurrentLoadTimeLabel = entityDetailsUI:FindFirstChild("CurrentLTLabel", true) :: TextLabel
details.Stats.CurrentLoadTimeValue = entityDetailsUI:FindFirstChild("CurrentLTValue", true) :: TextLabel
details.Stats.NextLoadTimeLabel = entityDetailsUI:FindFirstChild("NextLTLabel", true) :: TextLabel
details.Stats.NextLoadTimeValue = entityDetailsUI:FindFirstChild("NextLTValue", true) :: TextLabel

-- Non-Building
details.Stats.CurrentMaxStorageLabel = entityDetailsUI:FindFirstChild("CurrentMaxStorageLabel", true) :: TextLabel
details.Stats.CurrentMaxStorageValue = entityDetailsUI:FindFirstChild("CurrentMaxStorageValue", true) :: TextLabel
details.Stats.NextMaxStorageLabel = entityDetailsUI:FindFirstChild("NextMaxStorageLabel", true) :: TextLabel
details.Stats.NextMaxStorageValue = entityDetailsUI:FindFirstChild("NextMaxStorageValue", true) :: TextLabel

-- Building
details.Stats.CurrentBuffLabel = entityDetailsUI:FindFirstChild("CurrentBuffLabel", true) :: TextLabel
details.Stats.CurrentBuffValue = entityDetailsUI:FindFirstChild("CurrentBuffValue", true) :: TextLabel

-- EntityInteractiveFrame
details.EntityInteractiveFrameLabel = entityDetailsUI:FindFirstChild("EntityInteractiveFrame", true) :: TextLabel

-- Buttons
details.upgradeButton = entityDetailsUI:FindFirstChild("UpgradeButton", true) :: ImageButton
details.UpgradeCostLabel = entityDetailsUI:FindFirstChild("UpgradeCostLabel", true) :: TextLabel

-- Open/Close EntityDetails
-- Default close
entityDetailsUI.Visible = false
local detailsAreOpen = false

local _replica = nil
local entityData: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance | BuildingType.BuildingInstance = {}

local entityDetails = Events.GetRemote(Events.RemoteNames.OpenEntityDetails)
if entityDetails then entityDetails.OnClientEvent:Connect(function(data)
	clearExistingData()

	if data then
		player.PlayerGui.EntityDetails.Enabled = true
		entityDetailsUI.Visible = true
		detailsAreOpen = true
		entityData = data
		watchEntity()
		populateDetailsUI()
		handleClosingEntityDetailsUI()
	end
end) end

function watchEntity()
	local indexKey = entityData.Entity .. "s"
	Replica.OnNew("PlayerState", function(replicaData)
		_replica = replicaData:OnSet({ "Realms", replicaData.Data.CurrentRealm, indexKey, entityData.Id }, function(newState)
			entityData = newState
			updateUI()
		end)
	end)
end

function handleClosingEntityDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			entityDetailsUI.Visible = false
			detailsAreOpen = false
			clearExistingData()
			local blur: BlurEffect = Lighting.Blur
			if blur then blur:Destroy() end
			break
		end

		task.wait(0.5)
	end
end

function clearExistingData()
	if _replica then
		_replica:Disconnect()
		_replica = nil
	end
	entityData = nil
end

function populateDetailsUI()
	if not entityData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	writeDescription()
	updateUI()
end

function updateUI()
	updateName()
	updateLevel()
	updateStats()
	updateEntityInteractiveFrameLabel()
	updateButtonState()
end

function updateLevel()
	details.Defaults.LevelLabel.Text = entityData.isPurchased and "Lvl: " .. entityData.Level or ""
	details.Defaults.LevelLabel.Visible = true
end
function updateName()
	details.Defaults.NameLabel.Text = entityData.Name or entityData.Entity
	local qualityInfo = FFGEnum.QUALITY[entityData.UpgradeStage]
	if qualityInfo then
		local color = qualityInfo.Color
		details.Defaults.NameLabel.TextColor3 = color
	end

	if not details.Defaults.NameLabel.Visible then details.Defaults.NameLabel.Visible = true end
end
function writeDescription()
	details.Defaults.Description.Text = entityData.Description or ""
	details.Defaults.Description.Visible = true
end
function updateStats()
	-- Default hide all
	for k, element: TextLabel | ImageButton in pairs(details.Stats) do
		local frameParent = element:FindFirstAncestorWhichIsA("Frame")
		frameParent.Visible = false
	end

	-- Boat
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		details.Stats.CurrentFPSValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentFPS) or ""
		details.Stats.NextFPSValue.Text = entityData.isPurchased and "+" .. FormatNumber(entityData.NextFPS - entityData.CurrentFPS) or ""
		details.Stats.NextFPSValue.TextColor3 = Theme.color.green

		local currentFPSParent = details.Stats.CurrentFPSValue:FindFirstAncestorWhichIsA("Frame")
		currentFPSParent.Visible = entityData.isPurchased and true

		local nextFPSValueParent = details.Stats.NextFPSValue:FindFirstAncestorWhichIsA("Frame")
		nextFPSValueParent.Visible = entityData.isPurchased and true
	end

	-- Tender
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		details.Stats.CurrentTravelTimeValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentTravelTime) .. " secs" or ""
		details.Stats.CurrentLoadTimeValue.Text = entityData.isPurchased and FormatNumber(entityData.LoadTime) .. " secs" or ""

		-- //TODO - Add next times to Tender and reflect here
		local currentTTParent = details.Stats.CurrentTravelTimeValue:FindFirstAncestorWhichIsA("Frame")
		currentTTParent.Visible = entityData.isPurchased and true

		local currentLTParent = details.Stats.CurrentLoadTimeValue:FindFirstAncestorWhichIsA("Frame")
		currentLTParent.Visible = entityData.isPurchased and true
	end

	-- Non-Building
	if entityData.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		-- STORAGE Stats
		details.Stats.CurrentMaxStorageValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentMaxStorage) or ""
		details.Stats.NextMaxStorageValue.Text = entityData.isPurchased and "+" .. FormatNumber(entityData.NextLvlMaxStorage - entityData.CurrentMaxStorage) or ""
		details.Stats.NextMaxStorageValue.TextColor3 = Theme.color.green

		local currentMaxStorageParent = details.Stats.CurrentMaxStorageValue:FindFirstAncestorWhichIsA("Frame")
		currentMaxStorageParent.Visible = entityData.isPurchased and true

		local nextMaxStorageParent = details.Stats.NextMaxStorageValue:FindFirstAncestorWhichIsA("Frame")
		nextMaxStorageParent.Visible = entityData.isPurchased and true
	end

	-- Building
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		if entityData.isPurchased and entityData.BuildingBuff then
			local isPlus = entityData.BuildingBuff.IsPlus
			if isPlus then
				details.Stats.CurrentBuffValue.Text = "+" .. (FormatNumber(entityData.BuildingBuff.CurrentValue * 100)) .. "%" .. " " .. entityData.BuildingBuff.Label
			else
				details.Stats.CurrentBuffValue.Text = "-" .. FormatNumber(entityData.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. entityData.BuildingBuff.Label
			end

			details.Stats.CurrentBuffValue.TextColor3 = Theme.color.green
			details.Stats.CurrentBuffValue.Visible = true
		end
	end
end
function updateEntityInteractiveFrameLabel()
	details.EntityInteractiveFrameLabel.Text = entityData.isPurchased and "Upgrade" or "Purchase"
	details.EntityInteractiveFrameLabel.Visible = true
end

-- Upgrade Button
if details.upgradeButton then details.upgradeButton.Activated:Connect(function()
	handleUpgradeClick()
end) end

function updateButtonState()
	if not detailsAreOpen then return end
	details.upgradeButton.Visible = true

	local currentGoldAmount = currentState.Currencies.Gold or 0
	local cost = entityData.isPurchased and entityData.UpgradeCost or entityData.BaseCost
	local enable = cost <= currentGoldAmount

	if enable then
		details.upgradeButton.Active = true
		details.upgradeButton.ImageColor3 = Theme.color.green
		details.upgradeButton.HoverImage = Theme.button.hoverImage
		details.upgradeButton.PressedImage = Theme.button.pressedImage
		details.upgradeButton.Interactable = true
	else
		details.upgradeButton.Active = false
		details.upgradeButton.ImageColor3 = Theme.color.black
		details.upgradeButton.HoverImage = ""
		details.upgradeButton.PressedImage = ""
		details.upgradeButton.Interactable = false
	end

	details.upgradeButton.TextLabel.Text = entityData.isPurchased and "Upgrade" or "Purchase"
	details.UpgradeCostLabel.Text = FormatNumber(cost)
end

function handleUpgradeClick()
	local events = {
		Purchased = Events.GetRemote(Events.RemoteNames.EntityPurchased),
		Upgraded = Events.GetRemote(Events.RemoteNames.EntityUpgraded),
	}

	if not entityData.isPurchased then
		events.Purchased:FireServer(entityData[FFGEnum.CLASS.PROPERTIES.Id])
	else
		events.Upgraded:FireServer(entityData[FFGEnum.CLASS.PROPERTIES.Id])
	end
end

Replica.OnNew("PlayerState", function(replicaData)
	currentState = replicaData.Data

	replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
		currentState.Currencies.Gold = newValue
	end)
end)
