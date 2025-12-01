local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local satchel = require(ReplicatedStorage.Packages.satchel)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local MarketGUI = require(ReplicatedStorage.Shared.UI.Components.Market.MarketGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local main: Instance
local shopItemsContainer: Instance
local screenGui: ScreenGui
local innerWindow: Frame

task.spawn(function()
	screenGui = MarketGUI.Create()
	screenGui.Parent = playerGui

	main = screenGui:FindFirstChild("Main", true) :: Frame
	innerWindow = screenGui:FindFirstChild("InnerWindow", true) :: Frame
	if main then shopItemsContainer = main:FindFirstChild("ItemContainer", true) :: ScrollingFrame end
end)

function createShopitemComponent(item: FishType.FishData)
	return ShopItem({
		ItemData = item,
		BackgroundColor3 = FFGEnum.QUALITIES[item.QualityId].Color,
		Size = UDim2.fromScale(1, 1),
		Visible = true,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(32, 83, 32, 83),
		Parent = shopItemsContainer,
		ShopInstance = main,
	})
end

local playerInventoryData: { [string]: any } = {}
local itemComponents = {}

function handleClosingShopDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			satchel:SetBackpackEnabled(true)
			MarketGUI.CloseShop(screenGui)
			break
		end

		task.wait(0.5)
	end
end

function updateUI()
	KinUI.ScrollTo({ instance = shopItemsContainer })
	for _, component: Instance in pairs(itemComponents) do
		component:Destroy()
	end

	itemComponents = {}

	if shopItemsContainer then
		local isFirst = true
		local hasItems = false
		for k, item in pairs(playerInventoryData) do
			if item.IsPurchased then
				continue
			else
				local itemComponent = createShopitemComponent(item)
				hasItems = true
				if isFirst then
					local btn = itemComponent:FindFirstChildOfClass("ImageButton")
					if btn then
						btn.Selected = true
						Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, { Item = item })
					end

					isFirst = false
				end
				itemComponents[item.Id] = itemComponent
			end
		end

		if not hasItems then
			local infoPanel = innerWindow and innerWindow:FindFirstChild("InfoPanelContainer")
			if infoPanel then infoPanel:Destroy() end
		end
	end
end

function populateDetailsUI()
	if not playerInventoryData then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateUI()
end

local openMarketUIEvent = Events.GetRemote(Events.RemoteNames.OpenMarketShop)
local playerInventoryFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
if openMarketUIEvent and playerInventoryFn then
	openMarketUIEvent.OnClientEvent:Connect(function()
		local data = playerInventoryFn:InvokeServer()
		if data then
			-- //TODO - Remove hardcoded Fish
			playerInventoryData = data.Fish

			populateDetailsUI()
			satchel:SetBackpackEnabled(false)
			screenGui.Enabled = true
			task.spawn(function()
				handleClosingShopDetailsUI()
			end)
		end
	end)
end

local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateMarketUI)
if updateUIEvent then
	updateUIEvent.OnClientEvent:Connect(function(itemId)
		if not itemId then return end
		if playerInventoryData[itemId] then playerInventoryData[itemId] = nil end
		updateUI()
	end)
end
