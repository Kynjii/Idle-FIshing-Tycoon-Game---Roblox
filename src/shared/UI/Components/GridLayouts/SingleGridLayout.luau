local SingleGridLayout = {}

function SingleGridLayout.Create(props: {
	Name: string,
	Parent: Instance,
})
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = props.Name
	scrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.CanvasSize = UDim2.fromScale(0, 4)
	scrollingFrame.Position = UDim2.fromScale(0.5, 0.533006)
	scrollingFrame.ScrollBarImageColor3 = Color3.new()
	scrollingFrame.ScrollBarThickness = 0
	scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollingFrame.Size = UDim2.fromScale(1, 0.933988)
	scrollingFrame.Parent = props.Parent

	local uiGridLayout = Instance.new("UIGridLayout")
	uiGridLayout.Name = "UIGridLayout"
	uiGridLayout.CellSize = UDim2.fromScale(0.15, 0.3)
	uiGridLayout.CellPadding = UDim2.fromScale(0.05, 0.05)
	uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
	uiGridLayout.FillDirectionMaxCells = 5
	uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiGridLayout.Parent = scrollingFrame

	local gridPadding = Instance.new("UIPadding")
	gridPadding.Name = "GridPadding"
	gridPadding.PaddingBottom = UDim.new(0.01, 0)
	gridPadding.PaddingLeft = UDim.new(0.01, 0)
	gridPadding.PaddingRight = UDim.new(0.01, 0)
	gridPadding.PaddingTop = UDim.new(0.01, 0)
	gridPadding.Parent = scrollingFrame

	return scrollingFrame
end

return SingleGridLayout
