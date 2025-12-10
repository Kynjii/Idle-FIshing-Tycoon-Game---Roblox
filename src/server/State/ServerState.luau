local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local ServerState = {}

ServerState.Gold = Charm.atom(0)

return ServerState
