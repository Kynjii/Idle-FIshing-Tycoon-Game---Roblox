--!strict
local AvailableJobListItem = require("../Jobs/AvailableJobListItem")
local CrewManagementPanel = {}

function CrewManagementPanel.Create(props: {
	Slots: {
		MaxSlots: number,
		LockedSlots: number,
		AssignedHelpers: {
			[number]: { Name: string, Level: number, QualityId: number },
		},
	},
	JobId: number,
	Player: Player,
})
	local crewManagementContainer = Instance.new("Frame")
	crewManagementContainer.Name = "CrewManagementContainer"
	crewManagementContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	crewManagementContainer.BackgroundTransparency = 1
	crewManagementContainer.Position = UDim2.fromScale(0.5, 0.5)
	crewManagementContainer.Size = UDim2.fromScale(1, 1)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = crewManagementContainer

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

	local uIGridLayout = Instance.new("UIGridLayout")
	uIGridLayout.Name = "UIGridLayout"
	uIGridLayout.CellSize = UDim2.fromScale(0.9, 0.3)
	uIGridLayout.FillDirectionMaxCells = 50
	uIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout.Parent = availableJobs

	availableJobs.Parent = crewManagementContainer

	local availableJob = AvailableJobListItem.Create(props)
	availableJob.Parent = availableJobs

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

	local uIGridLayout7 = Instance.new("UIGridLayout")
	uIGridLayout7.Name = "UIGridLayout"
	uIGridLayout7.CellSize = UDim2.fromScale(0.95, 0.3)
	uIGridLayout7.FillDirection = Enum.FillDirection.Vertical
	uIGridLayout7.FillDirectionMaxCells = 50
	uIGridLayout7.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIGridLayout7.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout7.Parent = availableCrew

	local uIPadding7 = Instance.new("UIPadding")
	uIPadding7.Name = "UIPadding"
	uIPadding7.PaddingTop = UDim.new(0.03, 0)
	uIPadding7.Parent = availableCrew

	-- component goes here
	local frame18 = Instance.new("Frame")
	frame18.Name = "Frame"
	frame18.AnchorPoint = Vector2.new(0.5, 0.5)
	frame18.BackgroundColor3 = Color3.new(1, 1, 1)
	frame18.BorderColor3 = Color3.new()
	frame18.BorderSizePixel = 0
	frame18.Position = UDim2.fromScale(0.5, 0.5)
	frame18.Size = UDim2.fromScale(1, 1)
	frame18.Parent = availableCrew

	availableCrew.Parent = crewManagementContainer

	return crewManagementContainer
end

return CrewManagementPanel
