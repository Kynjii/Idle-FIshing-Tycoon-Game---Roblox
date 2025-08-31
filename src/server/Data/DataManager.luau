local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local PlayerDataTemplate = require(script.Parent.PlayerDataTemplate)
local Replica = require(ServerScriptService.Server.ReplicaServer)
local PlayerStateToken = Replica.Token("PlayerState")

local DataManager = {}
DataManager.Profiles = {}
DataManager.Replicas = {}

function DataManager.AttachReplica(player: Player, profile)
	FFGHelpers.PrintLog("Attaching Replica for: ", player)

	local currencies = {}

	for currencyType, amount in pairs(profile.Data.Currencies) do
		currencies[currencyType] = amount or PlayerDataTemplate.Currencies[currencyType]
	end

	local replica = Replica.New({
		Token = PlayerStateToken,
		Data = {
			Currencies = currencies,
		},
	})
	FFGHelpers.PrintLog("New Replica is: ", replica)
	replica:Subscribe(player)
	DataManager.Replicas[player] = replica
	return replica
end

function DataManager.DetachReplica(player: Player)
	FFGHelpers.PrintLog("Detaching Replica for: ", player)
	local replica = DataManager.Replicas[player]
	if replica then
		replica:Destroy()
		DataManager.Replicas[player] = nil
	end
end

function DataManager.Earn(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to earn: ", currencyType)
		return
	end
	if typeof(amount) ~= "number" or amount <= 0 then
		FFGHelpers.PrintLog("The amount is either not a number or <= 0: ", currencyType)
		return
	end
	if typeof(currencyType) ~= "string" then
		FFGHelpers.PrintLog("The currencyType is not a string: ", currencyType)
		return
	end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	local newValue = current + amount
	profile.Data.Currencies[currencyType] = newValue

	local replica = DataManager.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end
end

function DataManager.CanAfford(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	return (tonumber(profile.Data.Currencies[currencyType]) or 0) >= amount
end

function DataManager.Spend(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	if typeof(amount) ~= "number" or amount <= 0 then return end
	if typeof(currencyType) ~= "string" then return end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	if current < amount then return end

	local newValue = current - amount
	profile.Data.Currencies[currencyType] = newValue

	local replica = DataManager.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end
end

function DataManager.ClearProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to clear profile data for: ", player)
		return
	end

	profile.Data = nil

	FFGHelpers.PrintLog("Cleared Profile Data: ", profile)
end

function DataManager.CreateNewProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to create new profile data for: ", player)
		return
	end

	local resetDataTemplate = TableUtil.Copy(PlayerDataTemplate, true)
	profile.Data = resetDataTemplate

	FFGHelpers.PrintLog("Created Profile Data: ", profile)
end

function DataManager.SaveBoatState(player: Player, boatId: string, newState: FFGTypes.BoatState): boolean
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save boat state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	if not profile.Data.Boats then
		FFGHelpers.PrintLog("Boats Table not found")
		return false
	end

	local existingBoat = TableUtil.Find(profile.Data.Boats, function(boat)
		return boat[FFGEnum.ATTRIBUTES.BOAT.Id] == boat[FFGEnum.ATTRIBUTES.BOAT.Id]
	end)

	if not existingBoat then
		profile.Data.Boats[newState] = newState
	else
		profile.Data.Boats[existingBoat] = newState
	end

	FFGHelpers.PrintLog("Saved boat state for player", player.Name, "boat", boatId)
	return true
end

function DataManager.GetBoatState(profile): FFGTypes.BoatState?
	-- //TODO - update to match new saving scheme
	if not profile or not profile.Data then return nil end
	local realmId = profile.Data.CurrentRealm

	-- //TODO remove hardcoded laneId
	local laneId = 1

	if not profile.Data.Realms then return nil end
	if not profile.Data.Realms[realmId] then return nil end
	if not profile.Data.Realms[realmId].Lanes then return nil end
	if not profile.Data.Realms[realmId].Lanes[laneId] then return nil end

	return profile.Data.Realms[realmId].Lanes[laneId].Boat
end

function DataManager.LoadBoatState(player: Player): FFGTypes.BoatState?
	FFGHelpers.PrintLog("Attempting to load boat state for: ", player)
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found for: ", player)
		return nil
	end

	local state = DataManager.GetBoatState(profile)
	if not state then
		FFGHelpers.PrintLog("Unable to get BoatState for loading")
		return nil
	end

	FFGHelpers.PrintLog("Current boat state: ", state)
	return state
end

function DataManager.LoadBoatStateById(player: Player, boatId: string): FFGTypes.BoatState?
	-- TODO: Implement proper boat lookup by ID when supporting multiple boats
	-- For now, just return the single boat state
	return DataManager.LoadBoatState(player)
end

function DataManager.SaveProfileState(player: Player): boolean
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save state for: ", player)
		return false
	end

	local success = pcall(function()
		profile:Save()
	end)

	if success then
		FFGHelpers.PrintLog("Successfully saved profile for: ", player.Name)
	else
		FFGHelpers.PrintLog("Failed to save profile for: ", player.Name)
	end

	return success
end

function DataManager.ResetAllPlayerData(player: Player)
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to reset data for: ", player)
		return
	end

	DataManager.ClearProfileData(player, profile)
	DataManager.DetachReplica(player)

	DataManager.CreateNewProfileData(player, profile)
	DataManager.AttachReplica(player, profile)
end

return DataManager
