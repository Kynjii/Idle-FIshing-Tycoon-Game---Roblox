local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EntityNameplate = require(ServerScriptService.Server.Modules.EntityNameplate.EntityNameplate)
local PriceBillboard = require(ServerScriptService.Server.Modules.EntityNameplate.PriceBillboard)
local DataService = require(ServerScriptService.Server.Services.DataService)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
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

	local purchaseButton = pbModel
	local billboardRoot = purchaseButton:FindFirstChild("BillboardRoot") :: Part
	local button: Part = purchaseButton:FindFirstChild("Button")

	local pbDetails = EntityNameplate.Create({
		Name = typedClass.Name,
		Id = typedClass.Id,
		QualityId = typedClass.QualityId or typedClass.Tier,
		UpgradeStage = typedClass.UpgradeStage,
		Adornee = billboardRoot,
		Level = typedClass.Level,
		JobCategory = typedClass.JobCategory or typedClass.Entity or "None",
		MaxStorage = class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building and typedClass.CurrentMaxStorage or nil,
		FPS = class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat and typedClass.CurrentFPS or nil,
	})
	pbDetails.Enabled = true
	pbDetails.Parent = billboardRoot

	PriceBillboard.Create({
		IsPurchased = class.IsPurchased,
		BaseCost = class.BaseCost,
		UpgradeCost = class.UpgradeCost,
		Parent = button,
	})

	local levelLabel = pbDetails:FindFirstChild("Level", true)
	local stageLabel = pbDetails:FindFirstChild("Stage", true)
	local qualityLabel = pbDetails:FindFirstChild("Quality", true)

	if button then
		if not DataService.CanAfford(class.Player, "Gold", not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost) then
			button.Color = FFGEnum.THEME.color.red
		else
			button.Color = FFGEnum.THEME.color.green
		end
	end

	local hasProgressBar = billboardRoot:FindFirstChild("ProgressBarContainer") or billboardRoot:FindFirstChild("ProgressContainer")
	if not hasProgressBar then PB.CreateProgressBar(billboardRoot, typedClass) end

	-- Handle State based on IsPurchased
	local infoContainer = billboardRoot:FindFirstChild("InfoContainer", true)
	local uiList: UIListLayout = infoContainer:FindFirstChildWhichIsA("UIListLayout")
	if not typedClass.IsPurchased then
		uiList.HorizontalFlex = Enum.UIFlexAlignment.None
		levelLabel.Visible = false
		stageLabel.Visible = false
	else
		uiList.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
		levelLabel.Visible = true
		stageLabel.Visible = true
	end

	-- Building Buff
	if typedClass.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		if qualityLabel then qualityLabel.Text = typedClass.BuildingBuff.Label end
	end

	return purchaseButton, pbDetails
end

function PB.CreateProgressBar(parent: Part, class)
	local progressContainer = ProgressBar.Create({ Color = "WhiteShiny", HasText = true, HasBillboard = true, Adornee = parent })
	progressContainer.Parent = parent

	local progressTypeIsFrame = typeof(progressContainer) == "Frame"

	local progressBarText = progressContainer:FindFirstChild("ProgressBarText", true)

	local progressBarFrame = progressContainer:FindFirstChild("ProgressBar", true)

	if not class.IsPurchased then
		if progressTypeIsFrame then
			progressContainer.Visible = false
		else
			progressContainer.Enabled = false
		end
	else
		if progressTypeIsFrame then
			progressContainer.Visible = true
		else
			progressContainer.Enabled = true
		end
	end

	if class.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		if progressBarText then progressBarText.Text = `{FormatNumber(class.FishInStorage)} / {FormatNumber(class.CurrentMaxStorage)}` end
		if progressBarFrame then ProgressBar.Update(progressBarFrame, class.FishInStorage, class.CurrentMaxStorage) end
	else
		if progressContainer then
			if progressTypeIsFrame then
				progressContainer.Visible = false
			else
				progressContainer.Enabled = false
			end
		end
	end
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

	local purchaseButton = class.PurchaseButton
	local billboardRoot = purchaseButton:FindFirstChild("BillboardRoot") :: Part
	local nameplate = billboardRoot:FindFirstChild("EntityNameplate")
	local button: Part = purchaseButton:FindFirstChild("Button")
	local priceBillboard = button:FindFirstChild("PriceBillboard")
	if nameplate then nameplate:Destroy() end
	if priceBillboard then priceBillboard:Destroy() end

	PB.CreatePB(typedClass.PurchaseButton, typedClass)

	local progressBar = purchaseButton:FindFirstChild("ProgressBarContainer") or purchaseButton:FindFirstChild("ProgressContainer")
	if progressBar then PB.UpdateProgress(progressBar, typedClass) end
end

function PB.UpdateProgress(progressBar: Frame, class)
	local progressContainer = progressBar:FindFirstAncestor("ProgressBarContainer")
	local progressBarText = progressContainer:FindFirstChild("ProgressBarText", true)

	local progressBarFrame = progressContainer:FindFirstChild("ProgressBar", true)
	if progressBarText then progressBarText.Text = `{FormatNumber(class.FishInStorage)} / {FormatNumber(class.CurrentMaxStorage)}` end
	if progressBarFrame then ProgressBar.Update(progressBarFrame, class.FishInStorage, class.CurrentMaxStorage) end
end

function PB.Destroy(pbModel: Model)
	local purchaseButton = pbModel
	local billboardRoot = purchaseButton:FindFirstChild("BillboardRoot") :: Part
	local nameplate = billboardRoot:FindFirstChild("HelperNameplate")
	local progressBar = billboardRoot:FindFirstChild("ProgressBarContainer") or purchaseButton:FindFirstChild("ProgressContainer")

	if nameplate then nameplate:Destroy() end
	if progressBar then progressBar:Destroy() end
end

function PB.CreateLogic(class)
	local buttonBase: Part = class.PurchaseButton:FindFirstChild("Base")
	class.ButtonDebounce = false

	local function handleUpgrade(class)
		Events.FireBindableEvent(Events.BindableNames.PurchaseEntity, class)
	end

	class._cleaner:Add(buttonBase.Touched:Connect(function(hit)
		if class.ButtonDebounce then return end
		class.ButtonDebounce = true

		if hit.Parent:FindFirstChild("Humanoid") then
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				if class.Player ~= player or player.UserId ~= class.Owner then return end

				if class.Level == class.MaxLevel then
					local button: Part = class.PurchaseButton:FindFirstChild("Button")
					button.Color = FFGEnum.THEME.intent.disabled
					return
				end

				handleUpgrade(class)
				task.spawn(function()
					task.wait(1)
					class.ButtonDebounce = false
				end)
			end
		end
	end))
end

return PB
