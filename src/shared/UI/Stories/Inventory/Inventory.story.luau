local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInventory = require(ReplicatedStorage.Shared.UI.Components.Inventory.PlayerInventory)

local function story(target)
	local instance = PlayerInventory.Create({ Name = "Inventory", ScreenGuiName = "PlayerInventory" })
	instance.Parent = target

	return function()
		instance:Destroy()
	end
end

return story
