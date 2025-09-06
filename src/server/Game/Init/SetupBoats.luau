local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Boat = require(ServerScriptService.Server.Classes.Boat)
local BoatManager = require(ServerScriptService.Server.Managers.BoatManager)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

type BoatInstance = Boat.BoatInstance

local taggedBoats = CollectionService:GetTagged("Boat")

function SetupTaggedBoats(player: Player, teamId: number)
	if player then task.delay(1, function()
		for _, taggedBoat in ipairs(taggedBoats) do
			local teamIdAtt = taggedBoat:GetAttribute("TeamId")
			if teamId == teamIdAtt then SetupBoat(taggedBoat, player) end
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
	local Boat: BoatInstance = Boat.New(state[1], player, boatModel)

	Boat:Initialize()
	-- BoatManager.RegisterBoat(Boat)
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
