local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local BuildingsManager = require(script.Parent.BuildingsManager)
local ChainManager = require(script.Parent.ChainManager)
local HelperShopManager = require(script.Parent.HelperShopManager)
local InventoryManager = require(script.Parent.InventoryManager)
local JobManager = require(script.Parent.JobManager)
local BuildingsManagerType = require(ReplicatedStorage.Shared.Types.Managers.BuildingsManagerType)
local ChainManagerType = require(ReplicatedStorage.Shared.Types.Managers.ChainManagerType)

type BuildingsManager = BuildingsManagerType.BuildingsManagerInstance
type ChainManager = ChainManagerType.ChainManagerInstance

local TeamManager = {}
TeamManager.Teams = {
	[1] = {
		Name = "Islander 1",
		TeamColor = BrickColor.new("Bright red"),
	},
	[2] = {
		Name = "Islander 2",
		TeamColor = BrickColor.new("Really red"),
	},
	[3] = {
		Name = "Islander 3",
		TeamColor = BrickColor.new("Bright blue"),
	},
	[4] = {
		Name = "Islander 4",
		TeamColor = BrickColor.new("Really blue"),
	},
	[5] = {
		Name = "Islander 5",
		TeamColor = BrickColor.new("Earth green"),
	},
	[6] = {
		Name = "Islander 6",
		TeamColor = BrickColor.new("Dark green"),
	},
	[7] = {
		Name = "Islander 7",
		TeamColor = BrickColor.new("Mint"),
	},
	[8] = {
		Name = "Islander 8",
		TeamColor = BrickColor.new("New Yeller"),
	},
	[9] = {
		Name = "Islander 9",
		TeamColor = BrickColor.new("Deep orange"),
	},
	[10] = {
		Name = "Islander 10",
		TeamColor = BrickColor.new("Cork"),
	},
}

TeamManager.ChainManagers = {}
TeamManager.BuildingsManager = {}
TeamManager.HelperShopManager = {}
TeamManager.InventoryManager = {}
TeamManager.JobManager = {}

function TeamManager.CreateTeams(): ()
	for i, team in ipairs(TeamManager.Teams) do
		local newTeam = Instance.new("Team")
		newTeam.TeamColor = team.TeamColor
		newTeam.Name = team.Name
		newTeam.AutoAssignable = false
		newTeam.Parent = Teams

		newTeam.PlayerAdded:Connect(function(player)
			local playersOnTeam = newTeam:GetPlayers()
			if #playersOnTeam > 1 then player:Kick("The server is full, try again.") end
		end)
	end
end

function TeamManager.AssignChainManagers(profile, player: Player, teamId: number): ()
	TeamManager.ChainManagers[player.UserId] = TeamManager.ChainManagers[player.UserId] or { OwnerId = player.UserId }
	local currentRealmId = profile.CurrentRealm
	local realmData = profile.Realms[currentRealmId]

	if not realmData then return end
	local buildingClasses = TeamManager.BuildingsManager[player.UserId] and TeamManager.BuildingsManager[player.UserId].Buildings or {}
	for lane = 1, realmData.Lanes do
		local chainManager: ChainManager = ChainManager.New(realmData, lane, player, teamId, buildingClasses)
		if not chainManager then break end

		table.insert(TeamManager.ChainManagers[player.UserId], chainManager)
		chainManager:Initialize()
	end
end

function TeamManager.AssignBuildingsManager(profile, player: Player, teamId: number): ()
	TeamManager.BuildingsManager[player.UserId] = TeamManager.BuildingsManager[player.UserId] or { OwnerId = player.UserId }
	local currentRealmId = profile.CurrentRealm
	local realmData = profile.Realms[currentRealmId]

	if not realmData then return end

	local buildingsManager: BuildingsManager = BuildingsManager.New(realmData, player, teamId)
	if not buildingsManager then return end

	TeamManager.BuildingsManager[player.UserId] = buildingsManager
	buildingsManager:Initialize()
end

function TeamManager.AssignHelperShopManager(profile, player: Player, teamId: number): ()
	TeamManager.HelperShopManager[player.UserId] = TeamManager.HelperShopManager[player.UserId] or { OwnerId = player.UserId }
	local currentRealm = profile.CurrentRealm or 1
	local realmData = profile and profile.Realms[currentRealm]

	local shopState = realmData.Shops["HelperShop"] or nil

	local helperShopManager = HelperShopManager.New(shopState, player, teamId)
	if not helperShopManager then return end

	TeamManager.HelperShopManager[player.UserId] = helperShopManager
	helperShopManager:Initialize()
end

function TeamManager.AssignInventoryManager(profile, player: Player, teamId: number): ()
	TeamManager.InventoryManager[player.UserId] = TeamManager.InventoryManager[player.UserId] or { OwnerId = player.UserId }
	local currentRealm = profile.CurrentRealm or 1
	local realmData = profile and profile.Realms[currentRealm]

	local playerInventoryState = realmData.Helpers or {}

	local inventoryManager = InventoryManager.New(playerInventoryState, player, teamId)
	if not inventoryManager then return end

	TeamManager.InventoryManager[player.UserId] = inventoryManager
end

function TeamManager.AssignJobManager(profile, player: Player, teamId: number): ()
	TeamManager.JobManager[player.UserId] = TeamManager.JobManager[player.UserId] or { OwnerId = player.UserId }
	local currentRealm = profile.CurrentRealm or 1
	local realmData = profile and profile.Realms[currentRealm]

	local playerHelperState = realmData.Helpers or {}
	local playerJobState = realmData.Jobs or {}

	local jobManager = JobManager.New(playerHelperState, playerJobState, player, teamId)
	if not jobManager then return end

	TeamManager.JobManager[player.UserId] = jobManager
end

function TeamManager.AssignTeam(player: Player): number?
	local teams = Teams:GetTeams()
	for i, team in ipairs(teams) do
		local playersOnTeam = team:GetPlayers()
		if #playersOnTeam == 0 then
			player.TeamColor = team.TeamColor
			player.Neutral = false

			player:LoadCharacter()
			Events.FireEvent(Events.RemoteNames.PlayerReady, player)
			return i
		end
	end

	return nil
end

function TeamManager.AssignManagers(profile, player: Player, teamId: number): ()
	TeamManager.AssignBuildingsManager(profile.Data, player, teamId)
	TeamManager.AssignChainManagers(profile.Data, player, teamId)
	TeamManager.AssignHelperShopManager(profile.Data, player, teamId)
	TeamManager.AssignInventoryManager(profile.Data, player, teamId)
	TeamManager.AssignJobManager(profile.Data, player, teamId)
end

local managerTypes = {
	Chain = "Chain",
	Building = "Building",
	Shop = "Shop",
	Inventory = "Inventory",
	Job = "Job",
}

local function listClean(list, userId, managerType): ()
	for i = #list, 1, -1 do
		local manager = list[i]
		if typeof(manager) == "table" and manager.Destroy then
			local ok, err = pcall(function()
				manager:Destroy()
			end)
			if not ok then warn("[TeamManager] destroy error:", err) end
		end
		list[i] = nil
	end

	if managerType == managerTypes.Chain then
		TeamManager.ChainManagers[userId] = nil
	elseif managerType == managerTypes.Building then
		TeamManager.BuildingsManager[userId] = nil
	elseif managerType == managerTypes.Shop then
		TeamManager.HelperShopManager[userId] = nil
	elseif managerType == managerTypes.Inventory then
		TeamManager.InventoryManager[userId] = nil
	elseif managerType == managerTypes.Job then
		TeamManager.JobManager[userId] = nil
	end
end

function TeamManager.CleanupPlayer(userId: number): ()
	local chainList = TeamManager.ChainManagers[userId]
	local buildingList = TeamManager.BuildingsManager[userId]
	local helperShopList = TeamManager.HelperShopManager[userId]
	local inventoryList = TeamManager.InventoryManager[userId]
	local jobList = TeamManager.JobManager[userId]

	if chainList then listClean(chainList, userId, managerTypes.Chain) end
	if buildingList then listClean(buildingList, userId, managerTypes.Building) end
	if helperShopList then listClean(helperShopList, userId, managerTypes.Shop) end
	if inventoryList then listClean(inventoryList, userId, managerTypes.Inventory) end
	if jobList then listClean(jobList, userId, managerTypes.Job) end
end

export type TeamManager = typeof(TeamManager)

return TeamManager
