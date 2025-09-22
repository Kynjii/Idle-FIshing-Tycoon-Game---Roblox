local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local PortStorageType = require(ServerScriptService.Server.Classes.Types.PortStorageType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local CalculateProgress = require(ReplicatedStorage.Shared.Utils.CalculateProgress)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)
local PB = {}

function PB.CreatePB(pbModel: Model, class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	local purchaseBoard = pbModel

	local pbDetails = {}

	-- Default
	pbDetails.NameLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel") :: TextLabel
	pbDetails.LevelLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel") :: TextLabel
	pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
	pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel

	-- Boat
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
		pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel
	end

	-- Tender
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then pbDetails.CurrentTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentTravelTime", "TextLabel") :: TextLabel end

	-- Non-Tender
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Tender then pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame end

	if pbDetails then
		local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color

		if not class.IsPurchased then
			pbDetails.NameLabel.Parent.Visible = false
		else
			pbDetails.NameLabel.Text = class:GetName()
			pbDetails.NameLabel.Parent.Visible = true
		end

		pbDetails.LevelLabel.Text = class.IsPurchased and "Lvl: " .. class.Level or "Purchase " .. class.Entity

		-- STORAGE Stats
		local currentStorage, nextStorage = class:CalculateMaxStorage()
		pbDetails.CurrentMaxStorageLabel.Text = class.IsPurchased and "Storage: " .. FormatNumber(currentStorage) or ""
		pbDetails.NextMaxStorageLabel.Text = class.IsPurchased and "Next Lvl Storage: " .. FormatNumber(nextStorage) or ""

		if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
			-- FPS Stats
			pbDetails.CurrentFPSLabel.Text = class.IsPurchased and "FPS: " .. FormatNumber(class.CurrentFPS) or ""
			pbDetails.NextFPSLabel.Text = class.IsPurchased and "Next Lvl FPS: " .. FormatNumber(class.NextFPS) or ""
		elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
			-- TRAVEL TIME Stats
			pbDetails.CurrentTravelTimeLabel.Text = class.isPurchased and "Travel Time: " .. class.CurrentTravelTime .. "secs" or ""
		end

		if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Tender then
			-- Storage Progress Bar
			local storageProgress = CalculateProgress(class.FishInStorage, class.CurrentMaxStorage)
			pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
		end
	end
	return purchaseBoard, pbDetails
end

function PB.UpdatePB(class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	--  Default
	class.PBDetails.LevelLabel.Text = "Lvl: " .. class.Level
	class.PBDetails.CurrentMaxStorageLabel.Text = class.isPurchased and "Storage: " .. FormatNumber(class.CurrentMaxStorage) or ""
	class.PBDetails.NextMaxStorageLabel.Text = class.isPurchased and "Next Lvl Storage: " .. FormatNumber(class.NextLvlMaxStorage) or ""

	local currentUpgradeStage = class.UpgradeStage
	local qualityInfo = FFGEnum.QUALITY[currentUpgradeStage]
	local color = qualityInfo.Color
	class.PBDetails.NameLabel.TextColor3 = color
	class.PBDetails.NameLabel.Text = class:GetName()

	-- Boat
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		class.PBDetails.CurrentFPSLabel.Text = class.isPurchased and "FPS: " .. FormatNumber(class.CurrentFPS) or ""
		class.PBDetails.NextFPSLabel.Text = class.isPurchased and "Next Lvl FPS: " .. FormatNumber(class.NextFPS) or ""
	end

	-- Tender
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		print(class)
		class.PBDetails.CurrentTravelTimeLabel.Text = class.isPurchased and "Travel Time: " .. class.CurrentTravelTime .. "secs" or ""
	end

	-- Non-Tender
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Tender then
		local storageProgress = CalculateProgress(class.FishInStorage, class.CurrentMaxStorage)
		class.PBDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
	end

	if class.isPurchased then class.PBDetails.NameLabel.Parent.Visible = true end
end

return PB
