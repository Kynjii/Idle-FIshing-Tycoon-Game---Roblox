local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local AvailableHelperListItem = require(ReplicatedStorage.Shared.UI.Components.Jobs.AvailableHelperListItem)
local AvailableJobListItem = require(ReplicatedStorage.Shared.UI.Components.Jobs.AvailableJobListItem)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
local CrewManagementPanel = {}

function CrewManagementPanel.Create(player: Player, jobsData, crewData, jobCategory: "Fishing" | "Woodcutting" | "Mining" | "Transporting")
	local crewManagementContainer = Instance.new("Frame")
	crewManagementContainer.Name = "CrewManagementContainer"
	crewManagementContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	crewManagementContainer.BackgroundTransparency = 1
	crewManagementContainer.Position = UDim2.fromScale(0.5, 0.5)
	crewManagementContainer.Size = UDim2.fromScale(1, 1)
	UIConfig.ApplyList(crewManagementContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })

	local availableJobs = Instance.new("ScrollingFrame")
	availableJobs.Name = "AvailableJobs"
	availableJobs.Active = true
	availableJobs.AnchorPoint = Vector2.new(0.5, 0.5)
	availableJobs.AutomaticCanvasSize = Enum.AutomaticSize.Y
	availableJobs.BackgroundTransparency = 1
	availableJobs.ScrollBarImageColor3 = Color3.new()
	availableJobs.ScrollBarThickness = 0
	availableJobs.ScrollingDirection = Enum.ScrollingDirection.Y
	availableJobs.Size = UDim2.fromScale(0.45, 1)

	local scrollingFramePadding = Instance.new("UIPadding")
	UIConfig.SetPadding(scrollingFramePadding, "M")
	scrollingFramePadding.Parent = availableJobs

	local uIGridLayout = Instance.new("UIGridLayout")
	uIGridLayout.Name = "UIGridLayout"
	uIGridLayout.CellSize = UDim2.fromScale(0.95, 0.3)
	uIGridLayout.FillDirectionMaxCells = 50
	uIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout.Parent = availableJobs

	availableJobs.Parent = crewManagementContainer

	-- Handle Available Jobs
	for id, job in ipairs(jobsData) do
		local jobData = job
		local preparedData = TableUtil.Copy(jobData)
		preparedData.Player = player
		local availableJob = AvailableJobListItem.Create(preparedData)
		availableJob.LayoutOrder = id
		availableJob.Parent = availableJobs
	end

	local availableCrew = Instance.new("ScrollingFrame")
	availableCrew.Name = "AvailableCrew"
	availableCrew.Active = true
	availableCrew.AnchorPoint = Vector2.new(0.5, 0.5)
	availableCrew.AutomaticCanvasSize = Enum.AutomaticSize.Y
	availableCrew.BackgroundTransparency = 1
	availableCrew.ScrollBarImageColor3 = Color3.new()
	availableCrew.ScrollBarThickness = 0
	availableCrew.ScrollingDirection = Enum.ScrollingDirection.Y
	availableCrew.Size = UDim2.fromScale(0.45, 1)

	local availableCrewUIGridLayout = Instance.new("UIGridLayout")
	availableCrewUIGridLayout.Name = "UIGridLayout"
	availableCrewUIGridLayout.CellSize = UDim2.fromScale(0.95, 0.3)
	availableCrewUIGridLayout.FillDirectionMaxCells = 50
	availableCrewUIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	availableCrewUIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	availableCrewUIGridLayout.Parent = availableCrew

	local availableCrewUIUIPadding = Instance.new("UIPadding")
	UIConfig.SetPadding(availableCrewUIUIPadding, "M")
	availableCrewUIUIPadding.Parent = availableCrew

	-- Handle available helpers
	local index = 1
	for _, helper in pairs(crewData) do
		local helperData: HelperType.HelperInstance = helper
		if helperData.CurrentAssignment > 0 then continue end
		if helperData.JobCategory ~= jobCategory then continue end

		local availableHelper = AvailableHelperListItem.Create(helperData)
		availableHelper.LayoutOrder = index
		availableHelper.Parent = availableCrew

		index += 1
	end

	availableCrew.Parent = crewManagementContainer

	return crewManagementContainer
end

return CrewManagementPanel
