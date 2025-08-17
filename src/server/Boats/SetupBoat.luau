local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BoatInstance = require(script.Parent.BoatInstance)
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)

local taggedBoats = CollectionService:GetTagged("Boat")

function SetupTaggedBoats(player)
	if player then task.delay(1, function()
		for _, taggedBoat in ipairs(taggedBoats) do
			SetupBoat(taggedBoat, player)
		end
	end) end
end

function SetupBoat(boatModel: Model, player: Player)
	if not player then
		FFGHelpers.PrintLog("No local player found, unable to setup boat")
		return
	end

	local state = GetBoatState(player)
	local Boat: FFGTypes.BoatInstance = BoatInstance:New(state, player.UserId, boatModel)

	Boat:Initialize()
end

function GetBoosts(player: Player)
	-- //TODO - handle boosts
end

function GetBoatState(player: Player)
	return DataManager.LoadBoatState(player)
end

return {
	SetupTaggedBoats = SetupTaggedBoats,
	SetupBoat = SetupBoat,
	GetBoatState = GetBoatState,
	GetBoosts = GetBoosts,
}
