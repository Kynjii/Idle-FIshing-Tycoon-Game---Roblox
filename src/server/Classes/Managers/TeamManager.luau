local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local Teams = game:GetService("Teams")
local ChainManager = require(script.Parent.ChainManager)
local ChainManagerType = require(ServerScriptService.Server.Classes.Types.ChainManagerType)

type BoatInstance = BoatType.BoatInstance
type Tender = TenderType.Tender
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
		TeamColor = BrickColor.new("New yeller"),
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

function TeamManager.CreateTeams()
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

function TeamManager.AssignChainManagers(profile, player: Player, teamId: number)
	TeamManager.ChainManagers[player.UserId] = TeamManager.ChainManagers[player.UserId] or { OwnerId = player.UserId }
	local currentRealmId = profile.CurrentRealm
	local realmData = profile.Realms[currentRealmId]

	if not realmData then return end

	for lane = 1, realmData.Lanes do
		local ChainManager: ChainManager = ChainManager.New(realmData, lane, player, teamId)
		if not ChainManager then break end

		table.insert(TeamManager.ChainManagers[player.UserId], ChainManager)
		ChainManager:Initialize()
	end
end

function TeamManager.AssignTeam(player: Player)
	local teams = Teams:GetTeams()
	for i, team in ipairs(teams) do
		local playersOnTeam = team:GetPlayers()
		if #playersOnTeam == 0 then
			player.TeamColor = team.TeamColor
			player.Neutral = false
			return i
		end
	end

	return nil
end

function TeamManager.CleanupPlayer(userId: number)
	local list = TeamManager.ChainManagers[userId]
	if not list then return end

	for i = #list, 1, -1 do
		local manager = list[i]
		if typeof(manager) == "table" and manager.Destroy then
			local ok, err = pcall(function()
				manager:Destroy()
			end)
			if not ok then warn("[TeamManager] Manager destroy error:", err) end
		end
		list[i] = nil
	end
	TeamManager.ChainManagers[userId] = nil
end

return TeamManager
