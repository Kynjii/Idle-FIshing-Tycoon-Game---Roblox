local ServerScriptService = game:GetService("ServerScriptService")
local BoatType = require(ServerScriptService.Server.Classes.Types.BoatType)
local TenderType = require(ServerScriptService.Server.Classes.Types.TenderType)
local Teams = game:GetService("Teams")
local BoatManager = require(script.Parent.BoatManager)
local BoatManagerType = require(ServerScriptService.Server.Classes.Types.BoatManagerType)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)

type BoatInstance = BoatType.BoatInstance
type Tender = TenderType.Tender
type ProfileData = PlayerDataTemplate.ProfileData
type BoatManager = BoatManagerType.BoatManagerInstance

local TeamManager = {}
TeamManager.Teams = {
	[1] = {
		Name = "Islander 1",
		TeamColor = BrickColor.new("Bright Red"),
	},
	[2] = {
		Name = "Islander 2",
		TeamColor = BrickColor.new("Really Red"),
	},
	[3] = {
		Name = "Islander 3",
		TeamColor = BrickColor.new("Bright Blue"),
	},
	[4] = {
		Name = "Islander 4",
		TeamColor = BrickColor.new("Really Blue"),
	},
	[5] = {
		Name = "Islander 5",
		TeamColor = BrickColor.new("Earth Green"),
	},
	[6] = {
		Name = "Islander 6",
		TeamColor = BrickColor.new("Dark Green"),
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
		TeamColor = BrickColor.new("Deep Orange"),
	},
	[10] = {
		Name = "Islander 10",
		TeamColor = BrickColor.new("Cork"),
	},
}

TeamManager.BoatManagers = {}

function TeamManager.CreateTeams()
	for i, team in ipairs(TeamManager.Teams) do
		local newTeam = Instance.new("Team")
		newTeam.TeamColor = team.TeamColor
		newTeam.Name = team.Name
		newTeam.AutoAssignable = true
		newTeam.Parent = Teams

		newTeam.PlayerAdded:Connect(function(player)
			local playersOnTeam = #newTeam:GetPlayers()
			-- //TODO - Attempt to re-assign first
			if playersOnTeam > 1 then player:Kick("The server is full, try again.") end
		end)
	end
end

function TeamManager.AssignBoatManagers(profile: ProfileData, player: Player)
	TeamManager.BoatManagers[player] = {
		OwnerId = player.UserId,
	}
	local currentRealmId = profile.CurrentRealm
	local realmData = profile.Realms[currentRealmId]

	if realmData then
		local numOfLanes = realmData.Lanes
		for i = 1, numOfLanes, 1 do
			local boatManager: BoatManager = BoatManager.New(realmData.Boats, realmData.Tenders, i, player)

			if not boatManager then break end
			table.insert(TeamManager.BoatManagers[player], boatManager)
			boatManager:Initialize()
		end
	end
end

return TeamManager
