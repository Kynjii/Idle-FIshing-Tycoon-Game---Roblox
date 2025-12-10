local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local satchel = require(ReplicatedStorage.Packages.Satchel)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local main: Instance
local shopItemsContainer: Instance
local screenGui: ScreenGui

task.spawn(function()
    screenGui = ShopGUI.Create({
        screenGuiName = "HelperShop",
        panelName = "Hire Crew Members",
    }, player.UserId)
    screenGui.Parent = playerGui

    main = screenGui:FindFirstChild("Main", true) :: Frame
    if main then
        shopItemsContainer = main:FindFirstChild("ItemContainer", true) :: ScrollingFrame
    end
end)

function createShopitemComponent(helper: HelperType.HelperData)
    return ShopItem({
        ItemData = helper,
        BackgroundColor3 = FFGEnum.QUALITIES[helper.QualityId].Color,
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

local shopData: { [string]: any } = {}
local itemComponents = {}

function handleClosingShopDetailsUI()
    local character = player.Character.PrimaryPart
    local originalPosition = character.CFrame.Position

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
    for _, component: Instance in pairs(itemComponents) do
        component:Destroy()
    end

    itemComponents = {}

    if shopItemsContainer then
        local isFirst = true
        for k, item in pairs(shopData) do
            if item.IsPurchased then
                continue
            else
                local itemComponent = createShopitemComponent(item)
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

local shopDetails = Events.GetRemote(Events.RemoteNames.OpenHelperShop)
if shopDetails then
    shopDetails.OnClientEvent:Connect(function(data)
        if data then
            shopData = data

            populateDetailsUI()
            satchel:SetBackpackEnabled(false)
            screenGui.Enabled = true
            task.spawn(function()
                handleClosingShopDetailsUI()
            end)
        end
    end)
end

local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateHelperShopUI)
if updateUIEvent then
    updateUIEvent.OnClientEvent:Connect(function(helperId)
        if not helperId then
            return
        end
        if shopData[helperId] then
            shopData[helperId] = nil
        end
        updateUI()
    end)
end
