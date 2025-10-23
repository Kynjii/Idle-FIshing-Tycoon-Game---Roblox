local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local SingleGridLayout = require(ReplicatedStorage.Shared.UI.Components.GridLayouts.SingleGridLayout)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local PlayerInventory = {}

function PlayerInventory.Create(props: {
	Name: string,
	ScreenGuiName: string,
})
	local shopScreenGui = Instance.new("ScreenGui")
	shopScreenGui.Name = props.ScreenGuiName
	shopScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	shopScreenGui.ResetOnSpawn = false
	shopScreenGui.Enabled = false

	local mainPanel = MainUIPanel.Create({ Name = "Inventory", Parent = shopScreenGui })

	SingleGridLayout.Create({ Name = "ItemContainer", Parent = mainPanel })

	Tooltip.Initialize(mainPanel)

	return shopScreenGui
end

function PlayerInventory.CloseShop(screenGui)
	screenGui.Enabled = false
	if Lighting then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then blur:Destroy() end
	end
end

return PlayerInventory
