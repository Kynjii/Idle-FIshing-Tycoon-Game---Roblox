-- local Lighting = game:GetService("Lighting")
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local StarterPlayer = game:GetService("StarterPlayer")
-- local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
-- local AnimateButtonHover = require(StarterPlayer.StarterPlayerScripts.Client.HUD.Utils.AnimateButtonHover)
-- local Events = require(ReplicatedStorage.Shared.Events.Events)
-- local ShopItems = require(ReplicatedStorage.Shared.Items.ShopItems)
-- local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
-- local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

-- local player = Players.LocalPlayer
-- task.wait(3)

-- local islandShopUI = player.PlayerGui:WaitForChild("IslandShopGUI") :: ScreenGui
-- local shopDetailsUI = islandShopUI:WaitForChild("DetailsContainer") :: Frame
-- local main = shopDetailsUI:WaitForChild("Main") :: Frame
-- local shopItemsContainer = main:WaitForChild("ShopItemsContainer") :: ScrollingFrame

-- local itemCatalog = ShopItems
-- local playerItems = {}
-- local itemElements = {}

-- function handlePurchaseClick(itemId: string)
-- 	local shopItemPurchased = Events.GetRemote(Events.RemoteNames.ShopItemPurchased)
-- 	if shopItemPurchased then shopItemPurchased:FireServer(itemId) end
-- end

-- function createShopItemElement(item: ShopItems.ShopItem)
-- 	local template = shopItemsContainer:WaitForChild("ShopItemTemplate")

-- 	local clone
-- 	if template then
-- 		clone = template:Clone() :: Frame
-- 		clone.Name = item.id

-- 		local itemNameLabel = clone:FindFirstChild("ItemName", true) :: TextLabel
-- 		if itemNameLabel then itemNameLabel.Text = item.name end

-- 		local buyButton = clone:FindFirstChild("BuyBtn", true) :: ImageButton
-- 		if buyButton then
-- 			local baseSize = buyButton.Size
-- 			buyButton.Activated:Connect(function()
-- 				handlePurchaseClick(item.id)
-- 			end)

-- 			buyButton.MouseEnter:Connect(function()
-- 				AnimateButtonHover.Enter(buyButton, baseSize)
-- 			end)

-- 			buyButton.MouseLeave:Connect(function()
-- 				AnimateButtonHover.Leave(buyButton, baseSize)
-- 			end)

-- 			local buttonText = buyButton:FindFirstChild("ItemCost", true) :: TextLabel
-- 			if buttonText then buttonText.Text = FormatNumber(item.baseCost) end
-- 		end

-- 		local category = shopItemsContainer:FindFirstChild(`Category_{item.jobCategory}`) :: Frame
-- 		local itemParent = category:FindFirstChild("ShopItems") :: Frame

-- 		if itemParent then
-- 			clone.Visible = true
-- 			clone.Parent = itemParent
-- 		else
-- 			return
-- 		end
-- 	end

-- 	return clone
-- end

-- if shopItemsContainer then
-- 	for i, item in ipairs(itemCatalog) do
-- 		local itemElement = createShopItemElement(item)
-- 		itemElements[i] = itemElement
-- 	end
-- end

-- local details = {
-- 	Defaults = {},
-- 	Stats = {},
-- }
-- -- Defaults
-- details.Defaults.Title = main:FindFirstChild("Title", true) :: TextLabel

-- -- Buttons
-- details.closeButton = shopDetailsUI:FindFirstChild("CloseButton", true) :: ImageButton

-- -- Open/Close ShopDetails
-- -- Default close
-- shopDetailsUI.Visible = false

-- local _replica = nil
-- local shopData: any = {}

-- function watchPlayerItems()
-- 	Replica.OnNew("PlayerState", function(replicaData)
-- 		_replica = replicaData:OnSet({ "Realms", replicaData.Data.CurrentRealm, "Items" }, function(newState)
-- 			playerItems = newState
-- 			updateUI()
-- 		end)
-- 	end)
-- end

-- function handleClosingShopDetailsUI()
-- 	local character = player.Character.PrimaryPart
-- 	local originalPosition = character.CFrame.Position

-- 	while true do
-- 		local distance = player:DistanceFromCharacter(originalPosition)
-- 		if distance >= 8 then
-- 			closeDetails()
-- 			break
-- 		end

-- 		task.wait(0.5)
-- 	end
-- end

-- function closeDetails()
-- 	shopDetailsUI.Visible = false
-- 	if Lighting then
-- 		local blur = Lighting:FindFirstChild("Blur")
-- 		if blur then blur:Destroy() end
-- 	end
-- end

-- function handleCloseClick()
-- 	closeDetails()
-- end

-- -- Close Button
-- if details.closeButton then
-- 	local baseSize = details.closeButton.Size
-- 	details.closeButton.Activated:Connect(function()
-- 		handleCloseClick()
-- 	end)

-- 	details.closeButton.MouseEnter:Connect(function()
-- 		AnimateButtonHover.Enter(details.closeButton, baseSize)
-- 	end)

-- 	details.closeButton.MouseLeave:Connect(function()
-- 		AnimateButtonHover.Leave(details.closeButton, baseSize)
-- 	end)
-- end

-- function updateUI()
-- 	for _, element: Frame in pairs(itemElements) do
-- 		local associatedItem = TableUtil.Find(playerItems, function(item)
-- 			return item.id == element.Name
-- 		end)

-- 		if associatedItem then
-- 			local buyButton = element:FindFirstChild("BuyBtn", true) :: ImageButton
-- 			if buyButton then
-- 				buyButton.Active = false
-- 				buyButton.Image = "rbxassetid://87220614829273"
-- 				buyButton.HoverImage = ""
-- 				buyButton.PressedImage = ""
-- 				buyButton.Interactable = false
-- 			end
-- 		end
-- 	end
-- end

-- function populateDetailsUI()
-- 	if not shopData then return end
-- 	local blur = Instance.new("BlurEffect")
-- 	blur.Parent = Lighting

-- 	updateUI()
-- end

-- local shopDetails = Events.GetRemote(Events.RemoteNames.OpenShopDetails)
-- if shopDetails then shopDetails.OnClientEvent:Connect(function(data)
-- 	if data then
-- 		player.PlayerGui.IslandShopGUI.Enabled = true
-- 		shopDetailsUI.Visible = true
-- 		shopData = data
-- 		watchPlayerItems()
-- 		populateDetailsUI()
-- 		handleClosingShopDetailsUI()
-- 	end
-- end) end

-- local playerItemStateEvent = Events.GetRemote(Events.RemoteNames.PrepareShopItems)
-- if playerItemStateEvent then playerItemStateEvent.OnClientEvent:Connect(function(data)
-- 	if not data then return end

-- 	playerItems = data
-- end) end
