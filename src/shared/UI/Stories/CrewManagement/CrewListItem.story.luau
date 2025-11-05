--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvailableHelperListItem = require(ReplicatedStorage.Shared.UI.Components.Jobs.AvailableHelperListItem)

local function story(target)
	local panel = AvailableHelperListItem.Create({ Id = "testid", Name = "Transporter", QualityId = 1 })
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.BackgroundColor3 = Color3.fromRGB(58, 56, 211)
	frame.Parent = target

	panel.Parent = frame

	return function()
		panel:Destroy()
	end
end

return story
