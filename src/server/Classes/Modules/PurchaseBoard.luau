local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProgressBar = require(ServerScriptService.Server.Modules.Tweens.ProgressBar)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Theme = require(ReplicatedStorage.Shared.Theme.Theme)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local PB = {}

function PB.CreatePB(pbModel: Model, class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	local purchaseBoard = pbModel

	local pbDetails = {}

	-- Default
	pbDetails.NameLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "HeaderContainer", "Name") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "InfoContainer", "Level") :: TextLabel
	pbDetails.EntityLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "InfoContainer", "EntityName") :: TextLabel
	pbDetails.QualityLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "InfoContainer", "Quality") :: TextLabel
	pbDetails.ProgressBar = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "ProgressContainer", "ProgressBG", "ProgressBar") :: ImageLabel
	pbDetails.StorageLabel = DeepWait(purchaseBoard, "Paper", "SurfaceGui", "ProgressContainer", "ProgressBG", "StorageText") :: TextLabel

	-- Add relevant data to texts
	if pbDetails then
		-- Name
		pbDetails.NameLabel.Text = class:GetName()

		-- Quality
		local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
		local color = qualityInfo.Color
		local quality = qualityInfo.Label
		pbDetails.QualityLabel.Text = quality
		pbDetails.QualityLabel.TextColor3 = color

		-- Entity Name
		pbDetails.EntityLabel.Text = class.Entity
		pbDetails.EntityLabel.TextColor3 = Theme.textColor[class.Entity]

		-- Handle State based on isPurchased
		local progressContainer: Frame = pbDetails.ProgressBar:FindFirstAncestor("ProgressContainer")
		if not class.isPurchased then
			pbDetails.LevelLabel.Visible = false
			pbDetails.QualityLabel.Visible = false
			progressContainer.Visible = false
		else
			progressContainer.Visible = true
			pbDetails.LevelLabel.Visible = true
			pbDetails.QualityLabel.Visible = true
			pbDetails.LevelLabel.Text = class.isPurchased and "Level: " .. class.Level
		end

		-- Progress Bar
		if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
			pbDetails.StorageLabel.Text = FormatNumber(class.FishInStorage) .. "/" .. FormatNumber(class.CurrentMaxStorage)
			ProgressBar.Update(pbDetails.ProgressBar, class.FishInStorage, class.CurrentMaxStorage)
		else
			if progressContainer then progressContainer.Visible = false end
		end
	end
	return purchaseBoard, pbDetails
end

function PB.UpdatePB(class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	-- Name
	class.PBDetails.NameLabel.Text = class:GetName()

	-- Quality
	local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
	local color = qualityInfo.Color
	local quality = qualityInfo.Label
	class.PBDetails.QualityLabel.Text = quality
	class.PBDetails.QualityLabel.TextColor3 = color

	-- Entity Name
	class.PBDetails.EntityLabel.Text = class.Entity
	class.PBDetails.EntityLabel.TextColor3 = Theme.textColor[class.Entity]

	-- Handle State based on isPurchased
	local progressContainer: Frame = class.PBDetails.ProgressBar:FindFirstAncestor("ProgressContainer")
	if not class.isPurchased then
		class.PBDetails.LevelLabel.Visible = false
		class.PBDetails.QualityLabel.Visible = false
		progressContainer.Visible = false
	else
		progressContainer.Visible = true
		class.PBDetails.LevelLabel.Visible = true
		class.PBDetails.QualityLabel.Visible = true
		class.PBDetails.LevelLabel.Text = class.isPurchased and "Level: " .. class.Level
	end

	-- Progress Bar
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		class.PBDetails.StorageLabel.Text = FormatNumber(class.FishInStorage) .. "/" .. FormatNumber(class.CurrentMaxStorage)
		ProgressBar.Update(class.PBDetails.ProgressBar, class.FishInStorage, class.CurrentMaxStorage)
	else
		if progressContainer then progressContainer.Visible = false end
	end
end

return PB
