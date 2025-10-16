local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = {}

Events.RemoteNames = {
	WarningMsg = "WarningMsg",
	OpenEntityDetails = "OpenEntityDetails",
	EntityPurchased = "EntityPurchased",
	EntityUpgraded = "EntityUpgraded",
	GameReset = "GameReset",
	OpenShopDetails = "OpenShopDetails",
	ShopItemPurchased = "ShopItemPurchased",
}

local FOLDER_NAME = "Events"

function Events.InitOnServer()
	assert(RunService:IsServer(), "InitOnServer must be called from the server")

	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	for _, remoteName in pairs(Events.RemoteNames) do
		if not folder:FindFirstChild(remoteName) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = remoteName
			ev.Parent = folder
		end
	end
end

function Events.GetRemote(name: string): RemoteEvent?
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 10)
	if not folder then return nil end
	local ev = folder:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then return ev end

	return folder:WaitForChild(name, 5) :: RemoteEvent
end

function Events.FireEvent(name: string, player: Player, data: string)
	assert(RunService:IsServer(), "FireEvent must be called from the server")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	local ev = folder and folder:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		local safeData = data
		if type(data) == "table" and data:Serialize() then safeData = data:Serialize() end
		ev:FireClient(player, safeData)
		return true
	else
		warn(("RemoteEvent %q not found under ReplicatedStorage/%s"):format(name, FOLDER_NAME))
		return false
	end
end

return Events
