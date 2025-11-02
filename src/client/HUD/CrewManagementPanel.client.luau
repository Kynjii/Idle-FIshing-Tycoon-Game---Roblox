-- !strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crewManagementButtonScreenGui = playerGui:WaitForChild("CrewManagementButton")
local crewManagementButton = crewManagementButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton
local screenGui: ScreenGui

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
end)

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

local crewState: { [string]: any } = {}

function updateCrewMngPanelUI()
	clearExistingTooltip()

	-- //TODO -
end

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
