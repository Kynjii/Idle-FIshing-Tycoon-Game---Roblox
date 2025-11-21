local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("PlayerSkills")
local skillBarContainer = screenGui:WaitForChild("SkillBarContainer")
KinUI.ApplyList(skillBarContainer, Enum.FillDirection.Vertical, { VFlex = Enum.UIFlexAlignment.SpaceEvenly })

local fishingXPFrame
local fishingXPProgressBar

local function updateXP(skill: "Fishing", newLevel, newXpAmount, totalForNextLevel)
	if not fishingXPFrame then
		fishingXPFrame, fishingXPProgressBar = ProgressBar.Create({ Color = "Green", Parent = skillBarContainer })
		fishingXPFrame.LayoutOrder = 1
	end

	if fishingXPProgressBar then ProgressBar.Update(fishingXPProgressBar, newXpAmount, totalForNextLevel) end
end

Replica.OnNew("PlayerState", function(replicaData)
	-- Set intial snapshot
	local fishingLevel = replicaData.Data.Skills.Fishing.FishingLevel
	local xpAmount = replicaData.Data.Skills.Fishing.FishingXP
	updateXP("Fishing", fishingLevel, xpAmount)

	-- Currencies
	replicaData:OnSet({ "Skills", "Fishing" }, function(newValue)
		local newLevel = newValue.FishingLevel
		local newXpAmount = newValue.FishingXP
		local totalForNextLevel = newValue.TotalForNextLevel
		updateXP("Fishing", newLevel, newXpAmount, totalForNextLevel)
	end)
end)

Replica.RequestData()
