local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillUpNotification = require(ReplicatedStorage.Shared.UI.Components.HUD.SkillUpNotification)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local function story(target)
	local item = SkillUpNotification.Create("+50 xp", "Fishing")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	KinUI.AddStroke(frame, "L")
	frame.Parent = target

	item.Parent = frame

	return function()
		item:Destroy()
	end
end

return story
