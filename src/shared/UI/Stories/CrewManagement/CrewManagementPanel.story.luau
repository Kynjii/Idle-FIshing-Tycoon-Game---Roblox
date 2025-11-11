--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CrewManagementPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.CrewManagementPanel)

local function story(target)
	local panel = CrewManagementPanel.Create(
		Players.LocalPlayer,
		{
			Id = 1,
			Tier = 1,
			Category = FFGEnum.JOB_CATEGORY.Transporting,
			Label = "Pier 1",
			Slots = {
				MaxSlots = 3,
				LockedSlots = 2,
				AssignedHelpers = {},
			},
		},
		{
			{
				BaseCost = 16000,
				CurrencyType = "Gold",
				CurrentAssignment = 0,
				Description = "A crew member specialized in Transporting Fish from the Port to the Market.",
				Entity = "Helper",
				Id = "50bf32f2-deae-4a0f-9420-9ec0e27a9d99",
				IsPurchased = true,
				ItemImage = "rbxassetid://135331905621652",
				JobCategory = "Transporting",
				Level = 1,
				MaxLevel = 100,
				Name = "Transporter",
				Owner = 8984765705,
				QualityId = 3,
				RealmId = 1,
				ResourceInStorage = 0,
				Stats = {
					FishValue = 0.1,
					LoadTime = 8,
					Storage = 62,
					WalkSpeed = 6,
				},
				StorageFull = true,
				TeamId = 1,
				UpgradeCost = 17280,
				UpgradeStage = 1,
			},
		},
		"Transporting",
		target
	)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 1920, 0, 1080)
	frame.BackgroundColor3 = Color3.fromRGB(58, 56, 211)
	frame.Parent = target

	panel.Parent = frame

	return function()
		panel:Destroy()
	end
end

return story
