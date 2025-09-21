local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.Server.Libs.ProfileStore)
local TeamManager = require(ServerScriptService.Server.Classes.Managers.TeamManager)
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local MusicManager = require(ServerScriptService.Server.Music.MusicManager)
local DataService = require(ServerScriptService.Server.Services.DataService)

-- //SECTION - Game Start
-- Create Teams based on static data and kick someone if the team has more than one player
TeamManager.CreateTeams()

-- Create new Playerstore using the PlayerDataTemplate
local PlayerStore = ProfileStore.New(FFGHelpers.GetStoreName(), PlayerDataTemplate)

-- Create a replica of state so the client has access to it
local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	DataService.AttachReplica(player, profile)
end

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			DataService.Profiles[player] = nil
			DataService.DetachReplica(player)
		end)

		if player.Parent == Players then
			DataService.Profiles[player] = profile
			Initialize(player, profile)

			local teamId = TeamManager.AssignTeam(player)
			if not teamId then
				player:Kick("Server is full, try again")
				return
			end

			TeamManager.AssignBuildingsManager(profile.Data, player, teamId)
			TeamManager.AssignChainManagers(profile.Data, player, teamId)
		else
			profile:EndSession()
		end
	else
		player:Kick("Data error occured, please rejoin.")
	end
end

for _, p in Players:GetPlayers() do
	task.spawn(PlayerAdded, p)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	pcall(function()
		TeamManager.CleanupPlayer(player.UserId)
	end)

	local profile = DataService.Profiles[player]
	if profile then
		profile:EndSession()

		task.delay(1, function()
			DataService.Profiles[player] = nil
		end)
	end
	DataService.DetachReplica(player)
end)

-- Start music
MusicManager.LoadMusic()

-- Load Animations
Animator.LoadAnimations()
