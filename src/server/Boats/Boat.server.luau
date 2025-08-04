local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local BoatData = require(script.Parent.BoatData)

local taggedBoats = CollectionService:GetTagged("Boat")

local BOAT = {}

BOAT.SetupProximityPrompt = function(primaryPart: Part, purchaseButton: Part)
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseButton)
	proximityPrompt.ObjectText = primaryPart:GetAttribute("isUnlocked") and "Upgrade" or "Unlock"
	proximityPrompt.ActionText = primaryPart:GetAttribute("isUnlocked")
			and "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.Level))
		or "Boat"

	proximityPrompt.Triggered:Connect(function()
		-- logic for handling upgrade
		-- most likely send a remove event to server to update state which in turn updates the Instance's attribute(s)
		if primaryPart:GetAttribute("isUnlocked") then
			-- handle upgrading
		else
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isUnlocked, true)
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.isActive, true)
		end
	end)
end

BOAT.SetupUpgradeStore = function(boat: Model, primaryPart: Instance)
	local purchaseButton = boat:WaitForChild("Purchase_Button")
	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseButton, "SurfaceGui", "Main", "Header", "Name", "TextLabel")
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseButton, "SurfaceGui", "Main", "Header", "Level", "TextLabel")

	if pbDetails then
		local level = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.Level)
		for qualityIndex, qualityLevelCap in ipairs(FFGEnum.QUALITY_PROMOTION_LEVELS) do
			if level <= qualityLevelCap then
				local qualityInfo = FFGEnum.QUALITY[qualityIndex]
				if qualityInfo then
					local color = qualityInfo.color
					pbDetails.NameLabel.TextColor3 = color
				end

				break
			end
		end
		pbDetails.NameLabel.Text = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.Name)

		pbDetails.LevelLabel.Text = "Level: " .. level
	end

	return purchaseButton
end

BOAT.SetupBoat = function(boat: Model)
	local primaryPart = boat.PrimaryPart

	local attributes = BoatData.Default_Attributes

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end

	local purchaseButton = BOAT.SetupUpgradeStore(boat, primaryPart)
	BOAT.SetupProximityPrompt(primaryPart, purchaseButton)
end

for _, taggedBoat in ipairs(taggedBoats) do
	BOAT.SetupBoat(taggedBoat)
end

CollectionService:GetInstanceAddedSignal("Boat"):Connect(BOAT.SetupBoat)
