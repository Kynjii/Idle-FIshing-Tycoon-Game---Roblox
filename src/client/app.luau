local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local PlayerStateService = require(StarterPlayer.StarterPlayerScripts.Client.PlayerState.PlayerStateService)
local React = require(ReplicatedStorage.Packages.React)
local RC = require(ReplicatedStorage.Packages["React-charm"])
local RR = require(ReplicatedStorage.Packages["React-roblox"])

local e = React.createElement

local function MyColorfulClickableSquare()
    local goldAmount, setGoldAmount = RC.useAtom(PlayerStateService.State.Gold)

    local color, setColor = React.useState(Color3.new(255, 255, 255))
    return e("TextButton", {
        Size = UDim2.new(0, 200, 0, 200),
        BackgroundColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = tostring(goldAmount),
        [React.Event.Activated] = function()
            local newColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            print("changing color to " .. tostring(newColor) .. "!")
            setColor(newColor)
        end,
    })
end

local handle = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
handle.ResetOnSpawn = false
local root = RR.createRoot(handle)
root:render(e(MyColorfulClickableSquare, {}, {}))
