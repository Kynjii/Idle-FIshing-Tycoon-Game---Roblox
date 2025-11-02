--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrewManagementPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.CrewManagementPanel)

local function story(target)
	local panel = CrewManagementPanel.Create({
		JobId = 1,
		Slots = {
			MaxSlots = 3,
			LockedSlots = 1,
			AssignedHelpers = {
				[1] = {
					Name = "Transporter",
					Level = 5,
					QualityId = 2,
				},
			},
		},
		Player = Players.LocalPlayer,
	})
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 1920, 0, 1080)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.Parent = target

	panel.Parent = frame

	return function()
		panel:Destroy()
	end
end

return story
