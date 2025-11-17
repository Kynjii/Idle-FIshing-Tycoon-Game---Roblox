--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishData = require(ReplicatedStorage.Shared.Fish.FishData)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local InfoPanel = {}

function InfoPanel.Create(props: {
	Infodata: FishType.FishData,
	Parent: Instance,
})
	local data = props.Infodata

	local panelContainer = Instance.new("Frame")
	panelContainer.Name = "PanelContainer"
	panelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	panelContainer.BackgroundTransparency = 1
	panelContainer.Position = UDim2.fromScale(0.80, 0.5)
	panelContainer.Size = UDim2.fromScale(0.35, 0.9)
	panelContainer.ZIndex = 0
	panelContainer.Parent = props.Parent
	KinUI.AddStroke(panelContainer, "XL", Color3.fromHex("#02447d"))
	KinUI.AddCorner(panelContainer, "S")
	KinUI.ApplyList(panelContainer, Enum.FillDirection.Vertical)
	KinUI.AddPadding(panelContainer, "M")

	-- //SECTION - Header
	local itemName = Instance.new("Frame")
	itemName.Name = "ItemName"
	itemName.BackgroundTransparency = 1
	itemName.Size = UDim2.fromScale(1, 0.15)
	itemName.Parent = panelContainer

	KinUI.AddTextLabel(itemName, nil, ((not data.Caught and "?") or data.Name), "L")
	-- //!SECTION

	-- //SECTION - Item Image
	local itemImage = Instance.new("Frame")
	itemImage.Name = "ItemImage"
	itemImage.BackgroundTransparency = 1
	itemImage.Size = UDim2.fromScale(1, 0.3)
	itemImage.Parent = panelContainer

	local image = nil
	if data.SpeciesKey then
		if data.Caught then
			image = data.ItemImage
		else
			image = FishData.FISH_ASSETS_MASKED[data.SpeciesKey]
		end
	else
		image = data.ItemImage or ""
	end

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ItemImage"
	imageLabel.Image = image or ""
	imageLabel.BackgroundTransparency = 1
	imageLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	imageLabel.Position = FFGEnum.THEME.alignment.position.center
	imageLabel.Size = UDim2.fromScale(0.6, 0.6)
	imageLabel.ZIndex = 2
	KinUI.ApplyAspect(imageLabel)
	imageLabel.Parent = itemImage
	-- //!SECTION

	-- //SECTION - Item Variants
	local itemVariants = Instance.new("Frame")
	itemVariants.BackgroundTransparency = 1
	itemVariants.Name = "ItemVariants"
	itemVariants.Size = UDim2.fromScale(1, 0.15)
	itemVariants.Parent = panelContainer
	KinUI.ApplyList(itemVariants, Enum.FillDirection.Vertical)
	KinUI.AddTextLabel(itemVariants, UDim2.fromScale(1, 0.3), "Variant", "M")
	KinUI.AddPadding(itemVariants, "M")

	local variantsContainer = Instance.new("Frame")
	variantsContainer.BackgroundTransparency = 1
	variantsContainer.Size = UDim2.fromScale(1, 0.65)
	variantsContainer.Parent = itemVariants
	KinUI.ApplyList(variantsContainer, Enum.FillDirection.Horizontal, { HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	if data.Variant == FishData.FISH_VARIANT.NORMAL then
		KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), "Normal", "M", 1, FFGEnum.THEME.Variants.Normal)
	elseif data.Variant == FishData.FISH_VARIANT.ELEMENTAL then
		local element = not data.Caught and "Elemental" or data.RealmId and FishData.REALM_ELEMENTS[data.RealmId]
		local elementColor = not data.Caught and FFGEnum.THEME.Variants.Elemental[1] or data.RealmId and FFGEnum.THEME.Variants.Elemental[data.RealmId]
		KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), element, "M", 2, elementColor)
	elseif data.Variant == FishData.FISH_VARIANT.ELDER then
		KinUI.AddBadge(variantsContainer, UDim2.fromScale(0.3, 0.8), "Elder", "M", 3, FFGEnum.THEME.Variants.Elder)
	end
	-- //!SECTION

	local statData = nil
	local fishStatFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishStat)
	if fishStatFn then
		if data.Caught then statData = fishStatFn:InvokeServer(data) end
	end
	print(statData)

	local itemProgress = Instance.new("Frame")
	itemProgress.Name = "ItemProgress"
	itemProgress.BackgroundTransparency = 1
	itemProgress.Size = UDim2.fromScale(1, 0.4)
	itemProgress.Parent = panelContainer
	KinUI.ApplyList(itemProgress, Enum.FillDirection.Vertical, { VFlex = Enum.UIFlexAlignment.SpaceBetween, HAlign = Enum.HorizontalAlignment.Center })

	if data.Caught then
		local progressHeader = Instance.new("Frame")
		progressHeader.BackgroundTransparency = 1
		progressHeader.Size = UDim2.fromScale(1, 0.1)
		progressHeader.LayoutOrder = 1
		progressHeader.Parent = itemProgress
		local label = KinUI.AddTextLabel(progressHeader, UDim2.fromScale(0.3, 1), "Total Count", "M")
		label.Position = UDim2.fromScale(0.35, 0.5)

		for i, qualityNum in ipairs(FFGEnum.QUALITIES) do
			local qualityContainer = Instance.new("Frame")
			qualityContainer.Size = UDim2.fromScale(1, 0.15)
			qualityContainer.BackgroundTransparency = 1
			qualityContainer.LayoutOrder = i + 1
			qualityContainer.Parent = itemProgress
			KinUI.ApplyList(qualityContainer, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceBetween, VAlign = Enum.VerticalAlignment.Center })

			local textLabel = KinUI.AddTextLabel(qualityContainer, UDim2.fromScale(0.25, 0.8), FFGEnum.QUALITIES[i].Label, "M")
			textLabel.LayoutOrder = 1

			local countLabel = KinUI.AddTextLabel(qualityContainer, UDim2.fromScale(0.15, 0.8), statData[data.Variant].Count, "M")
			countLabel.LayoutOrder = 2

			local progressBarContainer, progressBar = ProgressBar.Create({ Color = "Green", Parent = qualityContainer })
			progressBarContainer.Size = UDim2.fromScale(0.4, 1)
			if typeof(progressBarContainer) == "Frame" then progressBarContainer.LayoutOrder = 3 end

			-- //TODO - currentCount, achievement target
			ProgressBar.Update(progressBar, statData[data.Variant].Count, 1000)

			local claimButton = Button.Create({ Color = "White", Text = "Claim", CurrencyType = "None", Size = UDim2.fromScale(0.1, 1) })
			claimButton.ImageColor3 = FFGEnum.THEME.intent.disabled
			claimButton.LayoutOrder = 4
			claimButton.Interactable = false
			claimButton.Parent = qualityContainer
		end
	else
		KinUI.AddTextLabel(itemProgress, UDim2.fromScale(0.8, 0.8), "Undiscovered", "M")
	end

	return panelContainer
end

return InfoPanel
