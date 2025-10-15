local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.fromScale(1, 1)
imageLabel.Image = "rbxassetid://84620520803704"
imageLabel.Parent = screenGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.fromScale(1, 1)
textLabel.Transparency = 1
textLabel.Font = Enum.Font.FredokaOne
textLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
textLabel.Text = "Loading game..."
textLabel.TextSize = 28
textLabel.Parent = imageLabel

-- Remove the default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

task.wait(3) -- Force screen to appear for a minimum number of seconds

if not game:IsLoaded() then game.Loaded:Wait() end

screenGui:Destroy()
