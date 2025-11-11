local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Notification = require(script.Parent.Notification)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
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

	local isBuilding = class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building

	local nameplate = EntityNameplate.Create({
		EntityData = typedClass,
		Adornee = billboardRoot,
		HasProgressBar = not isBuilding and true or false,
	})
	nameplate.Enabled = true
	nameplate.Parent = billboardRoot

	PriceBillboard.Create({
		IsPurchased = typedClass.IsPurchased,
		BaseCost = typedClass.BaseCost,
		UpgradeCost = typedClass.UpgradeCost,
		Parent = button,
	})

	local levelLabel = nameplate:FindFirstChild("Level", true)
	local stageLabel = nameplate:FindFirstChild("Stage", true)
	local qualityLabel = nameplate:FindFirstChild("Quality", true)

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

	return purchaseButton, nameplate
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

	local function handleStateUpdate(player: Player, class)
		local canProceed = Tutorial.CheckTutorialState(player, class)
		if not canProceed then
			Notification.SendAlert(player, "Follow the Tutorial to unlock this!")
			return
		end

		-- See if the player can afford the state update (purchase / upgrade)
		if not DataService.CanAfford(player, FFGEnum.CURRENCY_TYPES.Gold, not class.IsPurchased and class.BaseCost or class.UpgradeCost) then return end

		DataService.Spend(player, FFGEnum.CURRENCY_TYPES.Gold, not class.IsPurchased and class.BaseCost or class.UpgradeCost)

		if class.IsPurchased then
			class:Upgrade()
		else
			class:Purchase()
			class:Show()
			class:CanCollide()

			if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then class:StartFishing() end
		end

		class:Save()

		Events.FireBindableEvent(Events.BindableNames.EntityUpdated, HttpService:JSONEncode(class:Serialize()))
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

				handleStateUpdate(player, class)
				task.spawn(function()
					task.wait(1)
					class.ButtonDebounce = false
				end)
			end
		end
	end))
end

return PB
