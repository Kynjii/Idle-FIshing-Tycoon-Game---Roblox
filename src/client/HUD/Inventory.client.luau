local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local PlayerInventory = require(ReplicatedStorage.Shared.UI.Components.Inventory.PlayerInventory)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local inventoryUI: Instance
local inventoryDetailsUI: Instance
local main: Instance
local inventoryItemsContainer: Instance
local screenGui: ScreenGui

local hudInventoryButton = playerGui:WaitForChild("Inventory"):FindFirstChild("InventoryButton", true) :: ImageButton

task.spawn(function()
	inventoryUI = PlayerInventory.Create({ Name = "Inventory", ScreenGuiName = "PlayerInventory" })
	inventoryUI.Parent = playerGui

	inventoryDetailsUI = inventoryUI:WaitForChild("DetailsContainer", 10) :: Frame

	main = inventoryDetailsUI:WaitForChild("Main", 10) :: Frame
	inventoryItemsContainer = main:WaitForChild("ItemContainer", 10) :: ScrollingFrame

	screenGui = player.PlayerGui.PlayerInventory
end)

function createitemComponent(helper: HelperType.HelperData)
	local preparedStatData: { [number]: { [string]: any } }? = {}

	local index = 1
	for statName, statValue in pairs(helper.Stats) do
		preparedStatData[index] = { Label = statName, Value = statValue }
		index += 1
	end

	return ShopItem({
		ItemImage = helper.ItemImage,
		ItemName = helper.Name,
		ItemId = helper.Id,
		ItemDescription = helper.Description,
		ItemBaseCost = FormatNumber(helper.BaseCost),
		ItemStats = preparedStatData,
		ItemQualityId = helper.QualityId,
		BackgroundColor3 = FFGEnum.QUALITIES[helper.QualityId].Color,
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		HoverEffect = true,
		Visible = true,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		Parent = inventoryItemsContainer,
		ShopInstance = main,
	})
end

local playerInventory: { [string]: any } = {}
local itemComponents = {}

function updateUI()
	if inventoryItemsContainer then
		for k, item in pairs(playerInventory) do
			if itemComponents[item.Id] then return end
			local itemComponent = createitemComponent(item)
			itemComponents[item.Id] = { Component = itemComponent, Item = item }
		end
	end
end

function populateDetailsUI()
	if not playerInventory then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI()
end

local getInventoryFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetInventory)
if hudInventoryButton and getInventoryFn then hudInventoryButton.Activated:Connect(function()
	local data = getInventoryFn:InvokeServer()
	if data then
		playerInventory = data

		populateDetailsUI()
		screenGui.Enabled = true
	end
end) end
