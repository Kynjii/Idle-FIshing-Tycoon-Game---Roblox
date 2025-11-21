local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local SkillUpNotification = require(ReplicatedStorage.Shared.UI.Components.HUD.SkillUpNotification)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("SkillMessages")
local notificationContainer = screenGui:WaitForChild("MessageContainer")

if notificationContainer then
	local skillMessageEvent = Events.GetRemote(Events.RemoteNames.SkillMessage)
	if skillMessageEvent then
		skillMessageEvent.OnClientEvent:Connect(function(data)
			if data then
				local message = SkillUpNotification.Create(data.Text, data.Skill)
				if message then
					message.Parent = notificationContainer
					SkillUpNotification.Animate(message)
				end
			end
		end)
	end
end
