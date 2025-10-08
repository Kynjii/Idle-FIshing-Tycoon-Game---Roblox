local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProgressBar = require(ServerScriptService.Server.Modules.Tweens.ProgressBar)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Theme = require(ReplicatedStorage.Shared.Theme.Theme)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

type Boat = BoatType.BoatInstance
type Tender = TenderType.TenderInstance
type PortStorage = PortStorageType.StorageInstance
type Building = BuildingType.BuildingInstance

local PB = {}

function PB.CreatePB(pbModel: Model, class: Boat | Tender | PortStorage | Building)
	local typedClass
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		typedClass = class :: Boat
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		typedClass = class :: Tender
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.PortStorage then
		typedClass = class :: PortStorage
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		typedClass = class :: Building
	else
		error("Invalid entity passed to CreatePB")
	end

	local purchaseBoard = pbModel

	local pbDetails = {}

	-- Default
	pbDetails.NameLabel = purchaseBoard:FindFirstChild("Name", true) :: TextLabel
	pbDetails.LevelLabel = purchaseBoard:FindFirstChild("Level", true) :: TextLabel
	pbDetails.EntityLabel = purchaseBoard:FindFirstChild("EntityName", true) :: TextLabel
	pbDetails.QualityLabel = purchaseBoard:FindFirstChild("Quality", true) :: TextLabel
	pbDetails.ProgressBar = purchaseBoard:FindFirstChild("ProgressBar", true) :: ImageLabel
	pbDetails.StorageLabel = purchaseBoard:FindFirstChild("StorageText", true) :: TextLabel

	-- Add relevant data to texts
	if pbDetails then
		-- Name
		pbDetails.NameLabel.Text = typedClass:GetName()

		-- Quality
		local qualityInfo = FFGEnum.QUALITY[typedClass.UpgradeStage]
		local color = qualityInfo.Color
		local quality = qualityInfo.Label
		pbDetails.QualityLabel.Text = quality
		pbDetails.QualityLabel.TextColor3 = color

		-- Entity Name
		pbDetails.EntityLabel.Text = typedClass.Entity
		pbDetails.EntityLabel.TextColor3 = Theme.textColor[typedClass.Entity]

		-- Handle State based on isPurchased
		local progressContainer: Frame = pbDetails.ProgressBar:FindFirstAncestor("ProgressContainer")
		if not typedClass.isPurchased then
			pbDetails.LevelLabel.Visible = false
			pbDetails.QualityLabel.Visible = false
			progressContainer.Visible = false
		else
			progressContainer.Visible = true
			pbDetails.LevelLabel.Visible = true
			pbDetails.QualityLabel.Visible = true
			pbDetails.LevelLabel.Text = typedClass.isPurchased and `Level: {typedClass.Level}`
		end

		-- Building Buff
		if typedClass.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
			if not typedClass.isPurchased then pbDetails.EntityLabel.Text = typedClass.BuildingBuff.Label end
		end

		-- Progress Bar
		if typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
			pbDetails.StorageLabel.Text = `{FormatNumber(typedClass.FishInStorage)} / {FormatNumber(typedClass.CurrentMaxStorage)}`
			ProgressBar.Update(pbDetails.ProgressBar, typedClass.FishInStorage, typedClass.CurrentMaxStorage)
		else
			if progressContainer then progressContainer.Visible = false end
		end
	end
	return purchaseBoard, pbDetails
end

function PB.UpdatePB(class: Boat | Tender | PortStorage | Building)
	local typedClass
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		typedClass = class :: Boat
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		typedClass = class :: Tender
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.PortStorage then
		typedClass = class :: PortStorage
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		typedClass = class :: Building
	else
		error("Invalid entity passed to CreatePB")
	end

	-- Name
	typedClass.PBDetails.NameLabel.Text = typedClass:GetName()

	-- Quality
	local qualityInfo = FFGEnum.QUALITY[typedClass.UpgradeStage]
	local color = qualityInfo.Color
	local quality = qualityInfo.Label
	typedClass.PBDetails.QualityLabel.Text = quality
	typedClass.PBDetails.QualityLabel.TextColor3 = color

	-- Entity Name
	typedClass.PBDetails.EntityLabel.Text = typedClass.Entity
	typedClass.PBDetails.EntityLabel.TextColor3 = Theme.textColor[typedClass.Entity]

	-- Handle State based on isPurchased
	local progressContainer: Frame = typedClass.PBDetails.ProgressBar:FindFirstAncestor("ProgressContainer")
	if not typedClass.isPurchased then
		typedClass.PBDetails.LevelLabel.Visible = false
		typedClass.PBDetails.QualityLabel.Visible = false
		progressContainer.Visible = false
	else
		progressContainer.Visible = true
		typedClass.PBDetails.LevelLabel.Visible = true
		typedClass.PBDetails.QualityLabel.Visible = true
		typedClass.PBDetails.LevelLabel.Text = typedClass.isPurchased and "Level: " .. typedClass.Level
	end

	-- Progress Bar
	if typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		typedClass.PBDetails.StorageLabel.Text = FormatNumber(typedClass.FishInStorage) .. "/" .. FormatNumber(typedClass.CurrentMaxStorage)
		ProgressBar.Update(typedClass.PBDetails.ProgressBar, typedClass.FishInStorage, typedClass.CurrentMaxStorage)
	else
		if progressContainer then progressContainer.Visible = false end
	end
end

return PB
