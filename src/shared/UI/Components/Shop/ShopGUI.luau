local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local ShopGUI = {}

function ShopGUI.Create(props: {
	ShopName: string,
	ScreenGuiName: string,
})
	local shopScreenGui = Instance.new("ScreenGui")
	shopScreenGui.Name = props.ScreenGuiName
	shopScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	shopScreenGui.ResetOnSpawn = false
	shopScreenGui.Enabled = true

	local mainPanel = MainUIPanel.Create({ Name = "Crew Shop" })
	mainPanel.Parent = shopScreenGui

	local shopItemsContainer = SingleGridLayout.Create({ Name = "ShopItemContainer" })
	shopItemsContainer.Parent = mainPanel

	Tooltip.Initialize(mainPanel)

	return shopScreenGui
end

function ShopGUI.CloseShop(mainFrame)
	mainFrame.Visible = false
	if Lighting then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then blur:Destroy() end
	end
end

return ShopGUI
