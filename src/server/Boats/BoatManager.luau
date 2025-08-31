local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)

local BoatManager = {
	ActiveBoats = {}, -- Structure: [player.UserId][boatId] = BoatInstance
}

-- Register a new boat instance for a player
BoatManager.RegisterBoat = function(player: Player, boat: FFGTypes.BoatInstance): boolean
	if not player or not boat then
		FFGHelpers.PrintLog("BoatManager: Invalid player or boat provided")
		return false
	end

	local userId = player.UserId
	local boatId = boat.Id

	-- Initialize player's boat table if it doesn't exist
	if not BoatManager.ActiveBoats[userId] then BoatManager.ActiveBoats[userId] = {} end

	-- Check if boat already exists
	if BoatManager.ActiveBoats[userId][boatId] then
		FFGHelpers.PrintLog("BoatManager: Boat already registered", boatId)
		return false
	end

	-- Register the boat
	BoatManager.ActiveBoats[userId][boatId] = boat
	FFGHelpers.PrintLog("BoatManager: Registered boat", boatId, "for player", player.Name)
	return true
end

-- Unregister a specific boat
BoatManager.UnregisterBoat = function(player: Player, boatId: string): boolean
	if not player or not boatId then return false end

	local userId = player.UserId
	if not BoatManager.ActiveBoats[userId] then return false end

	local boat = BoatManager.ActiveBoats[userId][boatId]
	if not boat then return false end

	-- Remove the boat
	BoatManager.ActiveBoats[userId][boatId] = nil
	FFGHelpers.PrintLog("BoatManager: Unregistered boat", boatId, "for player", player.Name)
	return true
end

-- Get all boats for a specific player
BoatManager.GetPlayerBoats = function(player: Player): { [string]: FFGTypes.BoatInstance }?
	if not player then return nil end

	local userId = player.UserId
	return BoatManager.ActiveBoats[userId] or {}
end

-- Get a specific boat by ID
BoatManager.GetBoat = function(player: Player, boatId: string): FFGTypes.BoatInstance?
	if not player or not boatId then return nil end

	local playerBoats = BoatManager.GetPlayerBoats(player)
	return playerBoats and playerBoats[boatId] or nil
end

-- Get total active boat count (for monitoring)
BoatManager.GetActiveBoatCount = function(): number
	local count = 0
	for userId, playerBoats in pairs(BoatManager.ActiveBoats) do
		for boatId, boat in pairs(playerBoats) do
			count = count + 1
		end
	end
	return count
end

return BoatManager
