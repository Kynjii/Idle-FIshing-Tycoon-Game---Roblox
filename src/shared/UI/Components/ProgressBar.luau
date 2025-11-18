local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local ProgressBar = {}

function ProgressBar.Create(props: {
	Color: "Blue" | "Yellow" | "Green",
	HasText: boolean?,
	HasBillboard: boolean?,
	Adornee: Instance?,
	Parent: Instance?,
})
	local billBoard
	if props.HasBillboard then
		billBoard = Instance.new("BillboardGui")
		billBoard.Name = "ProgressBarContainer"
		billBoard.AlwaysOnTop = true
		if props.Adornee then billBoard.Adornee = props.Adornee end
		billBoard.Enabled = false
		billBoard.ExtentsOffsetWorldSpace = Vector3.new(-40, 0, 0)
		billBoard.LightInfluence = 1
		billBoard.MaxDistance = FFGEnum.THEME.Nameplate.MaxDistance
		billBoard.ResetOnSpawn = false
		billBoard.Size = UDim2.fromScale(10, 1)
		billBoard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end

	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	progressContainer.Position = FFGEnum.THEME.alignment.position.center
	progressContainer.BackgroundTransparency = 1
	progressContainer.ClipsDescendants = true
	progressContainer.LayoutOrder = 3
	progressContainer.Size = UDim2.fromScale(1, 1)

	local progressBG = Instance.new("ImageLabel")
	progressBG.Name = "ProgressBG"
	progressBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	progressBG.BackgroundTransparency = 1
	progressBG.ClipsDescendants = true
	progressBG.Image = FFGEnum.UI.ProgressBar.BackgroundWhite.Asset
	progressBG.ImageColor3 = FFGEnum.UI.ProgressBar.BackgroundColor
	progressBG.Position = FFGEnum.THEME.alignment.position.center
	progressBG.ScaleType = Enum.ScaleType.Slice
	progressBG.Size = UDim2.fromScale(1, 1)
	progressBG.SliceCenter = FFGEnum.UI.ProgressBar.BackgroundWhite.SliceCenter

	local progressBar = Instance.new("ImageLabel")
	progressBar.Name = "ProgressBar"
	progressBar.AnchorPoint = Vector2.new(0, 0.5)
	progressBar.BackgroundTransparency = 1
	progressBar.Image = props.Color and FFGEnum.UI.ProgressBar.InnerBar.White.Asset
	progressBar.ImageColor3 = props.Color and FFGEnum.THEME.color[props.Color]
	progressBar.Position = UDim2.fromScale(0, 0.5)
	progressBar.ScaleType = Enum.ScaleType.Slice
	progressBar.Size = UDim2.fromScale(0, 1)
	progressBar.SliceCenter = FFGEnum.UI.ProgressBar.InnerBar.White.SliceCenter
	progressBar.ZIndex = 2
	progressBar.Parent = progressBG

	if props.HasText then
		local progressBarText = Instance.new("TextLabel")
		progressBarText.Name = "ProgressBarText"
		progressBarText.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		progressBarText.BackgroundTransparency = 1
		progressBarText.Font = FFGEnum.THEME.bigFont
		progressBarText.Position = UDim2.fromScale(0.5, 0.5)
		progressBarText.Size = UDim2.fromScale(1, 0.8)
		progressBarText.Text = "0 / 100"
		progressBarText.TextColor3 = FFGEnum.THEME.color.white
		progressBarText.TextStrokeTransparency = 0.7
		progressBarText.ZIndex = 5
		progressBarText.TextScaled = true
		progressBarText.Parent = progressBG
	end

	progressBG.Parent = progressContainer

	if props.Parent then progressContainer.Parent = props.Parent end

	local container = props.HasBillboard and billBoard or progressContainer
	if props.HasBillboard then progressContainer.Parent = container end
	return container, progressBar
end

function ProgressBar.Show(parent)
	if not parent then return end

	for _, decendant in pairs(parent:GetDescendants()) do
		if decendant.Name == "ProgressContainer" then decendant.Visible = true end
	end
end

function ProgressBar.Hide(parent)
	if not parent then return end

	for _, decendant in pairs(parent:GetDescendants()) do
		if decendant.Name == "ProgressContainer" then decendant.Visible = false end
	end
end

function ProgressBar.Update(progressBarFrame: Frame | ImageLabel, currentValue: number, maxValue: number)
	local max = maxValue or 0
	local current = currentValue or 0
	local progress = (max > 0) and math.clamp(current / max, 0, 1) or 0

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local goal = { Size = UDim2.fromScale(progress, 1) }

	local tween = TweenService:Create(progressBarFrame, tweenInfo, goal)
	tween:Play()
	return tween
end

function ProgressBar.Reset(progressBar: Frame | ImageLabel)
	progressBar.Size = UDim2.fromScale(0, 1)
end

return ProgressBar
