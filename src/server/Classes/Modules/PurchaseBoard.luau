local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)

local PB = {}

function PB.CreatePB(pbModel: Model, class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	local purchaseBoard = pbModel

	local pbDetails = {}

	-- Default
	pbDetails.NameLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "Name") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "Level") :: TextLabel

	-- Add relevant data to texts
	if pbDetails then
		local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color
		pbDetails.NameLabel.TextXAlignment = "Center"
		pbDetails.NameLabel.Text = class:GetName()

		if not class.isPurchased then
			pbDetails.LevelLabel.Visible = false
		else
			pbDetails.LevelLabel.Visible = true
			pbDetails.LevelLabel.Text = class.isPurchased and "Level: " .. class.Level
		end
	end
	return purchaseBoard, pbDetails
end

function PB.UpdatePB(class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	--  Default
	if class.isPurchased then
		class.PBDetails.LevelLabel.Visible = true
		class.PBDetails.LevelLabel.Text = "Level: " .. class.Level
	end

	local currentUpgradeStage = class.UpgradeStage
	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	class.PBDetails.NameLabel.TextColor3 = color
	class.PBDetails.NameLabel.Text = class:GetName()
end

return PB
