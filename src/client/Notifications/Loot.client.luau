local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = require(ReplicatedStorage.Shared.Events.Events)
local LootNotification = require(ReplicatedStorage.Shared.UI.Components.HUD.LootNotification)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("LootNotifications")
local notificationContainer = screenGui:WaitForChild("LootNotificationContainer")

if notificationContainer then
	local lootNotificationEvent = Events.GetRemote(Events.RemoteNames.LootNotification)
	if lootNotificationEvent then
		lootNotificationEvent.OnClientEvent:Connect(function(data: LootNotification.Props)
			if data then
				local notification = LootNotification.Create({ ItemType = data.ItemType or nil, Text = data.Text or nil })
				if notification then
					notification.Parent = notificationContainer
					LootNotification.Animate(notification)
				end
			end
		end)
	end
end
