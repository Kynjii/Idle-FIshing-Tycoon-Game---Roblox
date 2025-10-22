local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local helperShopUI
local shopDetailsUI
local main
local shopItemsContainer
task.spawn(function()
	helperShopUI = ShopGUI.Create({ ShopName = "Crew Shop", ScreenGuiName = "HelperShop" })
	helperShopUI.Parent = playerGui

	shopDetailsUI = helperShopUI:WaitForChild("DetailsContainer", 10) :: Frame
	shopDetailsUI.Visible = false

	main = shopDetailsUI:WaitForChild("Main", 10) :: Frame
	shopItemsContainer = main:WaitForChild("ShopItemsContainer", 10) :: ScrollingFrame
end)

local playerTutorialItems = {}
local itemElements = {}

function handlePurchaseClick(itemId: string)
	local shopItemPurchased = Events.GetRemote(Events.RemoteNames.ShopItemPurchased)
	if shopItemPurchased then shopItemPurchased:FireServer(itemId) end
end

function createShopItemElement(helper: HelperType.HelperData)
	return ShopItem({
		ItemImage = helper.ItemImage,
		ItemName = helper.Name,
		ItemId = helper.Id,
		ItemDescription = "Wee wooo",
		ItemPrice = FormatNumber(helper.Stats and helper.Stats.BaseCost),
		BackgroundColor3 = FFGEnum.THEME.shop.shopItem.bgColor,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		Rounded = FFGEnum.THEME.button.cornerRadius,
		HoverEffect = true,
		Visible = true,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		Parent = shopItemsContainer,
		ShopInstance = main,
	})
end

local _replica = nil
local shopData: any = {}

function watchplayerTutorialItems()
	Replica.OnNew("PlayerState", function(replicaData)
		_replica = replicaData:OnSet({ "TutorialHelpers" }, function(newState)
			playerTutorialItems = newState
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
			local tooltip = main:FindFirstChild("ShopTooltip", true)
			if tooltip then tooltip:Destroy() end
			ShopGUI.CloseShop(shopDetailsUI)
			break
		end

		task.wait(0.5)
	end
end

function updateUI()
	for _, element: Frame in pairs(itemElements) do
		local associatedItem = TableUtil.Find(playerTutorialItems, function(item)
			return item.Id == element.Name
		end) :: Instance

		if associatedItem then associatedItem:Destroy() end
	end
end

function populateDetailsUI()
	if not shopData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI()
end

local shopDetails = Events.GetRemote(Events.RemoteNames.OpenHelperShop)
if shopDetails then shopDetails.OnClientEvent:Connect(function(data)
	if data then
		shopDetailsUI.Visible = true
		shopData = data
		watchplayerTutorialItems()
		populateDetailsUI()
		task.spawn(function()
			handleClosingShopDetailsUI()
		end)
	end
end) end

local playerTutorialItemstateEvent = Events.GetRemote(Events.RemoteNames.PrepareHelperShop)
if playerTutorialItemstateEvent then playerTutorialItemstateEvent.OnClientEvent:Connect(function(data)
	if not data then return end

	playerTutorialItems = data

	if shopItemsContainer then
		for i, item in ipairs(playerTutorialItems) do
			local itemElement = createShopItemElement(item)
			itemElements[i] = itemElement
		end
	end
end) end
