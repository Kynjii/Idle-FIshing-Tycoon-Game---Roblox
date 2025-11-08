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
		EntityData = typedClass,
		Adornee = billboardRoot,
		HasProgressBar = true,
	})
	pbDetails.Enabled = true
	pbDetails.Parent = billboardRoot

	PriceBillboard.Create({
		IsPurchased = typedClass.IsPurchased,
		BaseCost = typedClass.BaseCost,
		UpgradeCost = typedClass.UpgradeCost,
		Parent = button,
	})

	local levelLabel = pbDetails:FindFirstChild("Level", true)
	local stageLabel = pbDetails:FindFirstChild("Stage", true)
	local qualityLabel = pbDetails:FindFirstChild("Quality", true)

	if button then
		if not DataService.CanAfford(typedClass.Player, "Gold", not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost) then
			button.Color = FFGEnum.THEME.color.red
		else
			button.Color = FFGEnum.THEME.color.Green
		end
	end

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

	local buttonColorStateEvent = Events.GetBindableEvent(Events.BindableNames.UpdateState)
	if buttonColorStateEvent then
		typedClass._cleaner:Add(buttonColorStateEvent.Event:Connect(function(...: any)
			if button then
				if not DataService.CanAfford(typedClass.Player, "Gold", not typedClass.IsPurchased and typedClass.BaseCost or typedClass.UpgradeCost) then
					button.Color = FFGEnum.THEME.color.red
				else
					button.Color = FFGEnum.THEME.color.Green
				end
			end

			local priceBillboard = button:FindFirstChild("PriceBillboard", true)
			if priceBillboard then priceBillboard:Destroy() end

			PriceBillboard.Create({
				IsPurchased = typedClass.IsPurchased,
				BaseCost = typedClass.BaseCost,
				UpgradeCost = typedClass.UpgradeCost,
				Parent = button,
			})
		end))
	end

	return purchaseButton, pbDetails
end

function PB.Destroy(pbModel: Model)
	local purchaseButton = pbModel
	local billboardRoot = purchaseButton:FindFirstChild("BillboardRoot") :: Part
	local nameplate = billboardRoot:FindFirstChild("EntityNameplate")
	local button: Part = purchaseButton:FindFirstChild("Button")
	local priceBillboard = button:FindFirstChild("PriceBillboard")
	if nameplate then nameplate:Destroy() end
	if priceBillboard then priceBillboard:Destroy() end
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
