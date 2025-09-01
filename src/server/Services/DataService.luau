local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGTypes = require(ReplicatedStorage.Shared.Types.FFGTypes)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local Replica = require(ServerScriptService.Server.ReplicaServer)
local PlayerStateToken = Replica.Token("PlayerState")

local DataService = {}
DataService.Profiles = {}
DataService.Replicas = {}

function DataService.AttachReplica(player: Player, profile)
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
	DataService.Replicas[player] = replica
	return replica
end

function DataService.DetachReplica(player: Player)
	FFGHelpers.PrintLog("Detaching Replica for: ", player)
	local replica = DataService.Replicas[player]
	if replica then
		replica:Destroy()
		DataService.Replicas[player] = nil
	end
end

function DataService.Earn(player: Player, currencyType: string, amount: number)
	local profile = DataService.Profiles[player]
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

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end
end

function DataService.CanAfford(player: Player, currencyType: string, amount: number)
	local profile = DataService.Profiles[player]
	if not profile then return end
	return (tonumber(profile.Data.Currencies[currencyType]) or 0) >= amount
end

function DataService.Spend(player: Player, currencyType: string, amount: number)
	local profile = DataService.Profiles[player]
	if not profile then return end
	if typeof(amount) ~= "number" or amount <= 0 then return end
	if typeof(currencyType) ~= "string" then return end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	if current < amount then return end

	local newValue = current - amount
	profile.Data.Currencies[currencyType] = newValue

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end
end

function DataService.ClearProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to clear profile data for: ", player)
		return
	end

	profile.Data = nil

	FFGHelpers.PrintLog("Cleared Profile Data: ", profile)
end

function DataService.CreateNewProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to create new profile data for: ", player)
		return
	end

	local resetDataTemplate = TableUtil.Copy(PlayerDataTemplate, true)
	profile.Data = resetDataTemplate

	FFGHelpers.PrintLog("Created Profile Data: ", profile)
end

function DataService.SaveBoatState(player: Player, boatId: string, newState: FFGTypes.BoatState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save boat state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:" .. currentRealm)
		return false
	end

	if not profile.Data.Realms[currentRealm].Boats then
		FFGHelpers.PrintLog("No data structure found for boats in Realm:" .. currentRealm)
		return false
	end

	local existingBoat = TableUtil.Find(profile.Data.Realms[currentRealm].Boats, function(boat)
		return boat[FFGEnum.ATTRIBUTES.BOAT.Id] == boat[FFGEnum.ATTRIBUTES.BOAT.Id]
	end)

	if not existingBoat then
		profile.Data.Realms[currentRealm].Boats[newState] = newState
	else
		profile.Data.Realms[currentRealm].Boats[existingBoat] = newState
	end

	FFGHelpers.PrintLog("Saved boat state for player", player.Name, "boat", boatId)
	return true
end

-- //TODO - Figure out with boatstate function to use when multiple is needed
function DataService.GetBoatState(profile): FFGTypes.BoatState?
	if not profile or not profile.Data then return nil end
	local currentRealm = profile.Data.CurrentRealm or 1

	if not profile.Data.Realms then return nil end
	if not profile.Data.Realms[currentRealm] then return nil end
	if not profile.Data.Realms[currentRealm].Boats then return nil end

	return profile.Data.Realms[currentRealm].Boats
end

function DataService.LoadBoatState(player: Player): FFGTypes.BoatState?
	FFGHelpers.PrintLog("Attempting to load boat state for: ", player)
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found for: ", player)
		return nil
	end

	local state = DataService.GetBoatState(profile)
	if not state then
		FFGHelpers.PrintLog("Unable to get BoatState for loading")
		return nil
	end

	FFGHelpers.PrintLog("Current boat state: ", state)
	return state
end

function DataService.ResetAllPlayerData(player: Player)
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to reset data for: ", player)
		return
	end

	DataService.ClearProfileData(player, profile)
	DataService.DetachReplica(player)

	DataService.CreateNewProfileData(player, profile)
	DataService.AttachReplica(player, profile)
end

return DataService
