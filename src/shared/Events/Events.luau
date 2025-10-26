local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = {}

Events.RemoteNames = {
	WarningMsg = "WarningMsg",
	OpenEntityDetails = "OpenEntityDetails",
	EntityPurchased = "EntityPurchased",
	EntityUpgraded = "EntityUpgraded",
	GameReset = "GameReset",
	OpenHelperShop = "OpenHelperShop",
	HelperPurchased = "HelperPurchased",
	PrepareHelperShop = "PrepareHelperShop",
	UpdateUI = "UpdateUI",
	OpenJobManagementPanel = "OpenJobManagementPanel",
}

Events.RemoteFunctionNames = {
	GetPlayerInventory = "GetPlayerInventory",
}

Events.BindableNames = {
	ShowTooltip = "ShowTooltip",
	CloseUIWindow = "CloseUIWindow",
}

local FOLDER_NAME = "RME"
local FOLDER_NAME_BINDABLES = "BEV"
local FOLDER_NAME_REMOTE_FUNCS = "RFN"

function Events.InitOnServer()
	assert(RunService:IsServer(), "InitOnServer must be called from the server")

	-- Remotes
	local remoteFolder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = FOLDER_NAME
		remoteFolder.Parent = ReplicatedStorage
	end

	for _, remoteName in pairs(Events.RemoteNames) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = remoteName
			ev.Parent = remoteFolder
		end
	end

	local remoteFnFolder = ReplicatedStorage:FindFirstChild(FOLDER_NAME_REMOTE_FUNCS)
	if not remoteFnFolder then
		remoteFnFolder = Instance.new("Folder")
		remoteFnFolder.Name = FOLDER_NAME_REMOTE_FUNCS
		remoteFnFolder.Parent = ReplicatedStorage
	end

	for _, remoteFnName in pairs(Events.RemoteFunctionNames) do
		if not remoteFnFolder:FindFirstChild(remoteFnName) then
			local ev = Instance.new("RemoteFunction")
			ev.Name = remoteFnName
			ev.Parent = remoteFnFolder
		end
	end

	-- Bindables
	local bindableFolder = ReplicatedStorage:FindFirstChild(FOLDER_NAME_BINDABLES)
	if not bindableFolder then
		bindableFolder = Instance.new("Folder")
		bindableFolder.Name = FOLDER_NAME_BINDABLES
		bindableFolder.Parent = ReplicatedStorage
	end

	for _, bindableName in pairs(Events.BindableNames) do
		if not bindableFolder:FindFirstChild(bindableName) then
			local ev = Instance.new("BindableEvent")
			ev.Name = bindableName
			ev.Parent = bindableFolder
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

function Events.GetBindableEvent(name: string): BindableEvent?
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME_BINDABLES, 10)
	if not folder then return nil end
	local ev = folder:FindFirstChild(name)
	if ev and ev:IsA("BindableEvent") then return ev end

	return folder:WaitForChild(name, 5) :: BindableEvent
end

function Events.GetRemoteFn(name: string): RemoteFunction?
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME_REMOTE_FUNCS, 10)
	if not folder then return nil end
	local ev = folder:FindFirstChild(name)
	if ev and ev:IsA("RemoteFunction") then return ev end

	return folder:WaitForChild(name, 5) :: RemoteFunction
end

function Events.FireBindableEvent(name: string, data: any)
	assert(RunService:IsClient(), "FireEvent must be called from the client")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME_BINDABLES)
	local ev = folder and folder:FindFirstChild(name)
	if ev and ev:IsA("BindableEvent") then
		ev:Fire(data)
		return true
	else
		warn(("BindableEvent %q not found under ReplicatedStorage/%s"):format(name, FOLDER_NAME_BINDABLES))
		return false
	end
end

function Events.FireEvent(name: string, player: Player, data: any)
	assert(RunService:IsServer(), "FireEvent must be called from the server")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	local ev = folder and folder:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		local safeData = data
		if type(data) == "table" and type(data.Serialize) == "function" then safeData = data:Serialize() end
		ev:FireClient(player, safeData)
		return true
	else
		warn(("RemoteEvent %q not found under ReplicatedStorage/%s"):format(name, FOLDER_NAME))
		return false
	end
end

return Events
