local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local Replica = require(ServerScriptService.Server.ReplicaServer)
local PlayerStateToken = Replica.Token("PlayerState")

local DataService = {}
DataService.Profiles = {}
DataService.Replicas = {}

function DataService.AttachReplica(player: Player, profile)
	-- Global
	local currencies = {}
	local globalBuffs = {}
	local realms = {}

	-- Get and store data to be replicated
	-- Curencies
	for currencyType, amount in pairs(profile.Data.Currencies) do
		currencies[currencyType] = amount or PlayerDataTemplate.Currencies[currencyType]
	end

	-- Global Buffs
	for name, value in pairs(profile.Data.GlobalBuffs) do
		globalBuffs[name] = value or nil
	end

	-- Realm Data
	for k, data in ipairs(profile.Data.Realms) do
		realms[k] = data or {}
	end

	local replica = Replica.New({
		Token = PlayerStateToken,
		Data = {
			CurrentRealm = profile.Data.CurrentRealm or 1,
			Currencies = currencies,
			GlobalBuffs = globalBuffs,
			Realms = realms,
		},
	})

	replica:Subscribe(player)
	DataService.Replicas[player] = replica
	return replica
end

function DataService.DetachReplica(player: Player)
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
end

function DataService.CreateNewProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to create new profile data for: ", player)
		return
	end

	local resetDataTemplate = TableUtil.Copy(PlayerDataTemplate, true)
	profile.Data = resetDataTemplate
end

-- //SECTION - BOATS
function DataService.SaveBoatState(player: Player, boatId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save boat state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	-- Initialize Boats array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Boats then profile.Data.Realms[currentRealm].Boats = {} end

	profile.Data.Realms[currentRealm].Boats[boatId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Boats", boatId }, newState) end
end
-- //!SECTION

-- //SECTION - TENDERS
function DataService.SaveTenderState(player: Player, tenderId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save tender state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	-- Initialize Tenders array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Tenders then profile.Data.Realms[currentRealm].Tenders = {} end

	profile.Data.Realms[currentRealm].Tenders[tenderId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Tenders", tenderId }, newState) end
end
-- //!SECTION

-- //SECTION - STORAGE UNITS
function DataService.SaveStorageState(player: Player, storageId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save tender state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	-- Initialize Storage array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Storages then profile.Data.Realms[currentRealm].Storages = {} end

	profile.Data.Realms[currentRealm].Storages[storageId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Storages", storageId }, newState) end
end
-- //!SECTION

-- //SECTION - BUILDINGS
function DataService.SaveBuildingState(player: Player, buildingId: string, newState): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save building state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	-- Initialize Buildings array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buildings then profile.Data.Realms[currentRealm].Buildings = {} end

	profile.Data.Realms[currentRealm].Buildings[buildingId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Buildings", buildingId }, newState) end
end
-- //!SECTION

-- //SECTION - BUFFS
function DataService.SaveBuffState(player: Player, newState: { [string]: number }): boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to save buff state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	-- Initialize Buffs array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buffs then profile.Data.Realms[currentRealm].Buffs = {} end

	profile.Data.Realms[currentRealm].Buffs[newState.Name] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Buffs", newState.Name }, newState) end
end

function DataService.GetBuffState(player: Player, buffNames: { string })
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to get buff state for: ", player)
		return
	end

	-- Ensure the data structure exists
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return
	end

	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return
	end

	if not profile.Data.Realms[currentRealm].Buffs then return end

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
