local CollectionService = game:GetService("CollectionService")
local BoatData = require(script.Parent.BoatData)

local taggedBoats = CollectionService:GetTagged("Boat")

local function setupBoat(boat: Model)
	local primaryPart = boat.PrimaryPart

	local attributes = BoatData.Default_Attributes

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end
end

for _, taggedBoat in ipairs(taggedBoats) do
	setupBoat(taggedBoat)
end

CollectionService:GetInstanceAddedSignal("Boat"):Connect(setupBoat)
