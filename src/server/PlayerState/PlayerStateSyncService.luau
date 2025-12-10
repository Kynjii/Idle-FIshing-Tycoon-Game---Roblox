local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local CharmPackets = require(ReplicatedStorage.Shared.Networking.CharmSyncPackets)

local PlayerStateService = require(script.Parent.PlayerStateService)

local PlayerStateSyncService = {}

function PlayerStateSyncService:ConnectPlayer(player)
    local atoms = PlayerStateService:Get(player)

    local syncer = CharmSync.server({
        atoms = atoms,
        preserveHistory = false,
        autoSerialize = false,
    })

    syncer:connect(function(plr, state)
        CharmPackets.StateUpdate.sendTo({
            message = state,
        }, plr)
    end)

    CharmPackets.RequestHydrate.listen(function(data, plr)
        if plr == player then
            syncer:hydrate(plr)
        end
    end)
end

return PlayerStateSyncService
