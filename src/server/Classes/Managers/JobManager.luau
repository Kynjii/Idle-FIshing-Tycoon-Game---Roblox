local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Helper = require(ServerScriptService.Server.Classes.Helper)
local Pathfinding = require(ServerScriptService.Server.Classes.Modules.Pathfinding)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local ProgressBar = require(ServerScriptService.Server.Modules.Tweens.ProgressBar)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)

local JobManager = {}
JobManager.__index = JobManager

export type JobManager = typeof(setmetatable({}, JobManager))
export type JobState = {
	[number]: { IsAvailable: boolean },
}

function JobManager.New(helperState, player: Player, teamId: number): JobManager
	local self = setmetatable({} :: JobManager, JobManager)
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId

	self.Helpers = {}
	self.JobState = {} :: JobState
	self:GenerateJobState()

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

function JobManager.AssignJobs(self: JobManager, player: Player): ()
	for _, helper in pairs(self.Helpers) do
		self:AssignHelper(helper.Id, helper.CurrentAssignment, player)
	end
end

function JobManager.GenerateJobState(self: JobManager): ()
	local jobSlots = Jobs.GetMaxSlots()

	for i, slotNum in ipairs(jobSlots) do
		self.JobState[i] = {}
		local maxSlots = slotNum

		for s = 1, maxSlots do
			self.JobState[i][s] = { IsAvailable = false }
		end
	end

	print(self.JobState)
end

function JobManager.NumOfSlotsAvailable(self: JobManager, jobId: number): number
	local jobState: JobState = self.JobState[jobId]
	local slotNumber = 0

	for i, slot in ipairs(jobState) do
		if slot.IsAvailable then
			slotNumber += i
		end
	end

	return slotNumber
end

function JobManager.AssignSlot(self: JobManager, jobId: number): ()
	local jobState: JobState = self.JobState[jobId]

	for i, slot in ipairs(jobState) do
		if not slot.IsAvailable then
			slot.IsAvailable = true
			break
		end
	end
end

function JobManager.AssignHelper(self: JobManager, helperId: number, jobId: number, player: Player?): ()
	if not helperId or not jobId then return end
	if self:NumOfSlotsAvailable(jobId) == 0 then
		print("No JobSlots available for JobId: ", jobId)
		return
	end

	local helper = self.Helpers and self.Helpers[helperId] or nil

	-- To handle the case were the Helper is somehow not in the inventory when assignment is attempted.
	-- This is likely due to how it used to be handled, potential remove
	-- //TODO - reminder
	local isNewAssignment = true
	if not helper then
		local inventory = DataService.GetPlayerInventory(self.Player or player)
		if not inventory then return end

		local savedHelperState = inventory[helperId]
		local newHelperClass = Helper.New(savedHelperState, self.Player, self.TeamId)

		self.Helpers[newHelperClass.Id] = newHelperClass

		helper = newHelperClass
	else
		isNewAssignment = false
	end

	self:AssignSlot(jobId)
	helper:AssignJob(jobId, isNewAssignment)

	print(self.JobState)
end

function JobManager.BeginAction(self: JobManager, actionType: string, helper: HelperType.HelperInstance, jobId: number)
	local isGatherAction = actionType == "Gather"

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

		local actionTask = task.spawn(function()
			while not finished do
				if timePassed >= waitTime then
					finished = true
				else
					timePassed += 0.5
					if progressBarFrame then ProgressBar.Update(progressBarFrame, timePassed, waitTime) end
					task.wait(0.5)
				end
			end

			if finished then
				ProgressBar.Hide(helperProgressBillboard)
				if isGatherAction then
					local availableStorage = helper.Stats.Storage

					local data: GetStorageFishData = {
						Player = self.Player,
						JobId = jobId,
						TeamId = self.TeamId,
						AvailableStorage = availableStorage,
						HelperId = helper.Id,
					}
					Events.FireBindableEvent(Events.BindableNames.GetStorageFish, data)
				else
					local amount = helper.ResourceInStorage
					DataService.Earn(self.Player, FFGEnum.CURRENCY_TYPES.Gold, amount)
					helper:ClearStorage()
					self:StartJob(helper, jobId)
				end
			else
				ProgressBar.Hide(helperProgressBillboard)
				print("gathering cancelled")
			end
		end)

		if helper._cleaner then helper._cleaner:Add(function()
			task.cancel(actionTask)
		end) end
	end
end

function JobManager.BeginUnloading(self: JobManager, helper: HelperType.HelperData, jobId: number)
	local actionType = "Unload"
	self:BeginAction(actionType, helper, jobId)
end

function JobManager.StartJob(self: JobManager, helper: HelperType.HelperInstance, jobId: number)
	if not helper or not helper.Model then return end

	if helper.ResourceInStorage > 0 then
		self:BeginUnloading(helper, jobId)
	else
		Pathfinding.GoGatherSpot(jobId, helper.Id, helper.Model, self.Player)
	end
end

function JobManager.BeginGathering(self: JobManager, helper: HelperType.HelperData, jobId: number)
	if not helper then return end

	local actionType = "Gather"
	self:BeginAction(actionType, helper, jobId)
end

type SendStorageFishData = {
	Player: Player,
	HelperId: string,
	JobId: number,
	Amount: number,
}

type GetStorageFishData = {
	Player: Player,
	JobId: number,
	TeamId: number,
	AvailableStorage: number,
	HelperId: string,
}

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

		self:BeginGathering(helper, jobId)
	end) end

	local helperAtUnloadingLoc = Events.GetBindableEvent(Events.BindableNames.HelperAtUnloadingLoc)
	if helperAtUnloadingLoc then helperAtUnloadingLoc.Event:Connect(function(data)
		local helperId = data.Id
		local jobId = data.JobId
		local helper = self.Helpers[helperId]
		if not helper then return end

		self:StartJob(helper, jobId)
	end) end

	-- //TODO - Perhaps change the name, it's confusing. This is the chainmanager sending fish to me
	local sendStorageFish = Events.GetBindableEvent(Events.BindableNames.SendStorageFish)
	if sendStorageFish then sendStorageFish.Event:Connect(function(data: SendStorageFishData)
		local player = data.Player
		if player ~= self.Player then return end

		local helperId = data.HelperId
		local helper = self.Helpers[helperId]
		if not helper then return end

		local jobId = data.JobId
		if helper.CurrentAssignment ~= jobId then return end

		local amount = data.Amount
		if amount then helper:AddResource(amount) end
		Pathfinding.GoUnloadSpot(jobId, helper.Id, helper.Model, self.Player)
	end) end
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
