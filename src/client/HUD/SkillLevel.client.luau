local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("PlayerSkills")
local skillBarContainer = screenGui:WaitForChild("SkillBarContainer")
KinUI.ApplyList(skillBarContainer, Enum.FillDirection.Horizontal, { VFlex = Enum.UIFlexAlignment.SpaceEvenly })

local currentLevel
local nextLevel
local fishingXPFrame
local fishingXPProgressBar

local function updateXP(skill: "Fishing", newLevel, newXpAmount, totalForNextLevel, totalForCurrentLevel)
	if not currentLevel and not nextLevel then
		currentLevel = KinUI.AddTextLabel(skillBarContainer, UDim2.fromScale(0.1, 1), newLevel, "M")
		currentLevel.LayoutOrder = 1
		nextLevel = KinUI.AddTextLabel(skillBarContainer, UDim2.fromScale(0.1, 1), newLevel + 1, "M")
		nextLevel.LayoutOrder = 3
	end
	if not fishingXPFrame then
		fishingXPFrame, fishingXPProgressBar = ProgressBar.Create({ Color = "Green", Parent = skillBarContainer })
		fishingXPFrame.Size = UDim2.fromScale(0.8, 1)
		fishingXPFrame.LayoutOrder = 2
	end

	if fishingXPProgressBar and totalForNextLevel and totalForCurrentLevel then
		-- Calculate progress within current level
		local currentLevelProgress = newXpAmount - totalForCurrentLevel
		local xpNeededForThisLevel = totalForNextLevel - totalForCurrentLevel
		ProgressBar.Update(fishingXPProgressBar, currentLevelProgress, xpNeededForThisLevel)
	end

	if currentLevel and newLevel then
		currentLevel.Text = newLevel
		nextLevel.Text = newLevel + 1
	end
end

local playerAssignedEvent = Events.GetRemote(Events.RemoteNames.PlayerAssigned)
if playerAssignedEvent then playerAssignedEvent.OnClientEvent:Once(function()
	if screenGui and not screenGui.Enabled then screenGui.Enabled = true end
end) end

Replica.OnNew("PlayerState", function(replicaData)
	-- Set intial snapshot
	local fishingLevel = replicaData.Data.Skills.Fishing.FishingLevel
	local xpAmount = replicaData.Data.Skills.Fishing.FishingXP
	local totalForCurrentLevel = replicaData.Data.Skills.Fishing.TotalForCurrentLevel
	updateXP("Fishing", fishingLevel, xpAmount, nil, totalForCurrentLevel)

	-- Currencies
	replicaData:OnSet({ "Skills", "Fishing" }, function(newValue)
		local newLevel = newValue.FishingLevel
		local newXpAmount = newValue.FishingXP
		local totalForNextLevel = newValue.TotalForNextLevel
		local totalForCurrentLevel = newValue.TotalForCurrentLevel
		updateXP("Fishing", newLevel, newXpAmount, totalForNextLevel, totalForCurrentLevel)
	end)
end)

Replica.RequestData()
