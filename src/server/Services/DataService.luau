local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Analytics.Economy)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local Replica = require(ServerScriptService.Server.ReplicaServer)
local PlayerStateToken = Replica.Token("PlayerState")

local DataService = {}
DataService.Profiles = {}
DataService.Replicas = {}

type ReplicaType = Replica.Replica

local stateTypes = {
	SaveBuff = "save Buff",
	GetBuff = "get Buff",
	Boat = "save Boat",
	Tender = "save Tender",
	Building = "save Building",
	PortStorage = "save PortStorage",
	Item = "save Item",
	Helper = "save Helper",
	SaveTutorialState = "save Tutorial",
	CompletedTutorial = "complete Tutorial",
	GetTutorialState = "get Tutorial",
	ResetData = "Reset",
	HelperShop = "save Helper Shop",
	getPlayerInventory = "get Player Inventory",
	SaveJobState = "save Job State",
	GetJobState = "get Job State",
	SaveFish = "save Fish",
	SaveFishDex = "save Fish Dex",
}

local function getProfile(player: Player, stateType: string): any | boolean
	local profile = DataService.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog(`No profile found when attempting to {stateType} state for: {player}`)
		return false
	end

	return profile
end

local function getRealms(profile): boolean
	if not profile.Data.Realms then
		FFGHelpers.PrintLog("No Realms data structure found")
		return false
	end

	return true
end

local function getRealmData(profile): number | boolean
	local currentRealm = profile.Data.CurrentRealm or 1
	if not profile.Data.Realms[currentRealm] then
		FFGHelpers.PrintLog("No data structure found for Realm:", currentRealm)
		return false
	end

	return currentRealm
end

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
	}) :: ReplicaType

	if replica.ReadyPlayers[player] then
		replica:Subscribe(player)
	else
		local connection
		connection = replica.NewReadyPlayer:Connect(function(readyPlayer)
			if readyPlayer == player then
				replica:Subscribe(player)
				connection:Disconnect()
			end
		end)
	end

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

local function calculateBuffedAmount(player, amount)
	local validBuffs = {
		["Gold_Multi"] = "Gold_Multi",
		["Fish_Multi"] = "Fish_Multi",
		["Fish_Percent"] = "Fish_Percent",
	}

	local buffState = DataService.GetBuffState(player, validBuffs)

	local fishPercent: number? = buffState["Fish_Percent"] and buffState["Fish_Percent"].CurrentValue or nil
	local fishMulti: number? = buffState["Fish_Multi"] and buffState["Fish_Multi"].CurrentValue or nil
	local goldMulti: number? = buffState["Gold_Multi"] and buffState["Gold_Multi"].CurrentValue or nil

	local buffedAmount: number = amount
	if fishPercent then
		local percentValue: number = amount * fishPercent
		buffedAmount += percentValue
		print("w/ fish percent", buffedAmount)
	end

	if fishMulti then
		buffedAmount *= fishMulti
		print("w/ fish multi", buffedAmount)
	end

	if goldMulti then
		buffedAmount *= goldMulti
		print("w/ gold multi", buffedAmount)
	end

	return buffedAmount
end

function DataService.Earn(player: Player, currencyType: "Gold", amount: number)
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
	local buffedDiff = calculateBuffedAmount(player, amount)

	local newValue = current + buffedDiff
	profile.Data.Currencies[currencyType] = newValue

	Economy.Log(player, Economy.FlowType.CurrencyAdd, currencyType, amount, newValue, Economy.TransactionType.Gameplay)

	local leaderStats = player:FindFirstChild("leaderstats")
	local currency = leaderStats:FindFirstChild(currencyType)

	if currency then currency.Value = newValue end

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end

	Events.FireBindableEvent(Events.BindableNames.UpdateState, player)
	Events.FireEvent(Events.RemoteNames.LootNotification, player, { ItemType = currencyType, Text = Format.CurrencyNumber(amount) })
end

function DataService.CanAfford(player: Player, currencyType: "Gold", amount: number)
	local profile = DataService.Profiles[player]
	if not profile then return end

	return (tonumber(profile.Data.Currencies[currencyType]) or 0) >= amount
end

function DataService.Spend(player: Player, currencyType: "Gold", amount: number)
	local profile = DataService.Profiles[player]
	if not profile then return end
	if typeof(amount) ~= "number" or amount <= 0 then return end
	if typeof(currencyType) ~= "string" then return end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	if current < amount then return end

	local newValue = current - amount
	profile.Data.Currencies[currencyType] = newValue

	Economy.Log(player, Economy.FlowType.CurrencyRemove, currencyType, amount, newValue, Economy.TransactionType.Gameplay)

	local leaderStats = player:FindFirstChild("leaderstats")
	local currency = leaderStats:FindFirstChild(currencyType)

	if currency then currency.Value = newValue end

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Currencies", currencyType }, newValue) end

	Events.FireBindableEvent(Events.BindableNames.UpdateState, player)
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
	local profile = getProfile(player, stateTypes.Boat)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Boats array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Boats then profile.Data.Realms[currentRealm].Boats = {} end

	profile.Data.Realms[currentRealm].Boats[boatId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Boats", boatId }, newState) end

	return true
end
-- //!SECTION

-- //SECTION - TENDERS
function DataService.SaveTenderState(player: Player, tenderId: string, newState): boolean
	local profile = getProfile(player, stateTypes.Tender)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Tenders array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Tenders then profile.Data.Realms[currentRealm].Tenders = {} end

	profile.Data.Realms[currentRealm].Tenders[tenderId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Tenders", tenderId }, newState) end

	return true
end
-- //!SECTION

-- //SECTION - STORAGE UNITS
function DataService.SaveStorageState(player: Player, storageId: string, newState): boolean
	local profile = getProfile(player, stateTypes.PortStorage)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Storage array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Storages then profile.Data.Realms[currentRealm].Storages = {} end

	profile.Data.Realms[currentRealm].Storages[storageId] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Storages", storageId }, newState) end

	return true
end
-- //!SECTION

-- //SECTION - BUILDINGS
function DataService.SaveBuildingState(player: Player, newState: BuildingType.BuildingInstance): boolean
	local profile = getProfile(player, stateTypes.Building)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Buildings array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buildings then profile.Data.Realms[currentRealm].Buildings = {} end

	profile.Data.Realms[currentRealm].Buildings[newState.Id] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Buildings", newState.Id }, newState) end

	return true
end
-- //!SECTION

-- //SECTION - BUFFS
function DataService.SaveBuffState(player: Player, newState: { [string]: number }): boolean
	local profile = getProfile(player, stateTypes.SaveBuff)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Buffs array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Buffs then profile.Data.Realms[currentRealm].Buffs = {} end

	profile.Data.Realms[currentRealm].Buffs[newState.Name] = newState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Buffs", newState.Name }, newState) end

	return true
end

function DataService.GetBuffState(player: Player, buffNames: { string }): { [string]: any } | boolean
	local profile = getProfile(player, stateTypes.GetBuff)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	if not profile.Data.Realms[currentRealm].Buffs then return false end

	local buffs = {}
	for k, v in pairs(buffNames) do
		buffs[k] = profile.Data.Realms[currentRealm].Buffs[k] or nil
	end

	return buffs
end
-- //!SECTION

-- //SECTION - HELPER
function DataService.SaveHelper(player: Player, helper: HelperType.HelperData): boolean
	local profile = getProfile(player, stateTypes.Helper)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Helpers array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Helpers then profile.Data.Realms[currentRealm].Helpers = {} end

	profile.Data.Realms[currentRealm].Helpers[helper.Id] = helper

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Helpers" }, profile.Data.Realms[currentRealm].Helpers) end

	return true
end
-- //!SECTION

-- //SECTION - SHOPS
function DataService.SaveHelperShop(player: Player, shopState: { [string]: any })
	local profile = getProfile(player, stateTypes.HelperShop)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize HelperShop array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Shops then profile.Data.Realms[currentRealm].Shops = {} end

	profile.Data.Realms[currentRealm].Shops["HelperShop"] = shopState

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "Shops" }, profile.Data.Realms[currentRealm].Shops) end

	return true
end
-- //!SECTION

-- //SECTION - INVENTORY
function DataService.GetPlayerInventory(player: Player)
	local profile = getProfile(player, stateTypes.getPlayerInventory)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Inventory array if it doesn't exist
	-- //TODO - Replace with proper inventory (temp)
	-- if not profile.Data.Realms[currentRealm].Shops then profile.Data.Realms[currentRealm].Shops = {} end

	return profile.Data.Realms[currentRealm].Helpers
end
-- //!SECTION

-- //SECTION - TUTORIAL
function DataService.SaveTutorialState(player: Player, completedStage: number): ()
	local profile = getProfile(player, stateTypes.SaveTutorialState)
	if not profile then return end
	if completedStage == 4 then
		profile.Data.TutorialStageComplete[completedStage] = true
		profile.Data.CompletedTutorial = true
	end

	profile.Data.TutorialStageComplete[completedStage - 1] = true
end

function DataService.CompletedTutorial(player: Player): boolean
	local profile = getProfile(player, stateTypes.CompletedTutorial)
	if not profile then return false end

	return profile.Data.CompletedTutorial
end

function DataService.CurrentTutorialStage(player: Player): number?
	local profile = getProfile(player, stateTypes.GetTutorialState)
	if not profile then return nil end

	local currentStage = nil
	for i, stage in ipairs(profile.Data.TutorialStageComplete) do
		if stage then currentStage = i end
	end

	return currentStage
end
-- //!SECTION

-- //SECTION - JOBS
function DataService.SaveJobState(player: Player, jobState: Jobs.JobState, skipEvent: boolean)
	local profile = getProfile(player, stateTypes.SaveJobState)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Jobs array if it doesn't exist
	if not profile.Data.Realms[currentRealm].Jobs then profile.Data.Realms[currentRealm].Jobs = Jobs.Data end

	profile.Data.Realms[currentRealm].Jobs[jobState.Id] = jobState

	if not skipEvent then Events.FireEvent(Events.RemoteNames.UpdateJobManagementUI, player) end

	return true
end

function DataService.GetJobState(player: Player, jobId: number): Jobs.JobState
	local profile = getProfile(player, stateTypes.GetJobState)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	if not profile.Data.Realms[currentRealm].Jobs then return false end

	return profile.Data.Realms[currentRealm].Jobs[jobId]
end
-- //!SECTION

-- //SECTION - Fish Inventory
function DataService.SaveFish(player: Player, fish): boolean
	local profile = getProfile(player, stateTypes.SaveFish)
	if not profile then return false end

	local hasRealms = getRealms(profile)
	if not hasRealms then return false end

	local currentRealm = getRealmData(profile)
	if not currentRealm then return false end

	-- Initialize Fish Inventory array if it doesn't exist
	if not profile.Data.Realms[currentRealm].FishInventory then profile.Data.Realms[currentRealm].FishInventory = {} end

	profile.Data.Realms[currentRealm].FishInventory[fish.Id] = fish

	local replica = DataService.Replicas[player]
	if replica then replica:Set({ "Realms", currentRealm, "FishInventory" }, profile.Data.Realms[currentRealm].FishInventory) end

	return true
end
-- //!SECTION

-- //SECTION - Fish Dex
function DataService.SaveFishDex(player: Player, fishDexState): boolean
	local profile = getProfile(player, stateTypes.SaveFishDex)
	if not profile then return false end

	-- Initialize Fish Dex array if it doesn't exist
	if not profile.Data.FishDex then profile.Data.FishDex = {} end

	profile.Data.FishDex = fishDexState

	return true
end
-- //!SECTION

function DataService.ResetAllPlayerData(player: Player): boolean
	local profile = getProfile(player, stateTypes.ResetData)
	if not profile then return false end

	DataService.ClearProfileData(player, profile)
	DataService.DetachReplica(player)

	DataService.CreateNewProfileData(player, profile)
	DataService.AttachReplica(player, profile)

	return true
end

return DataService
