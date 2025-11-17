--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local function FishDexItem(props: {
	ItemData: FishType.FishData,
	Size: UDim2,
	Visible: boolean?,
	Parent: Instance,
})
	local item = props.ItemData

	local fishDexItemContainer = Instance.new("Frame")
	fishDexItemContainer.Name = item.SpeciesKey or "UnknownFishContainer"
	fishDexItemContainer.BackgroundTransparency = 1
	fishDexItemContainer.Size = props.Size
	fishDexItemContainer.BackgroundColor3 = FFGEnum.THEME.color.white
	fishDexItemContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	fishDexItemContainer.Position = FFGEnum.THEME.alignment.position.center
	fishDexItemContainer.Visible = props.Visible or true
	fishDexItemContainer.ClipsDescendants = true
	fishDexItemContainer.Parent = props.Parent or nil

	local fishDexItemContainerAspect = Instance.new("UIAspectRatioConstraint")
	fishDexItemContainerAspect.AspectRatio = 1
	fishDexItemContainerAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	fishDexItemContainerAspect.Parent = fishDexItemContainer

	local variant = {
		Normal = 1,
		Elemental = 2,
		Elder = 5,
	}

	local itemQualityBG = Instance.new("ImageButton")
	itemQualityBG.Name = "ItemBG"
	itemQualityBG.Size = UDim2.fromScale(1, 1)
	itemQualityBG.BackgroundTransparency = 1
	itemQualityBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemQualityBG.Position = FFGEnum.THEME.alignment.position.center
	itemQualityBG.Image = FFGEnum.UI.Items.BackgroundQualityId[item.QualityId or item.Tier or variant[item.Variant]]
	itemQualityBG.Parent = fishDexItemContainer

	-- //SECTION Holds all the main elements
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "FishDexItemMainContainer"
	mainContainer.Size = UDim2.fromScale(0.9, 0.8)
	mainContainer.Position = FFGEnum.THEME.alignment.position.center
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = fishDexItemContainer
	KinUI.ApplyList(mainContainer, Enum.FillDirection.Vertical, { VFlex = Enum.UIFlexAlignment.SpaceAround, HAlign = Enum.HorizontalAlignment.Center })
	-- //!SECTION

	-- //SECTION - Item Name
	local itemName = Instance.new("TextLabel")
	itemName.Name = "ItemName"
	itemName.Font = FFGEnum.THEME.bigFont
	itemName.Size = UDim2.fromScale(1, 0.2)
	itemName.BackgroundTransparency = 1
	itemName.TextColor3 = FFGEnum.THEME.color.white
	itemName.LayoutOrder = 1
	itemName.Text = not item.Caught and item.SpeciesKey and "?" or item.Name
	itemName.TextScaled = true
	KinUI.AddStroke(itemName, "L")
	itemName.Parent = mainContainer
	-- //!SECTION

	-- //SECTION -  Item Image
	local image
	if item.SpeciesKey then
		if item.Caught then
			image = item.ItemImage
		else
			image = FishData.FISH_ASSETS_MASKED[item.SpeciesKey]
		end
	else
		image = item.ItemImage
	end

	local itemImage = Instance.new("ImageLabel")
	itemImage.Name = "ItemImage"
	itemImage.Image = image or ""
	itemImage.LayoutOrder = 2
	itemImage.BackgroundTransparency = 1
	itemImage.Size = UDim2.fromScale(0.6, 0.6)
	itemImage.ZIndex = 2
	KinUI.ApplyAspect(itemImage)
	itemImage.Parent = mainContainer
	-- //!SECTION

	itemQualityBG.Activated:Connect(function()
		Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, Players.LocalPlayer, item)
	end)

	return fishDexItemContainer
end

return FishDexItem
