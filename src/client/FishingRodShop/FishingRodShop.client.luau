local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local satchel = require(ReplicatedStorage.Packages.Satchel)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local RodType = require(ReplicatedStorage.Shared.Types.RodType)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local main: Instance
local shopItemsContainer: ScrollingFrame
local screenGui: ScreenGui

task.spawn(function()
    screenGui = ShopGUI.Create({
        screenGuiName = "FishingRodShop",
        panelName = "Fishing Rod Shop",
    }, player.UserId)
    screenGui.Parent = playerGui

    main = screenGui:FindFirstChild("Main", true) :: Frame
    if main then
        shopItemsContainer = main:FindFirstChild("ItemContainer", true) :: ScrollingFrame
    end
end)

function createShopitemComponent(rod: RodType.FishingRodType)
    return ShopItem({
        ItemData = rod,
        BackgroundColor3 = FFGEnum.QUALITIES[rod.QualityId].Color,
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

local shopData: { [number]: RodType.FishingRodType } = {}
local itemComponents = {}

function handleClosingShopDetailsUI()
    local character = player.Character and player.Character.PrimaryPart
    local originalPosition = character and character.CFrame.Position
    if not originalPosition then
        return
    end

    while true do
        local distance = player:DistanceFromCharacter(originalPosition)
        if distance >= 8 then
            satchel:SetBackpackEnabled(true)
            ShopGUI.CloseShop(screenGui)
            break
        end

        task.wait(0.5)
    end
end

function updateUI()
    KinUI.ScrollTo({ instance = shopItemsContainer })
    for _, component in pairs(itemComponents) do
        local itemComponent = component :: Instance
        itemComponent:Destroy()
    end

    itemComponents = {}

    if shopItemsContainer then
        local isFirst = true
        for i, rod in ipairs(shopData) do
            local item = rod.Value
            local itemComponent = createShopitemComponent(item)
            itemComponent.LayoutOrder = item.LevelRequirement

            itemComponents[i] = itemComponent

            if i == 1 and isFirst then
                local btn = itemComponent:FindFirstChildOfClass("ImageButton")
                if btn then
                    btn.Selected = true
                    Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, { Item = item })
                end
                isFirst = false
            end
        end
    end
end

function populateDetailsUI()
    if not shopData then
        return
    end
    local blur = Instance.new("BlurEffect")
    blur.Parent = Lighting

    updateUI()
end

function prepareData(data)
    local list = {}
    for key, rod in pairs(data) do
        table.insert(list, { Key = key, Value = rod })
    end

    table.sort(list, function(a, b)
        return a.Value.Id < b.Value.Id
    end)

    return list
end

local openUIEvent = Events.GetRemote(Events.RemoteNames.OpenFishingRodShop)
if openUIEvent then
    openUIEvent.OnClientEvent:Connect(function(data)
        if data then
            shopData = prepareData(data)

            populateDetailsUI()
            satchel:SetBackpackEnabled(false)
            screenGui.Enabled = true
            task.spawn(function()
                handleClosingShopDetailsUI()
            end)
        end
    end)
end

local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateFishingRodShopUI)
if updateUIEvent then
    updateUIEvent.OnClientEvent:Connect(function(newShopData)
        if not newShopData then
            return
        end

        shopData = prepareData(newShopData)

        updateUI()
    end)
end
