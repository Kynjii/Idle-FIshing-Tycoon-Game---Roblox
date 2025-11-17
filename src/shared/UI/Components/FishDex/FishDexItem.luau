--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local function FishDexItem(props: {
	ItemData: FishType.FishData,
	Size: UDim2,
	Visible: boolean?,
	HoverEffect: boolean?,
	Parent: Instance,
})
	local item = props.ItemData

	local fishDexItemContainer = Instance.new("Frame")
	fishDexItemContainer.Name = item.Id or item.Species
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

	local itemQualityBG = Instance.new("ImageLabel")
	itemQualityBG.Name = "ItemBG"
	itemQualityBG.Size = UDim2.fromScale(1, 1)
	itemQualityBG.BackgroundTransparency = 1
	itemQualityBG.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	itemQualityBG.Position = FFGEnum.THEME.alignment.position.center
	itemQualityBG.Image = FFGEnum.UI.Items.BackgroundQualityId[item.QualityId or item.Tier or variant[item.Variant]]
	itemQualityBG.Parent = fishDexItemContainer

	-- //SECTION - Shop Item Outline
	local hoverImage = Instance.new("ImageLabel")
	hoverImage.Name = "HoverImage"
	hoverImage.Image = FFGEnum.UI.Items.Hovered
	hoverImage.BackgroundTransparency = 1
	hoverImage.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	hoverImage.Position = FFGEnum.THEME.alignment.position.center
	hoverImage.ScaleType = Enum.ScaleType.Slice
	hoverImage.SliceCenter = Rect.new(26, 34, 31, 37)
	hoverImage.ImageColor3 = FFGEnum.THEME.color.white
	hoverImage.ImageTransparency = 0.7
	hoverImage.Size = UDim2.fromScale(0.95, 0.85)
	hoverImage.Visible = false
	hoverImage.Parent = fishDexItemContainer
	-- //!SECTION

	-- //SECTION Holds all the main elements
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "FishDexItemMainContainer"
	mainContainer.Size = UDim2.fromScale(0.9, 0.8)
	mainContainer.Position = FFGEnum.THEME.alignment.position.center
	mainContainer.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = fishDexItemContainer
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

	-- //SECTION - UI List Layout
	local uiList = Instance.new("UIListLayout")
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiList.VerticalFlex = Enum.UIFlexAlignment.SpaceAround
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = mainContainer
	-- //!SECTION

	return fishDexItemContainer
end

return FishDexItem
