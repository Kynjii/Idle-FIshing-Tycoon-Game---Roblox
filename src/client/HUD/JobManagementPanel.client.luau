local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local Tooltip = require(ReplicatedStorage.Shared.UI.Components.Tooltips.Tooltip)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local inventoryUI: Instance
local inventoryDetailsUI: Instance
local main: Instance
local inventoryItemsContainer: Instance
local screenGui: ScreenGui

local jobManagementButton = playerGui:WaitForChild("JobManagement"):FindFirstChild("OpenButton", true) :: ImageButton

-- task.spawn(function()
-- 	inventoryUI = ShopGUI.Create({ Name = "Inventory", ScreenGuiName = "PlayerInventory" })
-- 	inventoryUI.Parent = playerGui

-- 	inventoryDetailsUI = inventoryUI:WaitForChild("DetailsContainer", 10) :: Frame

-- 	main = inventoryDetailsUI:WaitForChild("Main", 10) :: Frame
-- 	inventoryItemsContainer = main:WaitForChild("ItemContainer", 10) :: ScrollingFrame

-- 	screenGui = player.PlayerGui.PlayerInventory
-- end)

function clearExistingTooltip()
	Tooltip.ClearExisting(player.UserId)
end

local playerInventory: { [string]: any } = {}

function updateJobPanelUI()
	clearExistingTooltip()

	--
end

function populateDetailsUI()
	if not playerInventory then return end
	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting

	updateJobPanelUI()
end

local getInventoryFn = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)
if jobManagementButton and getInventoryFn then jobManagementButton.Activated:Connect(function()
	if screenGui.Enabled then
		screenGui.Enabled = false
		if Lighting then
			local blur = Lighting:FindFirstChild("Blur")
			if blur then blur:Destroy() end
		end
		return
	end

	local data = getInventoryFn:InvokeServer()
	if data then
		playerInventory = data

		populateDetailsUI()
		screenGui.Enabled = true
	end
end) end

local openJobManagementPanel = Events.GetRemote(Events.RemoteNames.OpenJobManagementPanel)
if openJobManagementPanel and getInventoryFn then openJobManagementPanel.OnClientEvent:Connect(function()
	local data = getInventoryFn:InvokeServer()
	if data then
		playerInventory = data

		populateDetailsUI()
		screenGui.Enabled = true
	end
end) end
