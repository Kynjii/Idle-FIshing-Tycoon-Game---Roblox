local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.Data.DataManager)
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

-- Save all boats for a player to persistent storage
BoatManager.SaveAllBoats = function(player: Player): boolean
	local playerBoats = BoatManager.GetPlayerBoats(player)
	if not playerBoats then return false end

	local success = true
	for boatId, boat in pairs(playerBoats) do
		local serializedData = boat:Serialize() -- uppercase to match BoatInstance method
		local saveSuccess = DataManager.SaveBoatState(player, boatId, serializedData)
		if not saveSuccess then
			FFGHelpers.PrintLog("BoatManager: Failed to save boat", boatId)
			success = false
		end
	end

	-- Trigger profile save to persist all changes
	if success then
		success = DataManager.SaveAllBoatData(player)
		FFGHelpers.PrintLog("BoatManager: Saved all boats for player", player.Name)
	end

	return success
end

-- Clean up all boats for a player (when they leave)
BoatManager.CleanupPlayer = function(player: Player): boolean
	if not player then return false end

	local userId = player.UserId

	-- Save before cleanup
	BoatManager.SaveAllBoats(player)

	-- Remove from active boats
	if BoatManager.ActiveBoats[userId] then
		local boatCount = 0
		for _ in pairs(BoatManager.ActiveBoats[userId]) do
			boatCount = boatCount + 1
		end

		BoatManager.ActiveBoats[userId] = nil
		FFGHelpers.PrintLog("BoatManager: Cleaned up", boatCount, "boats for player", player.Name)
		return true
	end

	return false
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

-- Save all boats for all players (periodic save)
BoatManager.SaveAllPlayersBoats = function(): boolean
	local Players = game:GetService("Players")
	local success = true

	for _, player in pairs(Players:GetPlayers()) do
		local playerSuccess = BoatManager.SaveAllBoats(player)
		if not playerSuccess then success = false end
	end

	FFGHelpers.PrintLog("BoatManager: Periodic save completed, success:", success)
	return success
end

return BoatManager
