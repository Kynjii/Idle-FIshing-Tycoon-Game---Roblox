local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Packages.ByteNet)

return ByteNet.defineNamespace("CharmSync", function()
    return {
        StateUpdate = ByteNet.definePacket({
            value = ByteNet.struct({
                message = ByteNet.unknown,
            }),
        }),

        RequestHydrate = ByteNet.definePacket({
            value = ByteNet.struct({
                message = ByteNet.unknown,
            }),
        }),
    }
end)
