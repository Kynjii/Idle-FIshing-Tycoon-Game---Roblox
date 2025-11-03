local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EntityNameplate = require(ServerScriptService.Server.Modules.EntityNameplate.EntityNameplate)
local DataService = require(ServerScriptService.Server.Services.DataService)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
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
		QualityId = typedClass.QualityId or typedClass.Tier,
		UpgradeStage = typedClass.UpgradeStage,
		Adornee = billboardRoot,
		Level = typedClass.Level,
	})
	pbDetails.Enabled = true
	pbDetails.Parent = billboardRoot

	-- //TODO - Move into helper func and add gold icon
	local priceBillboard = Instance.new("BillboardGui")
	priceBillboard.Name = "PriceBillboard"
	priceBillboard.AlwaysOnTop = true
	priceBillboard.Enabled = true
	priceBillboard.MaxDistance = FFGEnum.THEME.Nameplate.MaxDistance
	priceBillboard.ResetOnSpawn = false
	priceBillboard.Adornee = button
	priceBillboard.ExtentsOffsetWorldSpace = Vector3.new(70, 0, 0)
	priceBillboard.Size = UDim2.fromScale(2, 4)
	priceBillboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	priceBillboard.Parent = button

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = FFGEnum.THEME.bigFont
	priceLabel.LayoutOrder = 2
	priceLabel.Position = UDim2.fromScale(0.5, 0.5)
	priceLabel.Size = UDim2.fromScale(0.5, 0.5)
	local cost = not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost
	priceLabel.Text = FormatNumber(cost) or ""
	priceLabel.TextColor3 = FFGEnum.THEME.color.textGold
	priceLabel.TextStrokeTransparency = 0.7
	UIConfig.ApplyTextConstraints(priceLabel, "caption")
	priceLabel.Parent = priceBillboard

	local levelLabel = pbDetails:FindFirstChild("Level", true)
	local stageLabel = pbDetails:FindFirstChild("Stage", true)
	local qualityLabel = pbDetails:FindFirstChild("Quality", true)

	if button then
		if not DataService.CanAfford(class.Player, "Gold", not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost) then button.Color = FFGEnum.THEME.color.red end
	end

	local hasProgressBar = purchaseButton:FindFirstChild("ProgressBarContainer") or purchaseButton:FindFirstChild("ProgressContainer")
	if not hasProgressBar then PB.CreateProgressBar(purchaseButton, typedClass) end

	-- Handle State based on IsPurchased
	if not typedClass.IsPurchased then
		levelLabel.Visible = false
		stageLabel.Visible = false
	else
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
	local progressContainer = ProgressBar.Create({ Color = "GreenShiny", HasText = true, HasBillboard = true, Adornee = parent })
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
	ProgressBar.Update(progressBar, class.FishInStorage, class.CurrentMaxStorage)
end

function PB.Destroy(pbModel: Model)
	local purchaseButton = pbModel
	local billboardRoot = purchaseButton:FindFirstChild("BillboardRoot") :: Part
	local nameplate = billboardRoot:FindFirstChild("HelperNameplate")
	local progressBar = purchaseButton:FindFirstChild("ProgressBarContainer") or purchaseButton:FindFirstChild("ProgressContainer")

	if nameplate then nameplate:Destroy() end
	if progressBar then progressBar:Destroy() end
end

function PB.CreateLogic(class)
	local buttonBase: Part = class.PurchaseButton:FindFirstChild("Base")
	class.ButtonDebounce = false

	local function handleUpgrade(class)
		local data = {
			Id = class.Id,
			Player = class.Player,
		}
		Events.FireBindableEvent(Events.BindableNames.PurchaseEntity, data)
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
					task.wait(3)
					class.ButtonDebounce = false
				end)
			end
		end
	end))
end

return PB
