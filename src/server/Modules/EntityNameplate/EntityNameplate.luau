local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BoatType = require(ReplicatedStorage.Shared.Types.Classes.BoatType)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local PortStorageType = require(ReplicatedStorage.Shared.Types.Classes.PortStorageType)
local TenderType = require(ReplicatedStorage.Shared.Types.Classes.TenderType)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)

-- //SECTION - TYPES
type Boat = BoatType.BoatInstance
type Tender = TenderType.TenderInstance
type PortStorage = PortStorageType.StorageInstance
type Building = BuildingType.BuildingInstance
type Helper = HelperType.HelperInstance
-- //!SECTION

local EntityNameplate = {}
EntityNameplate.JobIconImage = {
	Fishing = FFGEnum.UI.Icons.Inventory,
	Woodcutting = FFGEnum.UI.Icons.Inventory,
	Mining = FFGEnum.UI.Icons.Inventory,
	Transporting = FFGEnum.UI.Icons.Inventory,
	Boat = FFGEnum.UI.Icons.Fishing,
	None = FFGEnum.UI.Icons.Inventory,
}

export type Props = {
	Id: string,
	Name: string,
	QualityId: number,
	Level: number,
	UpgradeStage: number,
	JobCategory: "Fishing" | "Woodcutting" | "Mining" | "Transporting" | "None",
	MaxStorage: number?,
	FPS: number?,
	Adornee: Instance?,
}

function EntityNameplate.Create(props: Props)
	local entityName = Instance.new("BillboardGui")
	entityName.Name = "EntityNameplate"
	entityName.AlwaysOnTop = true
	if props.Adornee then entityName.Adornee = props.Adornee end
	entityName.Enabled = false
	entityName.LightInfluence = 1
	entityName.MaxDistance = FFGEnum.THEME.Nameplate.MaxDistance
	entityName.ResetOnSpawn = false
	entityName.Size = UDim2.fromScale(10, 5)
	entityName.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local frameContainer = Instance.new("Frame")
	frameContainer.Name = "Main"
	frameContainer.BackgroundTransparency = 1
	frameContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	frameContainer.Position = FFGEnum.THEME.alignment.position.center
	frameContainer.Size = UDim2.fromScale(1, 1)
	frameContainer.Parent = entityName
	UIConfig.ApplyList(frameContainer, Enum.FillDirection.Vertical, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	local nameplateBg = Instance.new("ImageLabel")
	nameplateBg.Name = "NameplateBG"
	nameplateBg.ScaleType = Enum.ScaleType.Slice
	nameplateBg.SliceCenter = Rect.new(35, 35, 35, 35)
	nameplateBg.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	nameplateBg.Position = FFGEnum.THEME.alignment.position.center
	nameplateBg.ZIndex = 0
	nameplateBg.BackgroundTransparency = 1
	nameplateBg.Size = UDim2.fromScale(1, 1)
	nameplateBg.ImageTransparency = 0.7
	nameplateBg.Image = FFGEnum.UI.Frames.NameplateBackground
	nameplateBg.Parent = entityName

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	name.BackgroundTransparency = 1
	name.Font = FFGEnum.THEME.bigFont
	name.LayoutOrder = 2
	name.Position = UDim2.fromScale(0.5, 0.5)
	name.Size = UDim2.fromScale(1, 0.3)
	name.Text = props.Name or ""
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.7
	name.TextScaled = true
	UIConfig.AddPadding(name, "L")
	name.Parent = frameContainer

	local quality = Instance.new("TextLabel")
	quality.Name = "Quality"
	quality.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	quality.BackgroundTransparency = 1
	quality.Font = FFGEnum.THEME.bigFont
	quality.LayoutOrder = 1
	quality.Position = UDim2.fromScale(0.5, 0.5)
	quality.Size = UDim2.fromScale(1, 0.2)
	quality.Text = FFGEnum.QUALITIES[props.QualityId].Label or ""
	quality.TextColor3 = FFGEnum.QUALITIES[props.QualityId].Color or Color3.new(1, 1, 1)
	quality.TextStrokeTransparency = 0.7
	quality.TextScaled = true
	UIConfig.AddPadding(quality, "L")
	quality.Parent = frameContainer

	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	infoContainer.BackgroundTransparency = 1
	infoContainer.LayoutOrder = 3
	infoContainer.Position = UDim2.fromScale(0.5, 0.5)
	infoContainer.Size = UDim2.fromScale(0.8, 0.3)
	UIConfig.ApplyList(infoContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center })

	local level = Instance.new("TextLabel")
	level.Name = "Level"
	level.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	level.BackgroundTransparency = 1
	level.Font = FFGEnum.THEME.bigFont
	level.LayoutOrder = 1
	level.Size = UDim2.fromScale(0.33, 1)
	level.Text = `Level {props.Level}`
	level.TextColor3 = Color3.fromRGB(0, 255, 0)
	level.TextStrokeTransparency = 0.7
	level.TextXAlignment = Enum.TextXAlignment.Left
	level.TextScaled = true
	UIConfig.AddPadding(level, "L")
	level.Parent = infoContainer

	local jobInfoContainer = Instance.new("Frame")
	jobInfoContainer.Name = "JobInfoContainer"
	jobInfoContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	jobInfoContainer.BackgroundTransparency = 1
	jobInfoContainer.LayoutOrder = 2
	jobInfoContainer.Size = UDim2.fromScale(0.33, 1)
	jobInfoContainer.Parent = infoContainer
	UIConfig.ApplyList(jobInfoContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	if props.JobCategory ~= "Building" then
		local jobInfoIcon = Instance.new("ImageLabel")
		jobInfoIcon.Name = "JobInfoIcon"
		jobInfoIcon.Size = UDim2.fromScale(0.5, 1)
		jobInfoIcon.Image = EntityNameplate.JobIconImage[props.JobCategory] or EntityNameplate.JobIconImage.None
		jobInfoIcon.BackgroundTransparency = 1
		jobInfoIcon.Parent = jobInfoContainer
		UIConfig.ApplyAspect(jobInfoIcon)

		local jobInfoText = Instance.new("TextLabel")
		jobInfoText.Name = "JobInfoText"
		jobInfoText.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		jobInfoText.BackgroundTransparency = 1
		jobInfoText.Font = FFGEnum.THEME.bigFont
		jobInfoText.LayoutOrder = 1
		jobInfoText.Size = UDim2.fromScale(0.5, 1)
		jobInfoText.Text = props.JobCategory == FFGEnum.CLASS.ENTITY_NAME.Boat and `{props.FPS}/s` or props.MaxStorage or ""
		jobInfoText.TextColor3 = FFGEnum.THEME.color.Blue
		jobInfoText.TextStrokeTransparency = 0.7
		jobInfoText.TextScaled = true
		jobInfoText.TextXAlignment = Enum.TextXAlignment.Left
		jobInfoText.Parent = jobInfoContainer
		UIConfig.AddPadding(jobInfoText, "L")
	end

	local stage = Instance.new("TextLabel")
	stage.Name = "Stage"
	stage.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	stage.BackgroundTransparency = 1
	stage.Font = FFGEnum.THEME.bigFont
	stage.LayoutOrder = 3
	stage.Size = UDim2.fromScale(0.33, 1)
	stage.Text = FFGEnum.STAGES[props.UpgradeStage].Label
	stage.TextColor3 = FFGEnum.STAGES[props.UpgradeStage].Color or Color3.new(1, 1, 1)
	stage.TextStrokeTransparency = 0.7
	stage.TextXAlignment = Enum.TextXAlignment.Right
	stage.TextScaled = true
	UIConfig.AddPadding(stage, "L")
	stage.Parent = infoContainer

	infoContainer.Parent = frameContainer

	-- Event for handling Helper upgrades
	-- local freshHelperData = Events.GetRemote(Events.RemoteNames.HelperData)
	-- if freshHelperData then
	-- 	freshHelperData.OnClientEvent:Connect(function(helperData: HelperType.HelperData)
	-- 		if not props.JobCategory or props.JobCategory == "None" then return end
	-- 		if props.Id ~= helperData.Id then return end

	-- 		EntityNameplate.Update(entityName, helperData)
	-- 	end)
	-- end

	-- -- Event for handling non-helper upgrades/purchases
	-- local updateEvent = Events.GetRemote(Events.RemoteNames.EntityPurchased)
	-- if updateEvent then
	-- 	updateEvent.OnClientEvent:Connect(function(player: Player, entityData: Boat | Tender | PortStorage | Building)
	-- 		if props.JobCategory and props.JobCategory ~= "None" then return end
	-- 		if props.Id ~= entityData.Id then return end

	-- 		EntityNameplate.Update(entityName, entityData)
	-- 	end)
	-- end

	return entityName
end

function EntityNameplate.Update(entityBillboard: BillboardGui, class: Boat | Tender | PortStorage | Building | Helper)
	local typedClass
	if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
		typedClass = class :: Boat
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Tender then
		typedClass = class :: Tender
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.PortStorage then
		typedClass = class :: PortStorage
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then
		typedClass = class :: Building
	elseif class.Entity == FFGEnum.CLASS.ENTITY_NAME.Helper then
		typedClass = class :: Helper
	else
		error("Invalid entity passed to update EntityNameplate")
	end

	local levelLabel: TextLabel = entityBillboard:FindFirstChild("Level", true)
	local stageLabel: TextLabel = entityBillboard:FindFirstChild("Stage", true)
	local qualityLabel: TextLabel = entityBillboard:FindFirstChild("Quality", true)
	local jobInfoIcon: ImageLabel = entityBillboard:FindFirstChild("JobInfoIcon", true)
	local jobInfoText: TextLabel = entityBillboard:FindFirstChild("JobInfoText", true)

	if levelLabel then levelLabel.Text = `Level {typedClass.Level}` end

	if stageLabel then
		stageLabel.Text = FFGEnum.STAGES[typedClass.UpgradeStage].Label
		stageLabel.TextColor3 = FFGEnum.STAGES[typedClass.UpgradeStage].Color or Color3.new(1, 1, 1)
	end

	if typedClass.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Building then
		if qualityLabel then qualityLabel.Text = FFGEnum.QUALITIES[typedClass.QualityId].Label or "" end
	end

	if jobInfoIcon then jobInfoIcon.Image = EntityNameplate.JobIconImage[typedClass.JobCategory] or EntityNameplate.JobIconImage.None end

	if jobInfoText then jobInfoText.Text = typedClass.JobCategory == FFGEnum.CLASS.ENTITY_NAME.Boat and `{typedClass.FPS}/s` or typedClass.MaxStorage or "" end
end

return EntityNameplate
