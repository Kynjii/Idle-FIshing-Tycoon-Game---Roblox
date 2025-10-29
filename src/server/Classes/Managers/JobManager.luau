local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Helper = require(ServerScriptService.Server.Classes.Helper)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local JobManager = {}
JobManager.__index = JobManager

type JobManager = typeof(setmetatable({}, JobManager))

function JobManager.New(helperState, player: Player, teamId: number): JobManager
	local self = setmetatable({} :: JobManager, JobManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Helpers = {}
	for _, helper in pairs(helperState) do
		local helperClass = Helper.New(helper, player, teamId)
		self.Helpers[helperClass.Id] = helperClass
	end

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function JobManager.AssignHelper(self: JobManager, helperId: number, jobId: string): boolean
	if not helperId or not jobId then return false end

	local helper = self.Helpers and self.Helpers[helperId]
	if not helper then
		local inventory = DataService.GetPlayerInventory(self.Player)
		local savedHelperState = inventory[helperId]
		local newHelperClass = Helper.New(savedHelperState, self.Player, self.TeamId)
		self.Helpers[newHelperClass.Id] = newHelperClass
	end

	if helper and helper.AssignJob then
		local assigned = helper:AssignJob(jobId)
		if assigned then
			self:StartJob(helper, jobId)
			return true
		else
			return false
		end
	end

	return false
end

function JobManager.StartJob(self: JobManager, helper: HelperType.HelperInstance, jobId: string)
	if not helper then return end

	local startPos: Vector3 = Jobs.Data[jobId].Location
	if startPos then helper.Model:MoveTo(startPos) end
end

-- //SECTION - Event Listeners
function JobManager.AttachEventListeners(self: JobManager): ()
	local assignJobEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.AssignJob)
	if assignJobEvent then assignJobEvent.OnServerInvoke = function(player: Player, helperId: string, jobId: string)
		if self.Player ~= player or self.Owner ~= player.UserId then return end
		if not helperId or not jobId then return end

		return self:AssignHelper(helperId, jobId)
	end end
end
-- //!SECTION

-- //SECTION - Cleanup
function JobManager.Destroy(self: JobManager): ()
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Save()

	self.Player = nil :: any
end
-- //!SECTION

return JobManager
