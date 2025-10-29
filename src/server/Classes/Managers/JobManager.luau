local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local Trove = require(ReplicatedStorage.Packages.Trove)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local JobManager = {}
JobManager.__index = JobManager

type JobManager = typeof(setmetatable({}, JobManager))

function JobManager.New(helperState, player: Player, teamId: number): JobManager
	local self = setmetatable({} :: JobManager, JobManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Helpers = helperState and helperState.Helpers or nil

	self._cleaner = Trove.new()

	self:AttachEventListeners()

	return self
end

function JobManager.AssignHelper(self: JobManager, helperId: number, jobId: string)
	if not self.Helpers or not self.Helpers[helperId] or not jobId then return end

	local helper = self.Helpers[helperId]
	if helper and helper.AssignJob then
		local assigned = helper.AssignJob(jobId)
		if assigned then self:StartJob(helper, jobId) end
	end
end

function JobManager.StartJob(self: JobManager, helper: HelperType.HelperInstance, jobId: string)
	if not helper then return end

	local startPos: CFrame = Jobs.Data[jobId].Location
	if startPos then helper.Model:MoveTo(startPos) end
end

-- //SECTION - Setup
function JobManager.Initialize(self: JobManager): ()
	--
end
-- //!SECTION

-- //SECTION - Event Listeners
function JobManager.AttachEventListeners(self: JobManager): ()
	-- EventListeners.Attach(self :: any)
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
