local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)

local function story(target)
	local instance = ShopGUI.Create({ ShopName = "Crew Shop", ScreenGuiName = "HelperShop" })
	local shopDetailsUI = instance:WaitForChild("DetailsContainer") :: Frame
	shopDetailsUI.Parent = target

	return function()
		shopDetailsUI:Destroy()
	end
end

return story
