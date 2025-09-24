local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = require(ReplicatedStorage.Shared.Events.Events)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)

local player = Players.LocalPlayer
local entityDetailsUI: Frame = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer")
local upgradeButton: ImageButton = DeepWait(player.PlayerGui, "EntityDetails", "DetailsContainer", "UpgradeButton")

-- Open/Close EntityDetails
-- Default close
entityDetailsUI.Visible = false

local entityDetails = Events.GetRemote(Events.RemoteNames.OpenEntityDetails)
if entityDetails then entityDetails.OnClientEvent:Connect(function(data)
	if data then
		entityDetailsUI.Visible = true

		handleClosingEntityDetailsUI()
	end
end) end

function handleClosingEntityDetailsUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			entityDetailsUI.Visible = false
			break
		end

		task.wait(0.5)
	end
end

-- Upgrade Button
if upgradeButton then upgradeButton.Activated:Connect(function()
	handleUpgradeClick()
end) end

function handleUpgradeClick()
	print("click")
end
