local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local satchel = require(ReplicatedStorage.Packages.Satchel)
local Events = require(ReplicatedStorage.Shared.Events.Events)

satchel:SetBackpackEnabled(false)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local satchelGui = playerGui:WaitForChild("BackpackGui")
if satchelGui then
    local backpackFrame = satchelGui.Backpack :: Frame | nil
    if backpackFrame then
        backpackFrame.Size = UDim2.fromScale(1, 0.95)
    end
end

local playerAssignedEvent = Events.GetRemote(Events.RemoteNames.PlayerAssigned)
if playerAssignedEvent then
    playerAssignedEvent.OnClientEvent:Connect(function(...)
        satchel:SetBackpackEnabled(true)
    end)
end
