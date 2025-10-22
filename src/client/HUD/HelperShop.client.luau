local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local ShopHelpers = require(ReplicatedStorage.Shared.Inventory.ShopHelpers)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local helperShopUI = ShopGUI.Create({ ShopName = "Crew Shop", ScreenGuiName = "HelperShop" })
helperShopUI.Parent = playerGui

local shopDetailsUI = helperShopUI:WaitForChild("DetailsContainer") :: Frame
local main = shopDetailsUI:WaitForChild("Main") :: Frame
local shopItemsContainer = main:WaitForChild("ShopItemsContainer") :: ScrollingFrame

local itemCatalog = ShopHelpers
local playerItems = {}
local itemElements = {}

function handlePurchaseClick(itemId: string)
	local shopItemPurchased = Events.GetRemote(Events.RemoteNames.ShopItemPurchased)
	if shopItemPurchased then shopItemPurchased:FireServer(itemId) end
end

function createShopItemElement(helper: ShopHelpers.Helper)
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

if shopItemsContainer then
	for i, item in ipairs(itemCatalog) do
		local itemElement = createShopItemElement(item)
		itemElements[i] = itemElement
	end
end

-- Open/Close ShopDetails
-- Default close
shopDetailsUI.Visible = false

local _replica = nil
local shopData: any = {}

function watchPlayerItems()
	Replica.OnNew("PlayerState", function(replicaData)
		_replica = replicaData:OnSet({ "Realms", replicaData.Data.CurrentRealm, "Helpers" }, function(newState)
			playerItems = newState
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
			ShopGUI.CloseShop(helperShopUI)
			break
		end

		task.wait(0.5)
	end
end

function updateUI()
	for _, element: Frame in pairs(itemElements) do
		local associatedItem = TableUtil.Find(playerItems, function(item)
			return item.Id == element.Name
		end)

		if associatedItem then
			local buyButton = element:FindFirstChild("BuyBtn", true) :: ImageButton
			if buyButton then
				buyButton.Active = false
				buyButton.Image = "rbxassetid://87220614829273"
				buyButton.HoverImage = ""
				buyButton.PressedImage = ""
				buyButton.Interactable = false
			end
			break
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
if shopDetails then shopDetails.OnClientEvent:Connect(function(data)
	if data then
		player.PlayerGui.HelperShop.Enabled = true
		shopDetailsUI.Visible = true
		shopData = data
		watchPlayerItems()
		populateDetailsUI()
		task.spawn(function()
			handleClosingShopDetailsUI()
		end)
	end
end) end

local playerItemStateEvent = Events.GetRemote(Events.RemoteNames.PrepareHelperShop)
if playerItemStateEvent then playerItemStateEvent.OnClientEvent:Connect(function(data)
	if not data then return end

	playerItems = data
end) end
