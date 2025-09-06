local ServerScriptService = game:GetService("ServerScriptService")
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local TenderSetup = require(ServerScriptService.Server.Game.Init.SetupTenders)
local BoatSetup = require(ServerScriptService.Server.Game.Init.SetupBoats)

type BoatInstance = BoatType.BoatInstance
type Tender = TenderType.Tender

local TeamManager = {}
TeamManager.Teams = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = 9,
	[10] = 10,
}

local function SetupBoats(player, teamId)
	if player then
		BoatSetup.SetupTaggedBoats(player, teamId)
	else
		FFGHelpers.PrintLog("No player passed during initalization")
	end
end

local function SetupTenders(player, teamId)
	if player then
		TenderSetup.SetuptaggedTenders(player, teamId)
	else
		FFGHelpers.PrintLog("No player passed during initalization")
	end
end

function TeamManager.AssignTeam(player: Player)
	for i, v in ipairs(TeamManager.Teams) do
		if v == i then
			TeamManager.Teams[i] = player
			return i
		end
	end

	return nil
end

function TeamManager.RemovePlayer(player: Player)
	for i, v in ipairs(TeamManager.Teams) do
		if v == player then
			TeamManager.Teams[i] = i
			break
		end
	end
end

function TeamManager.Initialize(player: Player)
	if not player then
		FFGHelpers.PrintLog("No Player object passed to TeamManager")
		return
	end

	local teamId: number? = TeamManager.AssignTeam(player)
	if not teamId then
		FFGHelpers.PrintLog("[Error] Unable to assign team for player")
		return
	end

	SetupBoats(player, teamId)
	SetupTenders(player, teamId)
end

return TeamManager
