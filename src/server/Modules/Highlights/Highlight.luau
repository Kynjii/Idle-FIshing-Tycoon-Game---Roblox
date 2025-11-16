local Highlight = {}

function Highlight.Add(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "Highlight"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.new()
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.new()

	highlight.Parent = model
	highlight.Adornee = model
end

function Highlight.Destroy(model: Model)
	local highlight = model:FindFirstChild("Highlight")

	if highlight then highlight:Destroy() end
end

return Highlight
