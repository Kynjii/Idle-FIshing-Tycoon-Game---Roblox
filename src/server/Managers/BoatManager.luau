local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

type Boat = BoatType.Boat
type Tender = TenderType.Tender

local BoatManager = {}
BoatManager.Boats = {}
BoatManager.Tenders = {}

function BoatManager.RegisterBoat(boatClass: Boat)
	table.insert(BoatManager.Boats, boatClass)
end

function BoatManager.RegisterTender(tenderClass)
	table.insert(BoatManager.Tenders, tenderClass)

	local boat = BoatManager.Boats[1]

	if boat then
		FFGHelpers.PrintLog("Boat found: ", boat)
		local model = boat.Model :: Model
		local pp = model.PrimaryPart
		local cf = pp.CFrame
		tenderClass:MoveToBoat(boat, cf)
	else
		FFGHelpers.PrintLog("No boatClass found", BoatManager.Boats)
	end
end

function BoatManager.LoadFish(tenderClass: Tender, linkedBoatClass: Boat)
	local tender = tenderClass
	local boat = linkedBoatClass
	local amount = math.max(boat.FishInStorage, tender.CurrentMaxStorage)
	boat:RemoveFish(amount)

	-- create function to locate the correct Boat the Tender is linked to
	-- create function to attempt to add fish within a 5 second timeframe
	-- create function to move the Tender to the Port/Original position
	-- ReadyToOffload(state, boat)
end

function BoatManager.OffloadFish(tenderState, linkedBoat)
	-- create function to attempt to remove fish within a 5 second timeframe
	-- create function to move the Tender to the Port/Original position
	-- ReadyForFish(tenderState, linkedBoat)
end

return BoatManager
