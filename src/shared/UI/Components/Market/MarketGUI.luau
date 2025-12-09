local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishType = require(ReplicatedStorage.Shared.Types.Classes.FishType)
local InfoPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.InfoPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local MarketGUI = {}
MarketGUI.PlayerInfoPanels = {}

function MarketGUI.Create(playerId: number)
	local screenGui = MainUIPanel.Create({
		screenGuiName = FFGEnum.SCREENGUI.Market,
		panelName = "Market",
		panelTabs = {
			hasTabs = true,
			tabs = {
				{ Name = "Fish", Index = 1, Icon = FFGEnum.UI.Icons.Fishing },
			},
		},
	})

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	KinUI.ApplyList(innerWindow, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceEvenly, VAlign = Enum.VerticalAlignment.Center })
	if innerWindow then SingleGridLayout.Create({ Name = "ItemContainer", Parent = innerWindow, Size = "TwoThird" }) end

	local updateInfoPanelEvent = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanelEvent then
		updateInfoPanelEvent.OnClientEvent:Connect(function(data: { Item: FishType.FishData, isFishDex: boolean? })
			if data.isFishDex then return end

			MarketGUI.RenderInfoPanel(innerWindow, data.Item, playerId)
		end)
	else
		warn("[MarketGUI] UpdateInfoPanel RemoteEvent not found!")
	end
	return screenGui
end

function MarketGUI.RenderInfoPanel(innerWindow, item, playerId: number)
	local existing = MarketGUI.PlayerInfoPanels[playerId]
	if existing then existing:Destroy() end

	MarketGUI.PlayerInfoPanels[playerId] = InfoPanel.Create({ Parent = innerWindow, Infodata = item, isMarket = true })
end

function MarketGUI.CloseShop(mainFrame)
	mainFrame.Enabled = false
	if Lighting then
		local children = Lighting:GetChildren()
		for _, instance: Instance in pairs(children) do
			if instance.Name == "Blur" then instance:Destroy() end
		end
	end
end

return MarketGUI
