local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local InfoPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.InfoPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local FishDexUI = {}

function FishDexUI.Create()
	local screenGui = MainUIPanel.Create({
		screenGuiName = FFGEnum.SCREENGUI.FishDex,
		panelName = "Fish Dex",
		panelTabs = {
			hasTabs = true,
			tabs = {
				{ Name = "WaterRealm", Index = 1, Icon = FFGEnum.UI.Icons.Water },
			},
		},
	})

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	KinUI.ApplyList(innerWindow, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceEvenly, VAlign = Enum.VerticalAlignment.Center })
	if innerWindow then SingleGridLayout.Create({ Name = "ItemContainer", Parent = innerWindow, Size = "TwoThird" }) end

	local updateInfoPanelEvent = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanelEvent then updateInfoPanelEvent.OnClientEvent:Connect(function(fish)
		FishDexUI.RenderInfoPanel(innerWindow, fish)
	end) end

	return screenGui
end

function FishDexUI.RenderInfoPanel(innerWindow, fish)
	local existing = innerWindow:FindFirstChild("InfoPanelContainer", true)
	if existing then existing:Destroy() end

	InfoPanel.Create({ Parent = innerWindow, Infodata = fish })
end

function FishDexUI.CloseShop(mainFrame)
	mainFrame.Enabled = false
	if Lighting then
		local children = Lighting:GetChildren()
		for _, instance: Instance in pairs(children) do
			if instance.Name == "Blur" then instance:Destroy() end
		end
	end
end

return FishDexUI
