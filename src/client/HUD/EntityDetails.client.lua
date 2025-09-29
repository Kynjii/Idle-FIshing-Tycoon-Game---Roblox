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

local details = {}
-- Defaults
details.NameLabel = entityDetailsUI:FindFirstChild("EntityName", true) :: TextLabel
details.LevelLabel = entityDetailsUI:FindFirstChild("Level", true) :: TextLabel
details.Description = entityDetailsUI:FindFirstChild("Description", true) :: TextLabel

-- Boat
details.CurrentFPSLabel = entityDetailsUI:FindFirstChild("CurrentFPSLabel", true) :: TextLabel
details.CurrentFPSValue = entityDetailsUI:FindFirstChild("CurrentFPSValue", true) :: TextLabel
details.NextFPSLabel = entityDetailsUI:FindFirstChild("NextFPSLabel", true) :: TextLabel
details.NextFPSValue = entityDetailsUI:FindFirstChild("NextFPSValue", true) :: TextLabel

-- Tender
details.CurrentTravelTimeLabel = entityDetailsUI:FindFirstChild("CurrentTTLabel", true) :: TextLabel
details.CurrentTravelTimeValue = entityDetailsUI:FindFirstChild("CurrentTTValue", true) :: TextLabel
details.NextTravelTimeLabel = entityDetailsUI:FindFirstChild("NextTTLabel", true) :: TextLabel
details.NextTravelTimeValue = entityDetailsUI:FindFirstChild("NextTTValue", true) :: TextLabel
details.CurrentLoadTimeLabel = entityDetailsUI:FindFirstChild("CurrentLTLabel", true) :: TextLabel
details.CurrentLoadTimeValue = entityDetailsUI:FindFirstChild("CurrentLTValue", true) :: TextLabel
details.NextLoadTimeLabel = entityDetailsUI:FindFirstChild("NextLTLabel", true) :: TextLabel
details.NextLoadTimeValue = entityDetailsUI:FindFirstChild("NextLTValue", true) :: TextLabel

-- Non-Building
details.CurrentMaxStorageLabel = entityDetailsUI:FindFirstChild("CurrentMaxStorageLabel", true) :: TextLabel
details.CurrentMaxStorageValue = entityDetailsUI:FindFirstChild("CurrentMaxStorageValue", true) :: TextLabel
details.NextMaxStorageLabel = entityDetailsUI:FindFirstChild("NextMaxStorageLabel", true) :: TextLabel
details.NextMaxStorageValue = entityDetailsUI:FindFirstChild("NextMaxStorageValue", true) :: TextLabel

-- Building
details.CurrentBuffLabel = entityDetailsUI:FindFirstChild("CurrentBuffLabel", true) :: TextLabel
details.CurrentBuffValue = entityDetailsUI:FindFirstChild("CurrentBuffValue", true) :: TextLabel

-- EntityInteractiveFrame
details.EntityInteractiveFrameLabel = entityDetailsUI:FindFirstChild("EntityInteractiveFrame", true) :: TextLabel

-- Buttons
details.upgradeButton = entityDetailsUI:FindFirstChild("UpgradeButton", true) :: ImageButton

-- Open/Close EntityDetails
-- Default close
entityDetailsUI.Visible = false
local detailsAreOpen = false

local entityData: BoatType.BoatProps | TenderType.TenderProps | PortStorageType.StorageProps | BuildingType.BuildingProps | nil = nil

local entityDetails = Events.GetRemote(Events.RemoteNames.OpenEntityDetails)
if entityDetails then entityDetails.OnClientEvent:Connect(function(data)
	if data then
		player.PlayerGui.EntityDetails.Enabled = true
		entityDetailsUI.Visible = true
		entityData = data
		detailsAreOpen = true
		watchEntity()
		populateDetailsUI()
		handleClosingEntityDetailsUI()
	end
end) end

function watchEntity()
	local indexKey = entityData.Entity .. "s"
	Replica.OnNew("PlayerState", function(replicaData)
		-- General State
		replicaData:OnSet({ "Realms", replicaData.Data.CurrentRealm, indexKey, entityData.Id }, function(newState)
			entityData = newState
			updateName()
			updateLevel()
			updateStats()
			updateEntityInteractiveFrameLabel()
		end)

		-- Upgrade Button
		replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
			currentState.Currencies["Gold"] = newValue
			updateButtonState()
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
			entityData = nil
			local blur: BlurEffect = Lighting.Blur
			if blur then blur:Destroy() end
			break
		end

		task.wait(0.5)
	end
end

function populateDetailsUI()
	if not entityData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	-- Hide all elements by default
	for k, element in pairs(details) do
		element.Visible = false
	end

	updateName()
	updateLevel()
	writeDescription()
	updateEntityInteractiveFrameLabel()
	updateButtonState()
	updateStats()
end

function updateLevel()
	details.LevelLabel.Text = entityData.isPurchased and "Lvl: " .. entityData.Level or ""
	details.LevelLabel.Visible = true
end
function updateName()
	details.NameLabel.Text = entityData.Name or entityData.Entity
	local qualityInfo = FFGEnum.QUALITY[entityData.UpgradeStage]
	if qualityInfo then
		local color = qualityInfo.Color
		details.NameLabel.TextColor3 = color
	end

	if not details.NameLabel.Visible then details.NameLabel.Visible = true end
end
function writeDescription()
	details.Description.Text = entityData.Description or ""
	details.Description.Visible = true
end
function updateStats()
	-- Boat
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		details.CurrentFPSValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentFPS) or ""
		details.NextFPSValue.Text = entityData.isPurchased and "+" .. FormatNumber(entityData.NextFPS - entityData.CurrentFPS) or ""
		details.NextFPSValue.TextColor3 = Theme.color.green

		details.CurrentFPSValue.Visible = entityData.isPurchased and true
		details.NextFPSValue.Visible = entityData.isPurchased and true
		details.CurrentFPSLabel.Visible = entityData.isPurchased and true
		details.NextFPSLabel.Visible = entityData.isPurchased and true
	end

	-- Tender
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		details.CurrentTravelTimeValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentTravelTime) .. " secs" or ""
		details.CurrentLoadTimeValue.Text = entityData.isPurchased and FormatNumber(entityData.LoadTime) .. " secs" or ""

		details.CurrentTravelTimeValue.Visible = true
		details.CurrentLoadTimeValue.Visible = true
	end

	-- Non-Building
	if entityData.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		-- STORAGE Stats
		details.CurrentMaxStorageValue.Text = entityData.isPurchased and FormatNumber(entityData.CurrentMaxStorage) or ""
		details.NextMaxStorageValue.Text = entityData.isPurchased and "+" .. FormatNumber(entityData.NextLvlMaxStorage - entityData.CurrentMaxStorage) or ""
		details.NextMaxStorageValue.TextColor3 = Theme.color.green

		details.CurrentMaxStorageLabel.Visible = entityData.isPurchased and true
		details.NextMaxStorageLabel.Visible = entityData.isPurchased and true
		details.CurrentMaxStorageValue.Visible = entityData.isPurchased and true
		details.NextMaxStorageValue.Visible = entityData.isPurchased and true
	end

	-- Building
	if entityData.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		if entityData.isPurchased and entityData.BuildingBuff then
			local isPlus = entityData.BuildingBuff.IsPlus
			if isPlus then
				details.CurrentBuffValue.Text = "+" .. (FormatNumber(entityData.BuildingBuff.CurrentValue * 100)) .. "%" .. " " .. entityData.BuildingBuff.Label
			else
				details.CurrentBuffValue.Text = "-" .. FormatNumber(entityData.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. entityData.BuildingBuff.Label
			end

			details.CurrentBuffValue.TextColor3 = Theme.color.green
			details.CurrentBuffValue.Visible = true
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
		details.upgradeButton.ImageColor3 = Theme.color.slateBlue
		details.upgradeButton.HoverImage = ""
		details.upgradeButton.PressedImage = ""
		details.upgradeButton.Interactable = false
	end

	details.upgradeButton.TextLabel.Text = entityData.isPurchased and "Upgrade" or "Purchase"
end

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
end

Replica.OnNew("PlayerState", function(replicaData)
	currentState = replicaData.Data

	replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
		currentState.Currencies.Gold = newValue
	end)
end)
