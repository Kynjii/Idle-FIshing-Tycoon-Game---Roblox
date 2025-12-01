local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local InfoPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.InfoPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)

local HelperPanel = {}

function HelperPanel.Create(player: Player, crewData, innerWindow: Frame): ScrollingFrame
	local scrollingFrame = SingleGridLayout.Create({ Name = "ItemContainer", Parent = innerWindow, Size = "TwoThird" })

	local index = 0
	for _, helper in pairs(crewData) do
		local helperData: HelperType.HelperInstance = helper

		index += 1

		local helperItem = ShopItem({
			ItemData = helper,
			BackgroundColor3 = FFGEnum.QUALITIES[helper.QualityId].Color,
			Size = UDim2.fromScale(1, 1),
			Rounded = FFGEnum.THEME.button.cornerRadius,
			Visible = true,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(32, 83, 32, 83),
			Parent = scrollingFrame,
			ShopInstance = innerWindow,
		})
		helperItem.LayoutOrder = index

		if index == 1 then HelperPanel.RenderInfoPanel(innerWindow, helperData) end
	end

	if index == 0 then HelperPanel.AddEmptyState(scrollingFrame, "Purchase Crew Members from the Crew Shop to see them here.") end

	local updateInfoPanelEvent = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanelEvent then
		updateInfoPanelEvent.OnClientEvent:Connect(function(encodedData: { Item: HelperType.HelperInstance, isFishDex: boolean? })
			local data = HttpService:JSONDecode(encodedData)

			if data.isFishDex then return end

			HelperPanel.RenderInfoPanel(innerWindow, data.Item)
		end)
	end

	return scrollingFrame
end

function HelperPanel.AddEmptyState(parent: Instance, text: string)
	local emptyState = Instance.new("TextLabel")
	emptyState.Name = "EmptyState"
	emptyState.Font = FFGEnum.THEME.bigFont
	emptyState.TextColor3 = FFGEnum.THEME.color.white
	emptyState.BackgroundTransparency = 1
	emptyState.Size = UDim2.fromScale(0.8, 0.5)
	emptyState.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
	emptyState.Position = FFGEnum.THEME.alignment.position.center
	emptyState.Text = text
	emptyState.TextScaled = true
	emptyState.Parent = parent

	return emptyState
end

function HelperPanel.RenderInfoPanel(innerWindow, helper)
	local existing = innerWindow:FindFirstChild("InfoPanelContainer", true)
	if existing then existing:Destroy() end

	InfoPanel.Create({ Parent = innerWindow, Infodata = helper })
end

return HelperPanel
