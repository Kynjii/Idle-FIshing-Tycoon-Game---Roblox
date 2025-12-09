local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local InfoPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.InfoPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local ShopGUI = {}
ShopGUI.PlayerInfoPanels = {}
ShopGUI.RenderInProgress = {}

function ShopGUI.Create(props: { screenGuiName: string?, panelName: string?, panelTabs: boolean? }, playerId: number)
	local screenGui = MainUIPanel.Create({
		screenGuiName = props and props.screenGuiName or FFGEnum.SCREENGUI.HelperShop,
		panelName = props and props.panelName or "Hire Crew Members",
		panelTabs = props and props.panelTabs and {
			hasTabs = true,
			tabs = {
				{ Name = "Transporters", Index = 1, Icon = FFGEnum.UI.Icons.Transporting },
			},
		} or {},
	})

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	KinUI.ApplyList(innerWindow, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceEvenly, VAlign = Enum.VerticalAlignment.Center })
	if innerWindow then SingleGridLayout.Create({ Name = "ItemContainer", Parent = innerWindow, Size = "TwoThird" }) end

	local updateInfoPanelEvent = Events.GetRemote(Events.RemoteNames.UpdateInfoPanel)
	if updateInfoPanelEvent then
		updateInfoPanelEvent.OnClientEvent:Connect(function(data: { Item: any, isFishDex: boolean? })
			if data.isFishDex then return end
			if props.screenGuiName == "FishingRodShop" and data.Item.Entity ~= FFGEnum.CLASS.ENTITY_NAME.FishingRod then return end
			if props.screenGuiName == "HelperShop" and data.Item.Entity ~= FFGEnum.CLASS.ENTITY_NAME.Helper then return end

			local shopItems = innerWindow:FindFirstChild("ItemContainer"):GetChildren()

			for i, item in ipairs(shopItems) do
				if not item:IsA("Frame") then continue end

				local stroke = item:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Transparency = 1 end

				if tostring(data.Item.Id) == item.Name then stroke.Transparency = 0 end
			end

			ShopGUI.RenderInfoPanel(innerWindow, data.Item, playerId)
		end)
	end
	return screenGui
end

function ShopGUI.RenderInfoPanel(innerWindow, item, playerId: number)
	if ShopGUI.RenderInProgress[playerId] then return end
	ShopGUI.RenderInProgress[playerId] = true

	local existing = ShopGUI.PlayerInfoPanels[playerId]
	if existing then
		existing:Destroy()
		ShopGUI.PlayerInfoPanels[playerId] = nil
	end

	local newInfoPanel = InfoPanel.Create({ Parent = innerWindow, Infodata = item })
	ShopGUI.PlayerInfoPanels[playerId] = newInfoPanel

	task.wait(0.1)
	ShopGUI.RenderInProgress[playerId] = nil
end

function ShopGUI.CloseShop(mainFrame)
	mainFrame.Enabled = false
	if Lighting then
		local children = Lighting:GetChildren()
		for _, instance: Instance in pairs(children) do
			if instance.Name == "Blur" then instance:Destroy() end
		end
	end
end

return ShopGUI
