local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
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
	local buffs = {}

	for currencyType, amount in pairs(profile.Data.Currencies) do
		currencies[currencyType] = amount or PlayerDataTemplate.Currencies[currencyType]
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	for k, buff in pairs(profile.Data.Realms[currentRealm].Buffs) do
		buffs[k] = buff
	end

	local replica = Replica.New({
		Token = PlayerStateToken,
		Data = {
			Currencies = currencies,
			RealmBuffs = buffs,
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

-- //SECTION - BOATS
function DataService.SaveBoatState(player: Player, boatId: string, newState): boolean
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
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	-- Initialize Boats array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Boats then profile.Data.Realms[currentRealm].Boats = {} end

	local existingBoatIndex = nil
	for i, boat in ipairs(profile.Data.Realms[currentRealm].Boats) do
		if boat[FFGEnum.CLASS.PROPERTIES.Id] == boatId then
			existingBoatIndex = i
			break
		end
	end

	if existingBoatIndex then
		profile.Data.Realms[currentRealm].Boats[existingBoatIndex] = newState
		FFGHelpers.PrintLog("Updated existing boat at index", existingBoatIndex)
	else
		table.insert(profile.Data.Realms[currentRealm].Boats, newState)
		FFGHelpers.PrintLog("Added new boat with ID", boatId)
	end

	FFGHelpers.PrintLog("Saved boat state for player", player.Name, "boat", boatId)
	return true
end
-- //!SECTION

-- //SECTION - TENDERS
function DataService.SaveTenderState(player: Player, tenderId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save tender state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	-- Initialize Tenders array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Tenders then profile.Data.Realms[currentRealm].Tenders = {} end

	local existingStorageIndex = nil
	for i, tender in ipairs(profile.Data.Realms[currentRealm].Tenders) do
		if tender[FFGEnum.CLASS.PROPERTIES.Id] == tenderId then
			existingStorageIndex = i
			break
		end
	end

	if existingStorageIndex then
		profile.Data.Realms[currentRealm].Tenders[existingStorageIndex] = newState
		FFGHelpers.PrintLog("Updated existing tender at index", existingStorageIndex)
	else
		table.insert(profile.Data.Realms[currentRealm].Tenders, newState)
		FFGHelpers.PrintLog("Added new tender with ID", tenderId)
	end

	FFGHelpers.PrintLog("Saved tender state for player", player.Name, "tender", tenderId)
	return true
end
-- //!SECTION

-- //SECTION - STORAGE UNITS
function DataService.SaveStorageState(player: Player, storageId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save tender state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	-- Initialize Storage array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Storages then profile.Data.Realms[currentRealm].Storages = {} end

	local existingStorageIndex = nil
	for i, storage in ipairs(profile.Data.Realms[currentRealm].Storages) do
		if storage[FFGEnum.CLASS.PROPERTIES.Id] == storageId then
			existingStorageIndex = i
			break
		end
	end

	if existingStorageIndex then
		profile.Data.Realms[currentRealm].Storages[existingStorageIndex] = newState
		FFGHelpers.PrintLog("Updated existing tender at index", existingStorageIndex)
	else
		table.insert(profile.Data.Realms[currentRealm].Storages, newState)
		FFGHelpers.PrintLog("Added new tender with ID", storageId)
	end

	FFGHelpers.PrintLog("Saved tender state for player", player.Name, "tender", storageId)
	return true
end
-- //!SECTION

-- //SECTION - BUILDINGS
function DataService.SaveBuildingState(player: Player, buildingId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save building state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	-- Initialize Buildings array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buildings then profile.Data.Realms[currentRealm].Buildings = {} end

	profile.Data.Realms[currentRealm].Buildings[buildingId] = newState
	FFGHelpers.PrintLog("Updated existing building", profile.Data.Realms[currentRealm].Buildings[buildingId])

	return true
end
-- //!SECTION

-- //SECTION - BUFFS
function DataService.SaveBuffState(player: Player, newState: { [string]: number }): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save buff state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	-- Initialize Buffs array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buffs then profile.Data.Realms[currentRealm].Buffs = {} end

	profile.Data.Realms[currentRealm].Buffs[newState.Name] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "RealmBuffs", newState.Name }, newState) end

	FFGHelpers.PrintLog("Saved buff state for player", player.Name, profile.Data.Realms[currentRealm].Buffs)
	return true
end

function DataService.GetBuffState(player: Player, buffNames: { string })
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to get buff state for: ", player)
		return false
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	if not profile.Data.Realms[currentRealm].Buffs then return false end

	local buffs = {}
	for k, v in pairs(buffNames) do
		buffs[k] = profile.Data.Realms[currentRealm].Buffs[k] or nil
	end

	return buffs
end
-- //!SECTION

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
