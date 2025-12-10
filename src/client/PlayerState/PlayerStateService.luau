local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)

local PlayerStateService = {}

PlayerStateService.State = {
    Gold = Charm.atom(0),
    SelectedRod = Charm.atom(nil),
    SelectedMenuTab = Charm.atom("Fishing"),
}

function PlayerStateService:Get()
    return self.State
end

return PlayerStateService
