--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)

local function story(target)
	local item = ProgressBar.Create({
		Adornee = target,
		Color = "WhiteTrape",
		HasText = true,
	})

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 150, 0, 50)
	frame.Parent = target

	item.Parent = frame

	return function()
		item:Destroy()
	end
end

return story
