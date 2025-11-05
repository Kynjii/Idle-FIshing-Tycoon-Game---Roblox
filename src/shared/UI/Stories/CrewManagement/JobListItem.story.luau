--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvailableJobListItem = require(ReplicatedStorage.Shared.UI.Components.Jobs.AvailableJobListItem)

local function story(target)
	local panel = AvailableJobListItem.Create({ Player = Players.LocalPlayer, Id = 1, Category = "Transporting", Label = "Pier 1", Slots = { MaxSlots = 3, LockedSlots = 1, AssignedHelpers = {} } })
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 720, 0, 540)
	frame.BackgroundColor3 = Color3.fromRGB(58, 56, 211)
	frame.Parent = target

	panel.Parent = frame

	return function()
		panel:Destroy()
	end
end

return story
