local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.Server.Libs.ProfileStore)
local TeamManager = require(ServerScriptService.Server.Managers.TeamManager)
local DataService = require(ServerScriptService.Server.Services.DataService)

TeamManager.CreateTeams()

local PlayerStore = ProfileStore.New(FFGHelpers.GetStoreName(), PlayerDataTemplate)

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
			TeamManager.AssignBoatManagers(profile.Data, player)
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
	local profile = DataService.Profiles[player]
	if profile then
		profile:EndSession()

		task.delay(1, function()
			DataService.Profiles[player] = nil
		end)
	end
	DataService.DetachReplica(player)
end)
