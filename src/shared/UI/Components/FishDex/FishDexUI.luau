local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)

local FishDexUI = {}

function FishDexUI.Create()
	local screenGui = MainUIPanel.Create({
		screenGuiName = FFGEnum.SCREENGUI.FishDex,
		panelName = "Fish Dex",
		hasTabs = true,
		tabs = {
			{ Name = "Transporting", Index = 1, Icon = FFGEnum.UI.Icons.Water },
		},
	})

	return screenGui
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
