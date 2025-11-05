local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.fromScale(1, 1)
imageLabel.Image = "rbxassetid://84620520803704"
imageLabel.Parent = screenGui

local textFrame = Instance.new("Frame")
textFrame.Size = UDim2.fromScale(0.5, 0.3)
textFrame.AnchorPoint = Vector2.new(0.5, 0.5)
textFrame.Position = UDim2.fromScale(0.55, 0.8)
textFrame.Transparency = 1
textFrame.ZIndex = 10

local textFrameUIList = Instance.new("UIListLayout")
textFrameUIList.FillDirection = Enum.FillDirection.Horizontal
textFrameUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
textFrameUIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
textFrameUIList.ItemLineAlignment = Enum.ItemLineAlignment.Center
textFrameUIList.Padding = UDim.new(0.01)
textFrameUIList.Parent = textFrame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.fromScale(0.5, 0.5)
textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
textLabel.Position = UDim2.fromScale(0.5, 0.5)
textLabel.Transparency = 1
textLabel.TextTransparency = 0
textLabel.TextStrokeTransparency = 0
textLabel.TextStrokeColor3 = Color3.fromRGB(0)
textLabel.Font = Enum.Font.Bangers
textLabel.TextColor3 = Color3.fromHex("#ffffff")
textLabel.Text = "Loading game"
textLabel.TextScaled = true
textLabel.TextXAlignment = Enum.TextXAlignment.Right
textLabel.Parent = textFrame

local textLabel2 = Instance.new("TextLabel")
textLabel2.Size = UDim2.fromScale(0.3, 0.3)
textLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
textLabel2.Position = UDim2.fromScale(0.5, 0.3)
textLabel2.Transparency = 1
textLabel2.TextTransparency = 0
textLabel2.TextStrokeTransparency = 0
textLabel2.TextStrokeColor3 = Color3.fromRGB(0)
textLabel2.Font = Enum.Font.Bangers
textLabel2.TextColor3 = Color3.fromHex("#ffffff")
textLabel2.Text = ""
textLabel2.TextScaled = true
textLabel2.FontFace.Weight = Enum.FontWeight.Light
textLabel2.TextXAlignment = Enum.TextXAlignment.Left
textLabel2.TextYAlignment = Enum.TextYAlignment.Bottom
textLabel2.Parent = textFrame

textFrame.Parent = screenGui

local loadingText = {
	[1] = ".",
	[2] = "..",
	[3] = "...",
}

local textUpdater = task.spawn(function()
	while true do
		for index, text in ipairs(loadingText) do
			textLabel2.Text = loadingText[index]
			task.wait(1.2)
		end
	end
end)

-- Remove the default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

if not game:IsLoaded() then game.Loaded:Wait() end

task.wait(7) -- Force screen to appear for a minimum number of seconds
task.cancel(textUpdater)
textUpdater = nil

local hudElements = playerGui:GetChildren()
local elementsToShow = {
	HUD = "HUD",
	InventoryButton = "InventoryButton",
	CrewManagementButton = "CrewManagementButton",
}
for _, screenGUI: ScreenGui in pairs(hudElements) do
	if elementsToShow[screenGUI.Name] then screenGUI.Enabled = true end
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)

screenGui:Destroy()
