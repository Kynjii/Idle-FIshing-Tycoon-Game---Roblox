local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGDefaults = require(ReplicatedStorage.Shared.Utils.FFGDefaults)
local BoatData = require(script.Parent.BoatData)

local taggedBoats = CollectionService:GetTagged("Boat")

local function setupBoat(boat: Model)
	local primaryPart = boat.PrimaryPart

	local attributes = BoatData.Default_Attributes

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end

	local purchaseButton = boat:WaitForChild("Purchase_Button")

	local debounce = false
	if purchaseButton then
		purchaseButton.Touched:Connect(function(otherPart)
			if debounce then
				return
			end
			local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				debounce = true
				print("Touched:" .. primaryPart:GetAttribute("Name"))

				task.delay(FFGDefaults.DebounceCD, function()
					debounce = false
				end)
			end
		end)
	end
end

for _, taggedBoat in ipairs(taggedBoats) do
	setupBoat(taggedBoat)
end

CollectionService:GetInstanceAddedSignal("Boat"):Connect(setupBoat)
