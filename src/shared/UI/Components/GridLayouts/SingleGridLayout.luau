local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local SingleGridLayout = {}

function SingleGridLayout.Create(props: {
	Name: string,
	Size: "Full" | "Half" | "TwoThird",
	Parent: Instance,
})
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = props.Name
	scrollingFrame.AnchorPoint = props.Size == "Full" and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.CanvasSize = UDim2.fromScale(0, 10)
	scrollingFrame.Position = props.Size == "Full" and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0, 0.5)
	scrollingFrame.ScrollBarImageColor3 = Color3.new()
	scrollingFrame.ScrollBarThickness = 0
	scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	KinUI.AddStroke(scrollingFrame, "XL", Color3.fromHex("#02447d"))
	KinUI.AddCorner(scrollingFrame, "S")

	local size
	if props.Size == "Full" then
		size = UDim2.fromScale(1, 0.9)
	elseif props.Size == "Half" then
		size = UDim2.fromScale(0.4, 0.9)
	elseif props.Size == "TwoThird" then
		size = UDim2.fromScale(0.6, 0.9)
	end
	scrollingFrame.Size = size
	scrollingFrame.Parent = props.Parent

	local uiGridLayout = Instance.new("UIGridLayout")
	uiGridLayout.Name = "UIGridLayout"
	uiGridLayout.CellSize = UDim2.fromScale(0.2, 0.4)
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
