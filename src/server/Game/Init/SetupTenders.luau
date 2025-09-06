local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Tender = require(ServerScriptService.Server.Classes.Tender)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

type TenderInstance = TenderType.TenderInstance

local taggedTenders = CollectionService:GetTagged("Tender")

function SetuptaggedTenders(player: Player, teamId: number)
	if player then task.delay(1, function()
		for _, taggedTender in ipairs(taggedTenders) do
			local teamIdAtt = taggedTender:GetAttribute("TeamId")
			if teamId == teamIdAtt then SetupTender(taggedTender, player) end
		end
	end) end
end

function SetupTender(tenderModel: Model, player: Player)
	if not player then
		FFGHelpers.PrintLog("No local player found, unable to setup boat")
		return
	end

	local state = GetTenderState(player)
	-- //TODO Remove hardcoded index
	local Tender: TenderInstance = Tender.New(state[1], player, tenderModel)

	Tender:Initialize()
	-- BoatManager.RegisterTender(Tender)
end

function GetBoosts(player: Player)
	-- //TODO - handle boosts
end

function GetTenderState(player: Player)
	return DataService.LoadTenderState(player)
end

return {
	SetuptaggedTenders = SetuptaggedTenders,
	SetupTender = SetupTender,
	GetTenderState = GetTenderState,
	GetBoosts = GetBoosts,
}
