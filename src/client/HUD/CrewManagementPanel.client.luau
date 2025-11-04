--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local CrewManagementPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.CrewManagementPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crewManagementButtonScreenGui = playerGui:WaitForChild("CrewManagementButton")
local crewManagementButton = crewManagementButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton
local screenGui: ScreenGui

local getJobDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetJobData)

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

function updateCrewMngPanelUI()
	clearExistingTooltip()

	local innerWindow = screenGui:FindFirstChild("InnerWindow", true)
	local crewManagementContainer = innerWindow and innerWindow:FindFirstChild("CrewManagementContainer", true)
	if crewManagementContainer then crewManagementContainer:Destroy() end

	if innerWindow then
		if getJobDataEvent then
			local jobsData = getJobDataEvent:InvokeServer()
			local crewManagementPanel = CrewManagementPanel.Create(player, jobsData)
			crewManagementPanel.Parent = innerWindow
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
				{ Name = "TransportingTab", Index = 1, Icon = FFGEnum.UI.Icons.Transporting },
			},
		},
	})
	screenGui.Parent = playerGui

	updateCrewMngPanelUI()
end)

local crewState: { [string]: any } = {}

function populateDetailsUI()
	if not crewState then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateCrewMngPanelUI()
end

local getCrewManagementState = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
if crewManagementButton and getCrewManagementState then
	crewManagementButton.Activated:Connect(function()
		if screenGui.Enabled then
			screenGui.Enabled = false
			if Lighting then
				local blur = Lighting:FindFirstChild("BlurEffect")
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
