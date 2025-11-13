local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local PriceBillboard = {}

function PriceBillboard.Create(props: {
	IsPurchased: boolean,
	BaseCost: number?,
	UpgradeCost: number?,
	Parent: Instance,
})
	local priceBillboard = Instance.new("BillboardGui")
	priceBillboard.Name = "PriceBillboard"
	priceBillboard.AlwaysOnTop = true
	priceBillboard.Enabled = true
	priceBillboard.MaxDistance = FFGEnum.THEME.Nameplate.MaxDistance
	priceBillboard.ResetOnSpawn = false
	priceBillboard.Adornee = props.Parent
	priceBillboard.ExtentsOffsetWorldSpace = Vector3.new(70, 0, 0)
	priceBillboard.Size = UDim2.fromScale(8, 2)
	priceBillboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	priceBillboard.Parent = props.Parent

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	container.Position = FFGEnum.THEME.alignment.position.center
	container.Parent = priceBillboard
	KinUI.ApplyList(container, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center })

	local jobInfoIcon = Instance.new("ImageLabel")
	jobInfoIcon.Name = "JobInfoIcon"
	jobInfoIcon.Size = UDim2.fromScale(0.5, 1)
	jobInfoIcon.Image = FFGEnum.UI.Icons.Gold
	jobInfoIcon.LayoutOrder = 1
	jobInfoIcon.BackgroundTransparency = 1
	jobInfoIcon.Parent = container
	KinUI.ApplyAspect(jobInfoIcon)

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.fromScale(0.5, 1)
	priceLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	priceLabel.Position = FFGEnum.THEME.alignment.position.center
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = FFGEnum.THEME.bigFont
	priceLabel.LayoutOrder = 2
	local cost = not props.IsPurchased and props.BaseCost or props.UpgradeCost
	priceLabel.Text = Format.CurrencyNumber(cost) or ""
	priceLabel.TextColor3 = FFGEnum.THEME.color.textGold
	priceLabel.TextStrokeTransparency = 0.7
	priceLabel.TextScaled = true
	KinUI.AddPadding(priceLabel, "L")
	priceLabel.Parent = container

	local priceStroke = Instance.new("UIStroke")
	priceStroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	priceStroke.Thickness = 0.1
	priceStroke.Parent = priceLabel

	return priceBillboard
end

return PriceBillboard
