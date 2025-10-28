local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local main: Instance
local inventoryItemsContainer: Instance
local screenGui: ScreenGui
local inventoryButtonScreenGui = playerGui:WaitForChild("InventoryButton")
local hudInventoryButton = inventoryButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton

task.spawn(function()
	screenGui = ShopGUI.Create({ screenGuiName = "PlayerInventory", shopName = "INVENTORY" })
	screenGui.Parent = playerGui

	main = screenGui:FindFirstChild("Main", true) :: Frame
	if main then inventoryItemsContainer = main:WaitForChild("ItemContainer", 10) :: ScrollingFrame end
end)

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

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
		Size = UDim2.fromScale(1, 1),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		HoverEffect = true,
		Visible = true,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(77, 77, 100, 111),
		Parent = inventoryItemsContainer,
		ShopInstance = main,
		Owner = helper.Owner,
		IsPurchased = helper.IsPurchased or false,
	})
end

local playerInventory: { [string]: any } = {}
local itemComponents = {}

function updateUI()
	clearExistingTooltip()

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

local getInventoryFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
hudInventoryButton.Activated:Connect(function()
	if screenGui.Enabled then
		screenGui.Enabled = false
		if Lighting then
			local blur = Lighting:FindFirstChild("Blur")
			if blur then blur:Destroy() end
		end
		return
	end

	local data = getInventoryFn:InvokeServer()
	if data then
		playerInventory = data

		populateDetailsUI()
		screenGui.Enabled = true
	end
end)
