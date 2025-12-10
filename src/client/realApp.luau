local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local HUD = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD)
local FishingUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.FishingUI)

local function App()
    return e("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        HUD = HUD.component(),
    })
end

return App
