local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local ShopGUI = {}

function ShopGUI.Create(props: {
	screenGuiName: string,
	shopName: string,
})
	local screenGui = MainUIPanel.Create({ screenGuiName = props.screenGuiName, panelName = props.shopName })

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	if innerWindow then SingleGridLayout.Create({ Name = "ItemContainer", Parent = innerWindow, Size = "Full" }) end

	Tooltip.Initialize()

	return screenGui
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
