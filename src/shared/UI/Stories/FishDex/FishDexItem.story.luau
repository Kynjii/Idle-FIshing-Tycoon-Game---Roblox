local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishDexItem = require(ReplicatedStorage.Shared.UI.Components.FishDex.FishDexItem)

local function story(target)
	local item = FishDexItem({
		ItemData = {
			Caught = false,
			ItemImage = "rbxassetid://129183832440303",
			Name = "Large Char",
			NameKey = "LargeChar",
			Species = "Large Char",
			SpeciesKey = "LargeChar",
			Variant = "Normal",
		},
		Size = UDim2.fromOffset(150, 200),
		Parent = target,
	})

	return function()
		item:Destroy()
	end
end

return story
