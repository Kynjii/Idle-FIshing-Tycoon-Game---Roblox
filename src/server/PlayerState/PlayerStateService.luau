--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local PlayerStateService = {}
PlayerStateService.State = {}

local function createState(profile)
    return {
        Gold = Charm.atom(profile.Data.Currencies.Gold or 0),
        SelectedRod = Charm.atom(nil),
        SelectedMenuTab = Charm.atom("Fishing"),
    }
end

function PlayerStateService:InitPlayer(player, profile)
    local state = createState(profile)
    self.State[player] = state
    return state
end

function PlayerStateService:Get(player): { [any]: any }
    return self.State[player]
end

function PlayerStateService:RemovePlayer(player)
    self.State[player] = nil
end

return PlayerStateService
