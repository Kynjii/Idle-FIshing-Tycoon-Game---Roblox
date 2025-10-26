local HttpService = game:GetService("HttpService")
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

local helperShopUI: Instance
local shopDetailsUI: Instance
local main: Instance
local shopItemsContainer: Instance
local screenGui: ScreenGui

task.spawn(function()
	helperShopUI = ShopGUI.Create({ Name = "Crew Shop", ScreenGuiName = "HelperShop" })
	helperShopUI.Parent = playerGui

	shopDetailsUI = helperShopUI:WaitForChild("DetailsContainer", 10) :: Frame

	main = shopDetailsUI:WaitForChild("Main", 10) :: Frame
	shopItemsContainer = main:WaitForChild("ItemContainer", 10) :: ScrollingFrame

	screenGui = player.PlayerGui.HelperShop
end)

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

function createShopitemComponent(helper: HelperType.HelperData)
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
		Parent = shopItemsContainer,
		ShopInstance = main,
		Owner = helper.Owner,
	})
end

local _replica = nil
local shopData: { [string]: any } = {}
local itemComponents = {}

function handleClosingShopDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			clearExistingTooltip()
			ShopGUI.CloseShop(screenGui)
			break
		end

		task.wait(0.5)
	end
end

function updateUI()
	clearExistingTooltip()

	for _, component: Instance in pairs(itemComponents) do
		component:Destroy()
	end

	if shopItemsContainer then
		for k, item in pairs(shopData) do
			if item.IsPurchased then
				return
			else
				local itemComponent = createShopitemComponent(item)
				itemComponents[item.Id] = itemComponent
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
if shopDetails then shopDetails.OnClientEvent:Connect(function(data)
	if data then
		local decodedData = HttpService:JSONDecode(data)
		shopData = decodedData

		populateDetailsUI()
		screenGui.Enabled = true
		task.spawn(function()
			handleClosingShopDetailsUI()
		end)
	end
end) end

local prepareShopEvent = Events.GetRemote(Events.RemoteNames.PrepareHelperShop)
if prepareShopEvent then prepareShopEvent.OnClientEvent:Connect(function(data)
	if not data then return end
	local decodedData = HttpService:JSONDecode(data)
	shopData = decodedData
	updateUI()
end) end

local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateUI)
if updateUIEvent then updateUIEvent.OnClientEvent:Connect(function()
	updateUI()
end) end
