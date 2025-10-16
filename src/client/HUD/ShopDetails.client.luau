local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local ShopItems = require(ReplicatedStorage.Shared.Items.ShopItems)
local Theme = require(ReplicatedStorage.Shared.Theme.Theme)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)

local player = Players.LocalPlayer
local islandShopUI = player.PlayerGui:WaitForChild("IslandShopGUI") :: ScreenGui
local shopDetailsUI = islandShopUI:WaitForChild("DetailsContainer") :: Frame

local shopItemsContainer = shopDetailsUI:FindFirstChild("ShopItemsContainer", true)

local itemCatalog = ShopItems
local itemElements = {}

function createShopItemElement(item: ShopItems.ShopItem)
	local template = shopItemsContainer:WaitForChild("ShopItemTemplate")

	local clone
	if template then
		clone = template:Clone() :: Frame

		local itemNameLabel = clone:FindFirstChild("ItemName", true) :: TextLabel
		if itemNameLabel then itemNameLabel.Text = item.name end

		local buttonText = clone:FindFirstChild("ItemCost", true) :: TextLabel
		if buttonText then buttonText.Text = item.baseCost end

		local category = shopItemsContainer:FindFirstChild(`Category_{item.category}`) :: Frame
		local itemParent = category:FindFirstChild("ShopItems") :: ScrollingFrame
		if itemParent then
			clone.Visible = true
			clone.Parent = itemParent
		else
			return
		end
	end

	return clone
end

if shopItemsContainer then
	for i, item in ipairs(itemCatalog) do
		local itemElement = createShopItemElement(item)
		itemElements[i] = itemElement
	end
end

local currentState = {
	Currencies = {
		Gold = 0,
	},
	GlobalBuffs = {},
	Items = {},
}

local details = {
	Defaults = {},
	Stats = {},
}
-- Defaults
details.Defaults.LevelLabel = shopDetailsUI:FindFirstChild("Level", true) :: TextLabel

-- Buttons
details.upgradeButton = shopDetailsUI:FindFirstChild("UpgradeButton", true) :: ImageButton
details.upgradeCostLabel = shopDetailsUI:FindFirstChild("UpgradeCostLabel", true) :: TextLabel
details.closeButton = shopDetailsUI:FindFirstChild("CloseButton", true) :: ImageButton

-- Open/Close ShopDetails
-- Default close
shopDetailsUI.Visible = false
local detailsAreOpen = false

local _replica = nil
local shopData: any = {}

function clearExistingData()
	if _replica then
		_replica:Disconnect()
		_replica = nil
	end
	shopData = nil
end

function watchPlayerItems()
	Replica.OnNew("PlayerState", function(replicaData)
		_replica = replicaData:OnSet({ "Realms", replicaData.Data.CurrentRealm, "Items" }, function(newState)
			shopData = newState
			updateUI()
		end)
	end)
end

function handleClosingShopDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			clearExistingData()
			closeDetails()
			break
		end

		task.wait(0.5)
	end
end

function closeDetails()
	shopDetailsUI.Visible = false
	detailsAreOpen = false
	if Lighting then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then blur:Destroy() end
	end
end

function handlePurchaseClick(itemId: string)
	local shopItemPurchased = Events.GetRemote(Events.RemoteNames.ShopItemPurchased)
	if shopItemPurchased then shopItemPurchased:FireServer(itemId) end
end

-- Buttons
-- Upgrade Button
if details.upgradeButton then
	local baseSize = details.upgradeButton.Size
	details.upgradeButton.Activated:Connect(function()
		handlePurchaseClick("bleh")
	end)

	details.upgradeButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(details.upgradeButton, baseSize)
	end)

	details.upgradeButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(details.upgradeButton, baseSize)
	end)
end

function updateButtonState()
	if not detailsAreOpen then return end
	details.upgradeButton.Visible = true

	local currentGoldAmount = currentState.Currencies.Gold or 0
	local cost = shopData.BaseCost
	local enable = cost <= currentGoldAmount

	if enable then
		details.upgradeButton.Active = true
		details.upgradeButton.ImageColor3 = Theme.color.green
		details.upgradeButton.HoverImage = Theme.button.hoverImage
		details.upgradeButton.PressedImage = Theme.button.pressedImage
		details.upgradeButton.Interactable = true
	else
		details.upgradeButton.Active = false
		details.upgradeButton.ImageColor3 = Theme.color.white
		details.upgradeButton.HoverImage = ""
		details.upgradeButton.PressedImage = ""
		details.upgradeButton.Interactable = false
	end

	details.upgradeCostLabel.Text = FormatNumber(cost)
end

function handleCloseClick()
	clearExistingData()
	closeDetails()
end

-- Close Button
if details.closeButton then
	local baseSize = details.closeButton.Size
	details.closeButton.Activated:Connect(function()
		handleCloseClick()
	end)

	details.closeButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(details.closeButton, baseSize)
	end)

	details.closeButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(details.closeButton, baseSize)
	end)
end

Replica.OnNew("PlayerState", function(replicaData)
	currentState = replicaData.Data

	replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
		currentState.Currencies.Gold = newValue
	end)

	replicaData:OnSet({ "Realms", 1, "Items" }, function(newValue)
		currentState.Items = newValue
	end)
end)

function updateUI()
	--
end

function populateDetailsUI()
	if not shopData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI()
end

local shopDetails = Events.GetRemote(Events.RemoteNames.OpenShopDetails)
if shopDetails then shopDetails.OnClientEvent:Connect(function(data)
	clearExistingData()

	if data then
		player.PlayerGui.IslandShopGUI.Enabled = true
		shopDetailsUI.Visible = true
		detailsAreOpen = true
		shopData = data
		watchPlayerItems()
		populateDetailsUI()
		handleClosingShopDetailsUI()
	end
end) end

local playerItemStateEvent = Events.GetRemote(Events.RemoteNames.PrepareShopItems)
if playerItemStateEvent then
	playerItemStateEvent.OnClientEvent:Connect(function(data)
		-- //TODO - Take the player's item state and update existing ui elements
	end)
end
