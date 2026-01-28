_G.__DEV__ = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local IsStudio = RunService:IsStudio()
if IsStudio then
    _G.__DEV__ = true
end

local Events = require(ReplicatedStorage.Shared.Events.Events)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local PlayerDataTemplate = require(ServerScriptService.Server.Modules.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.Server.Libs.ProfileStore)
local TeamManager = require(ServerScriptService.Server.Classes.Managers.TeamManager)
local FishCalculators = require(ServerScriptService.Server.Classes.Modules.FishCalculators)
local FishingRods = require(ServerScriptService.Server.Data.FishingRods)
local Tutorial = require(ServerScriptService.Server.Game.Tutorial.Tutorial)
local Badges = require(ServerScriptService.Server.Modules.Badges.Badges)
local MusicManager = require(ServerScriptService.Server.Music.MusicManager)
local PlayerStateService = require(ServerScriptService.Server.PlayerState.PlayerStateService)
local PlayerStateSyncService = require(ServerScriptService.Server.PlayerState.PlayerStateSyncService)
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

local function updateTools()
    local fishTemplate = ServerStorage.FishTools:WaitForChild("FishTemplate")
    for _, fish in pairs(FishCalculators.GetAllFishVariations(1)) do
        local fishSpeciesKey = fish.SpeciesKey
        if ServerStorage.FishTools:FindFirstChild(fishSpeciesKey) then
            local fishTool = ServerStorage.FishTools[fishSpeciesKey]
            fishTool.TextureId = fish.ItemImage
            fishTool.ToolTip = fish.Species
            fishTool.RequiresHandle = true
            fishTool.CanBeDropped = true
        else
            -- //TODO - Remove once models are in-game
            local tempTool = fishTemplate:Clone()
            tempTool.Name = fish.SpeciesKey
            tempTool.TextureId = fish.ItemImage
            tempTool.ToolTip = fish.Species
            tempTool.RequiresHandle = true
            tempTool.CanBeDropped = true
            tempTool.Parent = ServerStorage.FishTools
        end
    end

    local rodTemplate = ServerStorage.RodTools:WaitForChild("RodTemplate") :: Instance
    for _, rod in pairs(FishingRods) do
        local rodTool = rodTemplate:Clone() :: Tool

        for _, part in pairs(rodTool:GetChildren()) do
            part.Color = rod.Color
        end

        rodTool.Name = rod.Id
        rodTool.TextureId = rod.ItemImage
        rodTool.ToolTip = rod.Name
        rodTool.RequiresHandle = true
        rodTool.CanBeDropped = false
        rodTool.Parent = ServerStorage.RodTools
    end
end
updateTools()

local function initPlayerState(player: Player, profile)
    local playerAtoms = PlayerStateService:InitPlayer(player, profile)
    PlayerStateSyncService:ConnectPlayer(player)

    return playerAtoms
end

local function handleTutorial(profile, teamId: number, player: Player)
    local completedTutorial = profile.Data and profile.Data.CompletedTutorial or false
    if not completedTutorial then
        local stageProgress
        for i, completed in ipairs(profile.Data.TutorialStageComplete) do
            if not completed then
                stageProgress = i
                break
            end
        end

        if stageProgress then
            Tutorial.Show(player, teamId, stageProgress)
        end
    end
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
            local teamId = TeamManager.AssignTeam(player)
            if not teamId then
                player:Kick("Server is full, try again")
                return
            end

            DataService.Profiles[player] = profile
            Initialize(player, profile)
            initPlayerState(player, profile)
            addPlayerToLeaderboard(player, profile.Data)
            handleTutorial(profile, teamId, player)

            TeamManager.AssignManagers(profile, player, teamId)

            Badges.CheckAlphaBadgeStatus(player)

            Events.FireEvent(Events.RemoteNames.PlayerAssigned, player)
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
        task.delay(2, function()
            profile:EndSession()
        end)
    end

    PlayerStateService:RemovePlayer(player)
end)

-- Start music
MusicManager.LoadMusic()
