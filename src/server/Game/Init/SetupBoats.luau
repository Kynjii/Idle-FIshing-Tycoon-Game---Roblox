local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local BoatClass = require(ServerScriptService.Server.Classes.Boat)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

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
	-- //TODO Remove hardcoded index
	local Boat = BoatClass:New(state[1], player, boatModel)

	Boat:Initialize()
end

function GetBoosts(player: Player)
	-- //TODO - handle boosts
end

function GetBoatState(player: Player)
	return DataService.LoadBoatState(player)
end

return {
	SetupTaggedBoats = SetupTaggedBoats,
	SetupBoat = SetupBoat,
	GetBoatState = GetBoatState,
	GetBoosts = GetBoosts,
}
