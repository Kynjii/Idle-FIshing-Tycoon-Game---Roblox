local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishDexUI = require(ReplicatedStorage.Shared.UI.Components.FishDex.FishDexUI)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local function story(target)
	local instance = FishDexUI.Create()
	local uiFrame = instance:FindFirstChild("PanelContainer")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	KinUI.AddStroke(frame, "L")
	frame.Parent = target

	uiFrame.Parent = frame

	local innerWindow = uiFrame:FindFirstChild("InnerWindow", true)
	FishDexUI.RenderInfoPanel(innerWindow, {})

	return function()
		instance:Destroy()
	end
end

return story
