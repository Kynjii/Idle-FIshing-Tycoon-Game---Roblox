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
	pbDetails.Description = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "Description", "TextLabel") :: TextLabel

	-- Boat
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		pbDetails.CurrentFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentFPS", "TextLabel") :: TextLabel
		pbDetails.NextFPSLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextFPS", "TextLabel") :: TextLabel
	end

	-- Tender
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then pbDetails.CurrentTravelTimeLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentTravelTime", "TextLabel") :: TextLabel end

	-- Non-Building
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		-- Non-Tender
		if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Tender then pbDetails.StorageProgress = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StorageBar", "StorageProgress") :: Frame end

		pbDetails.CurrentMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "CurrentMaxStorage", "TextLabel") :: TextLabel
		pbDetails.NextMaxStorageLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "NextMaxStorage", "TextLabel") :: TextLabel
	end

	-- Building
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then pbDetails.BuffLabel = DeepWait(purchaseBoard, "SurfaceGui", "Main", "DetailsContainer", "StatsContainer", "Buff", "TextLabel") :: TextLabel end

	-- Add relevant data to texts
	if pbDetails then
		local qualityInfo = FFGEnum.QUALITY[class.UpgradeStage]
		local color = qualityInfo.Color
		pbDetails.NameLabel.TextColor3 = color
		pbDetails.NameLabel.TextXAlignment = "Center"
		pbDetails.NameLabel.Text = class:GetName()

		local levelLabelParent: Frame = pbDetails.LevelLabel.Parent
		if not class.IsPurchased then
			levelLabelParent.Visible = false
		else
			levelLabelParent.Visible = true
			pbDetails.LevelLabel.Text = class.IsPurchased and "Lvl: " .. class.Level
		end

		pbDetails.Description.Text = class.Description or ""
		pbDetails.Description.TextScaled = true

		-- Non-Building
		if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
			-- Non-Tender
			if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Tender then
				local storageProgress = CalculateProgress(class.FishInStorage, class.CurrentMaxStorage)
				pbDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
			end

			-- STORAGE Stats
			local currentStorage, nextStorage = class:CalculateMaxStorage()
			pbDetails.CurrentMaxStorageLabel.Text = class.IsPurchased and "Storage: " .. FormatNumber(currentStorage) or ""
			pbDetails.NextMaxStorageLabel.Text = class.IsPurchased and "Next Lvl Storage: " .. FormatNumber(nextStorage) or ""
		end

		if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
			-- FPS Stats
			pbDetails.CurrentFPSLabel.Text = class.IsPurchased and "FPS: " .. FormatNumber(class.CurrentFPS) or ""
			pbDetails.NextFPSLabel.Text = class.IsPurchased and "Next Lvl FPS: " .. FormatNumber(class.NextFPS) or ""
		elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
			-- TRAVEL TIME Stats
			pbDetails.CurrentTravelTimeLabel.Text = class.isPurchased and "Travel Time: " .. class.CurrentTravelTime .. "secs" or ""
		elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
			if class.isPurchased and class.BuildingBuff then
				local isPlus = class.BuildingBuff.IsPlus
				if isPlus then
					pbDetails.BuffLabel.Text = "+" .. (class.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. class.BuildingBuff.Label
				else
					pbDetails.BuffLabel.Text = "-" .. (class.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. class.BuildingBuff.Label
				end

				pbDetails.BuffLabel.TextColor3 = Color3.fromHex("#55ff00")
			end
		end
	end
	return purchaseBoard, pbDetails
end

function PB.UpdatePB(class: BoatType.BoatInstance | TenderType.TenderInstance | PortStorageType.StorageInstance)
	--  Default
	if class.isPurchased then class.PBDetails.LevelLabel.Text = "Lvl: " .. class.Level end

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
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then class.PBDetails.CurrentTravelTimeLabel.Text = class.isPurchased and "Travel Time: " .. class.CurrentTravelTime .. "secs" or "" end

	-- Non-Building
	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		class.PBDetails.CurrentMaxStorageLabel.Text = class.isPurchased and "Storage: " .. FormatNumber(class.CurrentMaxStorage) or ""
		class.PBDetails.NextMaxStorageLabel.Text = class.isPurchased and "Next Lvl Storage: " .. FormatNumber(class.NextLvlMaxStorage) or ""
	end

	-- Building
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		if class.isPurchased and class.BuildingBuff then
			local isPlus = class.BuildingBuff.IsPlus
			if isPlus then
				class.PBDetails.BuffLabel.Text = "+" .. (class.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. class.BuildingBuff.Label
			else
				class.PBDetails.BuffLabel.Text = "-" .. (class.BuildingBuff.CurrentValue * 100) .. "%" .. " " .. class.BuildingBuff.Label
			end

			class.PBDetails.BuffLabel.TextColor3 = Color3.fromHex("#55ff00")
		end
	end

	local updateProgressBar = class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat or class.Entity == FFGEnum.CLASS.ENTITY_NAME.PortStorage
	if updateProgressBar then
		local storageProgress = CalculateProgress(class.FishInStorage, class.CurrentMaxStorage)
		class.PBDetails.StorageProgress.Size = UDim2.fromScale(1, storageProgress)
	end

	if class.isPurchased then class.PBDetails.NameLabel.Parent.Visible = true end
end

return PB
