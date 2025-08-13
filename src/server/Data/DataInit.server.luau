local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataTemplate = require(ServerScriptService.Server.Data.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.Server.Libs.ProfileStore)
local DataManager = require(ServerScriptService.Server.Data.DataManager)

local function GetStoreName()
	return RunService:IsStudio() and "Staging" or "Live"
end

local PlayerStore = ProfileStore.New(GetStoreName(), PlayerDataTemplate)

local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	-- Leaderstats (optional but nice for the default leaderboard)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Gold = Instance.new("NumberValue")
	Gold.Name = "Gold"
	Gold.Value = profile.Data.Gold or 0
	Gold.Parent = leaderstats

	DataManager.AttachReplica(player, profile)
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
			DataManager.Profiles[player] = nil
			DataManager.DetachReplica(player)
			player:Kick("Data error occured, please rejoin.")
		end)

		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)
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
	local profile = DataManager.Profiles[player]
	if profile then
		profile:EndSession()
		DataManager.Profiles[player] = nil
	end
	DataManager.DetachReplica(player)
end)
