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
	if main then inventoryItemsContainer = main:FindFirstChild("ItemContainer", true) :: ScrollingFrame end
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
		ItemUpgradeCost = helper.UpgradeCost,
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

function updateUI(keepTooltip: boolean)
	if not keepTooltip then clearExistingTooltip() end

	for _, component: Instance in pairs(itemComponents) do
		component:Destroy()
	end

	itemComponents = {}

	if inventoryItemsContainer then
		for k, item in pairs(playerInventory) do
			local itemComponent = createitemComponent(item)
			itemComponents[item.Id] = itemComponent
		end
	end
end

function populateDetailsUI(keepTooltip: boolean?)
	if not playerInventory then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI(keepTooltip)
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

local freshHelperData = Events.GetRemote(Events.RemoteNames.HelperData)
if freshHelperData then
	freshHelperData.OnClientEvent:Connect(function(helperData: HelperType.HelperData)
		if playerInventory[helperData.Id] then playerInventory[helperData.Id] = helperData end

		local keepTooltip = true
		populateDetailsUI(keepTooltip)
	end)
end
