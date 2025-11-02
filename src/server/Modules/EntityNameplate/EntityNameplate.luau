local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
local EntityNameplate = {}

function EntityNameplate.Create(props: {
	Name: string,
	QualityId: number,
	Level: number,
	UpgradeStage: number,
	Adornee: Instance?,
})
	local helperName = Instance.new("BillboardGui")
	helperName.Name = "HelperNameplate"
	helperName.AlwaysOnTop = true
	if props.Adornee then helperName.Adornee = props.Adornee end
	helperName.Enabled = false
	helperName.ExtentsOffsetWorldSpace = Vector3.new(0, 3, 0)
	helperName.LightInfluence = 1
	helperName.MaxDistance = 100
	helperName.ResetOnSpawn = false
	helperName.Size = UDim2.fromOffset(150, 35)
	helperName.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	UIConfig.ApplyList(helperName, Enum.FillDirection.Vertical, { HAlign = Enum.HorizontalAlignment.Center })

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.BackgroundTransparency = 1
	name.Font = FFGEnum.THEME.bigFont
	name.LayoutOrder = 2
	name.Position = UDim2.fromScale(0.5, 0.5)
	name.Size = UDim2.fromScale(1, 0.5)
	name.Text = props.Name or ""
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.7
	UIConfig.ApplyTextConstraints(name, "h1")
	name.Parent = helperName

	local quality = Instance.new("TextLabel")
	quality.Name = "Quality"
	quality.AnchorPoint = Vector2.new(0.5, 0.5)
	quality.BackgroundTransparency = 1
	quality.Font = FFGEnum.THEME.bigFont
	quality.LayoutOrder = 1
	quality.Position = UDim2.fromScale(0.5, 0.5)
	quality.Size = UDim2.fromScale(1, 0.15)
	quality.Text = FFGEnum.QUALITIES[props.QualityId].Label or ""
	quality.TextColor3 = FFGEnum.QUALITIES[props.QualityId].Color or Color3.new(1, 1, 1)
	UIConfig.ApplyTextConstraints(quality, "body")
	quality.Parent = helperName

	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.LayoutOrder = 3
	infoContainer.Position = UDim2.fromScale(0.5, 0.5)
	infoContainer.Size = UDim2.fromScale(0.5, 0.15)
	UIConfig.ApplyList(infoContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center })

	local level = Instance.new("TextLabel")
	level.Name = "Level"
	level.AnchorPoint = Vector2.new(0.5, 0.5)
	level.BackgroundTransparency = 1
	level.Font = FFGEnum.THEME.bigFont
	level.LayoutOrder = 1
	level.Position = UDim2.fromScale(0.5, 0.5)
	level.Size = UDim2.fromScale(0.5, 0.5)
	level.Text = `Level {props.Level}`
	level.TextColor3 = Color3.fromRGB(0, 255, 0)
	level.TextStrokeTransparency = 0.7
	level.TextXAlignment = Enum.TextXAlignment.Left
	UIConfig.ApplyTextConstraints(level, "caption")
	level.Parent = infoContainer

	local stage = Instance.new("TextLabel")
	stage.Name = "Stage"
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.BackgroundTransparency = 1
	stage.Font = FFGEnum.THEME.bigFont
	stage.LayoutOrder = 2
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.RichText = true
	stage.Size = UDim2.fromScale(0.5, 0.5)
	stage.Text = FFGEnum.STAGES[props.UpgradeStage].Label
	stage.TextColor3 = FFGEnum.STAGES[props.UpgradeStage].Color or Color3.new(1, 1, 1)
	stage.TextStrokeTransparency = 0.7
	stage.TextXAlignment = Enum.TextXAlignment.Right
	UIConfig.ApplyTextConstraints(stage, "caption")
	stage.Parent = infoContainer

	infoContainer.Parent = helperName

	return helperName
end

return EntityNameplate
