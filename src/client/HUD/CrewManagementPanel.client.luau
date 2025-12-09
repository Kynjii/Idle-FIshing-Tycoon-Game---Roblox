--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.HelperPanel)
local JobPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.JobPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)

-- Elements
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crewManagementButtonScreenGui = playerGui:WaitForChild("CrewManagementButton") :: ScreenGui
local crewManagementButton = crewManagementButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton
local screenGui: ScreenGui
local innerWindow: any

-- Events
local getJobDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetJobData)
local getCrewManagementState = Events.GetRemoteFn(Events.RemoteFunctionNames.GetHelperInventory)
local tabSelectedEvent = Events.GetBindableEvent(Events.BindableNames.TabSelected)
local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateJobManagementUI)

-- State
local crewState: { [string]: any } = {}
type Tab = "Crew" | "Jobs"
local selectedTab: Tab = "Crew"

task.spawn(function()
	screenGui = MainUIPanel.Create({
		screenGuiName = "CrewManagementPanel",
		panelName = "Crew Management",
		panelTabs = {
			hasTabs = true,
			tabs = {
				{ Name = "Crew", Index = 1, Icon = FFGEnum.UI.Icons.CrewManagement },
				{ Name = "Jobs", Index = 2, Icon = FFGEnum.UI.Icons.CrewJobs },
			},
		},
	})
	screenGui.Parent = playerGui
	innerWindow = screenGui:FindFirstChild("InnerWindow", true) :: Frame
end)

function updateCrewPanel()
	if not innerWindow then return end
	HelperPanel.Create(player, crewState, innerWindow)
end

function updateCrewMngPanelUI()
	local innerWindowChildren = innerWindow:GetChildren()
	for _, element in ipairs(innerWindowChildren) do
		element:Destroy()
	end

	if innerWindow and getCrewManagementState then
		-- Get Crewstate
		local data = getCrewManagementState:InvokeServer()
		if data then crewState = data end

		if selectedTab == "Jobs" then
			if getJobDataEvent then
				-- Get Job Data
				local jobsData = getJobDataEvent:InvokeServer()

				-- Recreate window
				local jobPanel = JobPanel.Create(player, jobsData, crewState, selectedTab)
				jobPanel.Parent = innerWindow
			end
		elseif selectedTab == "Crew" then
			updateCrewPanel()
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

local playerAssignedEvent = Events.GetRemote(Events.RemoteNames.PlayerAssigned)
if playerAssignedEvent then
	playerAssignedEvent.OnClientEvent:Once(function()
		if crewManagementButtonScreenGui and not crewManagementButtonScreenGui.Enabled then crewManagementButtonScreenGui.Enabled = true end
	end)
end

if updateUIEvent then updateUIEvent.OnClientEvent:Connect(function()
	updateCrewMngPanelUI()
end) end

if tabSelectedEvent and getCrewManagementState then tabSelectedEvent.Event:Connect(function(tabName)
	if not screenGui.Enabled then return end
	selectedTab = tabName

	updateCrewMngPanelUI()
end) end
