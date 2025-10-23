local ExperienceStateRecordingService = game:GetService("ExperienceStateRecordingService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local helperShopUI: Instance
local shopDetailsUI: Instance
local main: Instance
local shopItemsContainer: Instance
local screenGui: ScreenGui

task.spawn(function()
	helperShopUI = ShopGUI.Create({ ShopName = "Crew Shop", ScreenGuiName = "HelperShop" })
	helperShopUI.Parent = playerGui

	shopDetailsUI = helperShopUI:WaitForChild("DetailsContainer", 10) :: Frame

	main = shopDetailsUI:WaitForChild("Main", 10) :: Frame
	shopItemsContainer = main:WaitForChild("ItemContainer", 10) :: ScrollingFrame

	screenGui = player.PlayerGui.HelperShop
end)

function handlePurchaseClick(itemId: string)
	local shopItemPurchased = Events.GetRemote(Events.RemoteNames.ShopItemPurchased)
	if shopItemPurchased then shopItemPurchased:FireServer(itemId) end
end

function createShopitemComponent(helper: HelperType.HelperData)
	return ShopItem({
		ItemImage = helper.ItemImage,
		ItemName = helper.Name,
		ItemId = helper.Id,
		ItemDescription = "Wee wooo",
		ItemPrice = FormatNumber(helper.BaseCost),
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
local shopData: { [string]: any } = {}
local itemComponents = {}

function watchplayerTutorialItems()
	Replica.OnNew("PlayerState", function(replicaData)
		_replica = replicaData:OnSet({ "TutorialHelpers" }, function(newState)
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
			local tooltip = main:FindFirstChild("ShopTooltip", true)
			if tooltip then tooltip:Destroy() end
			ShopGUI.CloseShop(screenGui)
			break
		end

		task.wait(0.5)
	end
end

function updateUI()
	print(shopData.Inventory)
	if shopItemsContainer then
		for k, item in pairs(shopData.Inventory) do
			if item.IsPurchased then
				if itemComponents[item.Id] then
					local itemComponent: Instance = itemComponents[item.Id].Component
					itemComponents[item.Id] = nil
					itemComponent:Destroy()
					return
				end
			else
				if itemComponents[item.Id] then return end
				local itemComponent = createShopitemComponent(item)
				itemComponents[item.Id] = { Component = itemComponent, Item = item }
			end
		end
	end
end

function populateDetailsUI()
	if not shopData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI()
end

local shopDetails = Events.GetRemote(Events.RemoteNames.OpenHelperShop)
if shopDetails then
	shopDetails.OnClientEvent:Connect(function(data)
		if data then
			local decodedData = HttpService:JSONDecode(data)
			shopData = decodedData
			-- watchplayerTutorialItems()
			populateDetailsUI()
			screenGui.Enabled = true
			task.spawn(function()
				handleClosingShopDetailsUI()
			end)
		end
	end)
end

local prepareShopEvent = Events.GetRemote(Events.RemoteNames.PrepareHelperShop)
if prepareShopEvent then prepareShopEvent.OnClientEvent:Connect(function(data)
	if not data then return end
	local decodedData = HttpService:JSONDecode(data)
	shopData = { Inventory = decodedData }

	updateUI()
end) end
