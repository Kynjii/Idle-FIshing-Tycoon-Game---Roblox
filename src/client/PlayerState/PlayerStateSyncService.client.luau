local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local CharmPackets = require(ReplicatedStorage.Shared.Networking.CharmSyncPackets)
local PlayerStateService = require(script.Parent.PlayerStateService)

local syncer = CharmSync.client({
    atoms = PlayerStateService:Get(),
    ignoreUnhydrated = true,
})

CharmPackets.StateUpdate.listen(function(data)
    syncer:sync(data.message)
end)

CharmPackets.RequestHydrate.send({
    message = true,
})
