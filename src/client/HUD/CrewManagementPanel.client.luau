--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local JobPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.JobPanel)
local MainUIPanel = require(ReplicatedStorage.Shared.UI.Components.Frames.MainUIPanel)
local ShopItem = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopItem)

-- Elements
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crewManagementButtonScreenGui = playerGui:WaitForChild("CrewManagementButton")
local crewManagementButton = crewManagementButtonScreenGui:FindFirstChild("OpenButton", true) :: ImageButton
local screenGui: ScreenGui
local innerWindow: any

-- Events
local getJobDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetJobData)
local getCrewManagementState = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
local tabSelectedEvent = Events.GetBindableEvent(Events.BindableNames.TabSelected)
local getInventoryFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
local updateUIEvent = Events.GetRemote(Events.RemoteNames.UpdateJobManagementUI)
local helperUpgradedEvent = Events.GetRemote(Events.RemoteNames.HelperUpgraded)

-- State
local crewState: { [string]: any } = {}
type Tab = "Crew" | "Jobs"
local selectedTab: Tab = "Crew"

local itemComponents: { [string]: Instance } = {}
local playerInventory: { [string]: any } = {}

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

	local crewItemsContainer = innerWindow:FindFirstChild("ItemContainer", true) :: ScrollingFrame

	local function createShopitemComponent(helper: HelperType.HelperData)
		return ShopItem({
			ItemData = helper,
			BackgroundColor3 = FFGEnum.QUALITIES[helper.QualityId].Color,
			Size = UDim2.fromScale(1, 1),
			Rounded = FFGEnum.THEME.button.cornerRadius,
			HoverEffect = true,
			Visible = true,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(32, 83, 32, 83),
			Parent = crewItemsContainer,
			ShopInstance = innerWindow,
		})
	end

	for _, component in pairs(itemComponents) do
		component:Destroy()
	end

	itemComponents = {}

	if crewItemsContainer then
		local isFirst = true
		for k, item in pairs(playerInventory) do
			local itemComponent = createShopitemComponent(item)
			if isFirst then
				local btn = itemComponent:FindFirstChildOfClass("ImageButton")
				if btn then
					btn.Selected = true
					Events.FireEvent(Events.RemoteNames.UpdateInfoPanel, player, item)
				end

				isFirst = false
			end
			itemComponents[item.Id] = itemComponent
		end
	end
end

function updateCrewMngPanelUI()
	local crewManagementContainer = innerWindow and innerWindow:FindFirstChild("CrewManagementContainer", true)
	if crewManagementContainer then crewManagementContainer:Destroy() end

	if innerWindow then
		if selectedTab == "Jobs" then
			if getJobDataEvent and getCrewManagementState then
				-- Get Crewstate
				local data = getCrewManagementState:InvokeServer()
				if data then crewState = data end

				-- Get Job Data
				local jobsData = getJobDataEvent:InvokeServer()

				-- Recreate window
				local jobPanel = JobPanel.Create(player, jobsData, crewState, selectedTab)
				jobPanel.Parent = innerWindow
			end
		elseif selectedTab == "Crew" then
			local data
			if getInventoryFn then data = getInventoryFn:InvokeServer() end
			if data then playerInventory = data end
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

if updateUIEvent then updateUIEvent.OnClientEvent:Connect(function()
	updateCrewMngPanelUI()
end) end

if tabSelectedEvent and getInventoryFn then tabSelectedEvent.Event:Connect(function(tabName)
	selectedTab = tabName

	updateCrewMngPanelUI()
end) end

if helperUpgradedEvent then
	helperUpgradedEvent.OnClientEvent:Connect(function(helperData: HelperType.HelperData)
		if playerInventory[helperData.Id] then playerInventory[helperData.Id] = helperData end

		updateCrewMngPanelUI()
	end)
end
