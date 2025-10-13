local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.Server.Libs.ProfileStore)
local TeamManager = require(ServerScriptService.Server.Classes.Managers.TeamManager)
local Animator = require(ServerScriptService.Server.Classes.Modules.Animator)
local Badges = require(ServerScriptService.Server.Modules.Badges.Badges)
local MusicManager = require(ServerScriptService.Server.Music.MusicManager)
local DataService = require(ServerScriptService.Server.Services.DataService)

-- //SECTION - Game Start

-- Create Remotes
Events.InitOnServer()

-- Create Teams based on static data and kick someone if the team has more than one player
TeamManager.CreateTeams()

-- Setup leaderboard
local function addPlayerToLeaderboard(player, playerData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = playerData.Currencies.Gold or 0
	gold.Parent = leaderstats

	local isPrimary = Instance.new("BoolValue")
	isPrimary.Name = "IsPrimary"
	isPrimary.Value = true
	isPrimary.Parent = gold
end

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

			addPlayerToLeaderboard(player, profile.Data)

			TeamManager.AssignBuildingsManager(profile.Data, player, teamId)
			TeamManager.AssignChainManagers(profile.Data, player, teamId)

			Badges.CheckAlphaBadgeStatus(player)
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
