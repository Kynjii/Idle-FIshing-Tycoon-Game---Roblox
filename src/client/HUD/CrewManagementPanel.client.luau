--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local CrewManagementPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.CrewManagementPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

-- Elements
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crewManagementButtonScreenGui = playerGui:WaitForChild("CrewManagementButton")
local crewManagementButton = crewManagementButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton
local screenGui: ScreenGui

-- Events
local getJobDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetJobData)
local getCrewManagementState = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)

-- State
local crewState: { [string]: any } = {}
type Tab = "Fishing" | "Woodcutting" | "Mining" | "Transporting"
local selectedTab: Tab = "Transporting"

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

function updateCrewMngPanelUI()
	clearExistingTooltip()

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	local crewManagementContainer = innerWindow and innerWindow:WaitForChild("CrewManagementContainer", 5)
	if crewManagementContainer then crewManagementContainer:Destroy() end

	if innerWindow then
		if getJobDataEvent and getCrewManagementState then
			-- Get Crewstate
			local data = getCrewManagementState:InvokeServer()
			if data then crewState = data end

			-- Get Job Data
			local jobsData = getJobDataEvent:InvokeServer()

			-- Recreate window
			local crewManagementPanel = CrewManagementPanel.Create(player, jobsData, crewState, selectedTab)
			crewManagementPanel.Parent = innerWindow
		end
	end

	local tabContainer = screenGui:FindFirstChild("TabContainer", true)
	if tabContainer then
		local children = tabContainer:GetChildren()
		for _, instance in pairs(children) do
			if not instance:IsA("ImageButton") then continue end
			if instance.Name == selectedTab then
				instance.ImageColor3 = FFGEnum.UI.Tabs.SelectedColor
			else
				instance.ImageColor3 = FFGEnum.UI.Tabs.BaseColor
			end
		end
	end
end

task.spawn(function()
	screenGui = MainUIPanel.Create({
		screenGuiName = "CrewManagementPanel",
		panelName = "Crew Management",
		panelTabs = {
			hasTabs = true,
			tabs = {
				{ Name = "Transporting", Index = 1, Icon = FFGEnum.UI.Icons.Transporting },
			},
		},
	})
	screenGui.Parent = playerGui

	updateCrewMngPanelUI()
end)

function populateDetailsUI()
	if not crewState then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateCrewMngPanelUI()
end

if crewManagementButton and getCrewManagementState then
	crewManagementButton.Activated:Connect(function()
		if screenGui.Enabled then
			screenGui.Enabled = false
			if Lighting then
				local blur = Lighting:FindFirstChild("Blur")
				if blur then blur:Destroy() end
			end
			return
		end

		local data = getCrewManagementState:InvokeServer()
		if data then
			crewState = data

			populateDetailsUI()
			screenGui.Enabled = true
		end
	end)
end

local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateJobManagementUI)
if updateUIEvent then updateUIEvent.OnClientEvent:Connect(function()
	updateCrewMngPanelUI()
end) end

local tabSelectedEvent = Events.GetBindableEvent(Events.BindableNames.TabSelected)
if tabSelectedEvent then tabSelectedEvent.Event:Connect(function(tabName)
	selectedTab = tabName
	updateCrewMngPanelUI()
end) end
