local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local realApp = require(script.Parent.realApp)
local RR = require(ReplicatedStorage.Packages["React-roblox"])

local e = React.createElement

local handle = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
local root = RR.createRoot(handle)
root:render(e(realApp))
