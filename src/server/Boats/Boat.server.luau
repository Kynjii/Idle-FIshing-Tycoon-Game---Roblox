local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGDefaults = require(ServerScriptService.Server.FFGDefaults)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)

local taggedBoats = CollectionService:GetTagged("Boat")

local BOAT = {}

BOAT.SetupProximityPrompt = function(boat: Model, primaryPart: Part, purchaseBoard: Part)
	local proximityPrompt = Instance.new("ProximityPrompt", purchaseBoard)
	proximityPrompt.ObjectText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) and "Upgrade" or "Unlock"
	proximityPrompt.ActionText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased)
			and "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level))
		or "Boat"

	proximityPrompt.Triggered:Connect(function()
		if primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) then
			primaryPart:SetAttribute(
				FFGEnum.ATTRIBUTES.BOAT.Level,
				primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1
				-- //TODO probably gotta send something to replica at some point
			)
		else
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased, true)
			primaryPart:SetAttribute(FFGEnum.ATTRIBUTES.BOAT.isActive, true)

			proximityPrompt.ObjectText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased) and "Upgrade"
				or "Unlock"
			proximityPrompt.ActionText = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.isPurchased)
					and "Level: " .. tostring(primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level) + 1)
				or "Boat"

			local boatParts = boat:GetChildren()
			for _, part in pairs(boatParts) do
				if part.Transparency and part.Transparency == 1 then
					part.Transparency = 0
				end
			end
		end
	end)
end

BOAT.SetupUpgradeStore = function(boat: Model, primaryPart: Instance)
	local purchaseBoard = boat:WaitForChild("Purchase_Board")
	local pbDetails = {}
	pbDetails.NameLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Name", "TextLabel")
	pbDetails.LevelLabel = FFGHelpers.deepWait(purchaseBoard, "SurfaceGui", "Main", "Header", "Level", "TextLabel")

	if pbDetails then
		local level = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Level)
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
		pbDetails.NameLabel.Text = primaryPart:GetAttribute(FFGEnum.ATTRIBUTES.BOAT.Name)

		pbDetails.LevelLabel.Text = "Level: " .. level
	end

	return purchaseBoard
end

BOAT.SetupBoat = function(boat: Model)
	local primaryPart = boat.PrimaryPart
	local attributes = FFGDefaults.BOAT_STARTING_ATT

	for key, value in pairs(attributes) do
		primaryPart:SetAttribute(key, value)
	end
	-- //TODO Look into on attribute changed and then have other attributes update based that
	--  https://create.roblox.com/docs/reference/engine/classes/Instance#GetAttributeChangedSignal

	local purchaseBoard = BOAT.SetupUpgradeStore(boat, primaryPart)
	BOAT.SetupProximityPrompt(boat, primaryPart, purchaseBoard)
end

for _, taggedBoat in ipairs(taggedBoats) do
	BOAT.SetupBoat(taggedBoat)
end

CollectionService:GetInstanceAddedSignal("Boat"):Connect(BOAT.SetupBoat)
