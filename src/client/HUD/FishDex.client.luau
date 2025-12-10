local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local satchel = require(ReplicatedStorage.Packages.Satchel)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishDexItem = require(ReplicatedStorage.Shared.UI.Components.FishDex.FishDexItem)
local FishDexUI = require(ReplicatedStorage.Shared.UI.Components.FishDex.FishDexUI)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local main: Instance
local fishDexItemsContainer: Instance
local screenGui: ScreenGui
local fishDexButtonScreenGui = playerGui:WaitForChild("FishDexButton")
local hudFishDexButton = fishDexButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton

task.spawn(function()
    screenGui = FishDexUI.Create(player.UserId)
    screenGui.Parent = playerGui

    main = screenGui:FindFirstChild("Main", true) :: Frame
    if main then
        fishDexItemsContainer = main:FindFirstChild("ItemContainer", true) :: ScrollingFrame
    end
end)

function createitemComponent(fish)
    return FishDexItem({
        ItemData = fish,
        Size = UDim2.fromScale(1, 1),
        Visible = true,
        Parent = fishDexItemsContainer,
    })
end

local playerFishDex: { [string]: any } = {}
local itemComponents = {}

function updateUI()
    KinUI.ScrollTo({ instance = fishDexItemsContainer })
    for _, component: Instance in pairs(itemComponents) do
        component:Destroy()
    end

    itemComponents = {}

    if fishDexItemsContainer then
        for k, item in pairs(playerFishDex) do
            local itemComponent = createitemComponent(item)
            if item.Species == "Angelfish" then
                if item.Variant == "Normal" then
                    local btn = itemComponent:FindFirstChildOfClass("ImageButton")
                    if btn then
                        btn.Selected = true
                        Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, { Item = item, isFishDex = true })
                    end
                end
            end
            itemComponents[`{item.SpeciesKey}_{item.Variant}`] = itemComponent
        end
    end
end

function populateDetailsUI()
    if not playerFishDex then
        return
    end
    local blur = Instance.new("BlurEffect")
    blur.Parent = Lighting

    updateUI()
end

local playerAssignedEvent = Events.GetRemote(Events.RemoteNames.PlayerAssigned)
if playerAssignedEvent then
    playerAssignedEvent.OnClientEvent:Once(function()
        if fishDexButtonScreenGui and not fishDexButtonScreenGui.Enabled then
            fishDexButtonScreenGui.Enabled = true
        end
    end)
end

local getFishDexFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishDex)
hudFishDexButton.Activated:Connect(function()
    if screenGui.Enabled then
        satchel:SetBackpackEnabled(true)
        screenGui.Enabled = false
        if Lighting then
            local blur = Lighting:FindFirstChild("Blur")
            if blur then
                blur:Destroy()
            end
        end
        return
    end

    local data = getFishDexFn:InvokeServer()
    if data then
        playerFishDex = data

        populateDetailsUI()
        satchel:SetBackpackEnabled(false)
        screenGui.Enabled = true
    end
end)
