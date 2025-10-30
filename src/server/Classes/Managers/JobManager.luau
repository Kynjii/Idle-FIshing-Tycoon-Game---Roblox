local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Helper = require(ServerScriptService.Server.Classes.Helper)
local Pathfinding = require(ServerScriptService.Server.Classes.Modules.Pathfinding)
local ProgressBar = require(ServerScriptService.Server.Modules.Tweens.ProgressBar)
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

	self._cleaner = Trove.new()

	self:CreateHelpers(helperState)
	self:AttachEventListeners()
	self:AssignJobs(player)

	return self
end

function JobManager.CreateHelpers(self: JobManager, helperState)
	for _, helper in pairs(helperState) do
		local helperClass = Helper.New(helper, self.Player, self.TeamId)
		self.Helpers[helperClass.Id] = helperClass
	end
end

function JobManager.AssignJobs(self: JobManager, player: Player)
	for _, helper in pairs(self.Helpers) do
		self:AssignHelper(helper.Id, helper.CurrentAssignment, player)
	end
end

function JobManager.AssignHelper(self: JobManager, helperId: number, jobId: number, player: Player?): ()
	if not helperId or not jobId then return end

	local helper = self.Helpers and self.Helpers[helperId] or nil
	if not helper then
		local inventory = DataService.GetPlayerInventory(self.Player or player)
		if not inventory then return end

		local savedHelperState = inventory[helperId]
		local newHelperClass = Helper.New(savedHelperState, self.Player, self.TeamId)

		self.Helpers[newHelperClass.Id] = newHelperClass

		helper = newHelperClass
	end

	if helper and helper.AssignJob then
		local isNewAssignment = true
		helper:AssignJob(jobId, isNewAssignment)
	end
end

function JobManager.StartJob(self: JobManager, helper: HelperType.HelperInstance, jobId: number)
	if not helper or not helper.Model then return end

	if helper.ResourceInStorage > 0 then
		-- begin unload
	else
		Pathfinding.GoGatherSpot(jobId, helper.Id, helper.Model, self.Player)
	end
end

function JobManager.BeginGathering(self: JobManager, helper: HelperType.HelperData)
	if not helper then return end

	local helperProgressBillboard: BillboardGui? = helper.Model and helper.Model:FindFirstChild("HelperProgress")
	local progressBarFrame
	if helperProgressBillboard then
		progressBarFrame = helperProgressBillboard:FindFirstChild("ProgressBar", true)
		helperProgressBillboard.Enabled = true
		ProgressBar.Show(helperProgressBillboard)
	end

	local waitTime: number = helper.Stats and helper.Stats.LoadTime
	if waitTime then
		local timePassed = 0
		local finished = false

		local gatheringTask = task.spawn(function()
			while not finished and helper and self.Player do
				if timePassed >= waitTime then
					finished = true
				else
					timePassed += 1

					if progressBarFrame then ProgressBar.Update(progressBarFrame, timePassed, waitTime) end

					task.wait(1)
				end
			end

			if finished then
				ProgressBar.Hide(helperProgressBillboard)
				print("gathering complete!")
				-- Continue to next phase of job or fire completion event
			else
				ProgressBar.Hide(helperProgressBillboard)
				print("gathering cancelled")
			end
		end)

		if helper._cleaner then helper._cleaner:Add(function()
			task.cancel(gatheringTask)
		end) end
	end
end

-- //SECTION - Event Listeners
function JobManager.AttachEventListeners(self: JobManager): ()
	-- Remote events for assigning helper to a job
	local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
	if assignJobEvent then assignJobEvent.OnServerEvent:Connect(function(player: Player, helperId: string, jobId: number)
		if self.Player ~= player or self.Owner ~= player.UserId then return end
		if not helperId or not jobId then return end

		self:AssignHelper(helperId, jobId)
	end) end

	-- Remote Events for handling job cycle
	local helperAtGatheringLoc = Events.GetBindableEvent(Events.BindableNames.HelperAtGatheringLoc)
	if helperAtGatheringLoc then helperAtGatheringLoc.Event:Connect(function(data)
		local helperId = data.Id
		local jobId = data.JobId
		local helper = self.Helpers[helperId]
		if not helper then return end

		self:BeginGathering(helper)
	end) end

	local helperAtUnloadingLoc = Events.GetBindableEvent(Events.BindableNames.HelperAtUnloadingLoc)
	if helperAtUnloadingLoc then helperAtUnloadingLoc.Event:Connect(function(data)
		local helperId = data.Id
		local jobId = data.JobId
		local helper = self.Helpers[helperId]
		if not helper then return end

		self:StartJob(helper, jobId)
	end) end

	local helperStuck = Events.GetBindableEvent(Events.BindableNames.HelperStuck)
	if helperStuck then
		helperStuck.Event:Connect(function()
			-- helperStuck | send after ~30 seconds of it not reaching it's destination and reset
		end)
	end
end
-- //!SECTION

-- //SECTION - Cleanup
function JobManager.Destroy(self: JobManager): ()
	for _, helper in pairs(self.Helpers) do
		helper:Destroy()
	end

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Save()

	self.Player = nil :: any
end
-- //!SECTION

return JobManager
