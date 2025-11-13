local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Helper = require(ServerScriptService.Server.Classes.Helper)
local ClassCalculators = require(ServerScriptService.Server.Classes.Modules.ClassCalculators)
local Notification = require(ServerScriptService.Server.Classes.Modules.Notification)
local Pathfinding = require(ServerScriptService.Server.Classes.Modules.Pathfinding)
local Formulas = require(ServerScriptService.Server.Math.Formulas)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local JobManagerType = require(ReplicatedStorage.Shared.Types.Managers.JobManagerType)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)

local JobManager = {}
JobManager.__index = JobManager

type JobManager = typeof(setmetatable({} :: JobManagerType.JobManagerInstance, JobManager))

function JobManager.New(helperState: { [string]: HelperType.HelperInstance }, jobState: { [number]: Jobs.JobState }, player: Player, teamId: number, realmId: number): JobManager
	local self = setmetatable({} :: JobManager, JobManager)
	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.RealmId = realmId

	self.Helpers = {}
	self.JobState = jobState

	self:CalculateSlotUnlockCost()

	self._cleaner = Trove.new()

	self:CreateHelpers(helperState)
	self:AttachEventListeners()
	self:AssignJobs()

	return self
end

function JobManager.CreateHelpers(self: JobManager, helperState)
	for _, helper in pairs(helperState) do
		local existing = self.Helpers[helper.Id] or nil
		if existing then continue end

		local helperClass = Helper.New(helper, self.Player, self.TeamId)
		self.Helpers[helperClass.Id] = helperClass
	end
end

function JobManager.AssignJobs(self: JobManager): ()
	for _, helper in pairs(self.Helpers) do
		if helper.CurrentAssignment > 0 then self:AssignHelper(helper.Id, helper.CurrentAssignment) end
	end
end

function JobManager.GetAssignedHelpersForJob(self: JobManager, jobId: number)
	local job: Jobs.JobState = self.JobState[jobId]
	if job then return job.Slots.AssignedHelpers end
	return nil
end

function JobManager.CalculateSlotUnlockCost(self: JobManager)
	if not self.JobState then return end

	for _, job in ipairs(self.JobState) do
		local jobSlots = job.Slots
		jobSlots.UnlockCost = ClassCalculators.CalculateBaseValue(Formulas.JOBSLOT.BaseCost, job.Tier, self.RealmId)

		local skipEvent = true
		DataService.SaveJobState(self.Player, job, skipEvent)
	end
end

function JobManager.NumOfSlotsAvailable(self: JobManager, jobId: number): number
	local job: Jobs.JobState = self.JobState[jobId]
	if job then
		local assignedHelpers = self:GetAssignedHelpersForJob(jobId)
		if not assignedHelpers then assignedHelpers = {} end

		local maxSlots = job.Slots.MaxSlots
		local lockedSlots = job.Slots.LockedSlots

		local unlockedSlots = maxSlots - lockedSlots

		local availableSlots = unlockedSlots - #assignedHelpers

		return math.max(0, availableSlots)
	end

	return -1
end

function JobManager.UpdateNewJobState(self: JobManager, jobId: number, helper: HelperType.HelperInstance)
	local currentJob = helper.CurrentAssignment

	-- If the helper is changing jobs
	if currentJob ~= jobId then
		-- update old jobstate by removing the helper and save
		local oldJob: Jobs.JobState = self.JobState[currentJob]
		if oldJob then
			local assignedHelpersTable = oldJob.Slots.AssignedHelpers

			for i, assignedHelper: Jobs.AssignedHelper in ipairs(assignedHelpersTable) do
				if assignedHelper.Id == helper.Id then assignedHelpersTable[i] = nil end
			end

			DataService.SaveJobState(self.Player, oldJob)
		end
	end

	-- then we update the new state
	local job: Jobs.JobState = self.JobState[jobId]
	if job then
		local assignedHelpersTable = job.Slots.AssignedHelpers

		-- Prevents duplicates
		for i, assignedHelper: Jobs.AssignedHelper in ipairs(assignedHelpersTable) do
			if assignedHelper.Id == helper.Id then return end
		end

		local preparedData = {
			Id = helper.Id,
			Name = helper:GetName(),
			Level = helper.Level,
			QualityId = helper.QualityId,
		}
		assignedHelpersTable[#assignedHelpersTable + 1] = preparedData
		DataService.SaveJobState(self.Player, job)
	end
end

function JobManager.UnlockJob(self: JobManager, jobId: number)
	local job: Jobs.JobState = self.JobState[jobId]
	if job then
		local isUnlocked = job.Unlocked

		if not isUnlocked then job.Unlocked = true end

		DataService.SaveJobState(self.Player, job)
	end
end

function JobManager.PurchaseJobSlot(self: JobManager, jobId: number)
	local job: Jobs.JobState = self.JobState[jobId]
	if job then
		local jobSlots = job.Slots
		local lockedSlots = jobSlots.LockedSlots
		local amount = jobSlots.UnlockCost
		if not amount then return end

		if lockedSlots == 0 then
			print("All locked slots are already unlocked", job)
			return
		end

		if not DataService.CanAfford(self.Player, FFGEnum.CURRENCY_TYPES.Gold, amount) then
			Notification.SendAlert(self.Player, "Not enough gold.")
			return
		end
		DataService.Spend(self.Player, FFGEnum.CURRENCY_TYPES.Gold, amount)

		job.Slots.LockedSlots = lockedSlots - 1

		DataService.SaveJobState(self.Player, job)
	end
end

function JobManager.AssignHelper(self: JobManager, helperId: number, jobId: number): ()
	if not helperId or not jobId then return end
	local helper = self.Helpers and self.Helpers[helperId] or nil

	if jobId ~= 0 then
		if not helper or helper and helper.CurrentAssignment ~= jobId then
			if self:NumOfSlotsAvailable(jobId) == 0 then
				print("No JobSlots available for JobId: ", jobId)
				return
			elseif self:NumOfSlotsAvailable(jobId) == -1 then
				error(`No Jobstate or assignedHelpers: {self.JobState}`)
				return
			end
		end
	end

	local isNewAssignment = true
	if not helper then
		local inventory = DataService.GetPlayerInventory(self.Player)
		if not inventory then return end

		local savedHelperState = inventory[helperId]
		local newHelperClass = Helper.New(savedHelperState, self.Player, self.TeamId)

		self.Helpers[newHelperClass.Id] = newHelperClass

		helper = newHelperClass
	end

	if helper.CurrentAssignment == jobId then isNewAssignment = false end

	if isNewAssignment then self:UpdateNewJobState(jobId, helper) end

	helper:AssignJob(jobId, isNewAssignment)
end

function JobManager.BeginAction(self: JobManager, actionType: string, helper: HelperType.HelperInstance, jobId: number)
	local isGatherAction = actionType == "Gather"

	local nameplate: BillboardGui? = helper.Model and helper.Model:FindFirstChild("EntityNameplate")
	local progressBarFrame
	local progressBar
	if nameplate then
		progressBarFrame = nameplate:FindFirstChild("ProgressContainer")
		if progressBarFrame then
			nameplate.Enabled = true
			progressBar = progressBarFrame:FindFirstChild("ProgressBar", true)
			ProgressBar.Show(progressBarFrame)
		end
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
					if progressBar then ProgressBar.Update(progressBar, timePassed, waitTime) end
					task.wait(0.5)
				end
			end

			if finished then
				ProgressBar.Hide(progressBarFrame)
				ProgressBar.Reset(progressBar)
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
					local resourceCount: number = helper.ResourceInStorage
					local helperStats: HelperType.HelperStats = helper.Stats

					local currencyAmount: number
					if helper.JobCategory == FFGEnum.JOB_CATEGORY.Transporting then
						-- Multiply by the base value of fish (x2)
						local baseValue = resourceCount * Formulas.FISH_BASEVALUE

						-- Get the Fish Value buff from the Helper and calculate
						local priceMulti: number = 1 + helperStats.FishValue
						currencyAmount = baseValue * priceMulti
					end
					if not currencyAmount then error("No currencyAmount was defined") end

					DataService.Earn(self.Player, FFGEnum.CURRENCY_TYPES.Gold, currencyAmount)
					helper:ClearStorage()
					self:StartJob(helper, jobId)
				end
			else
				ProgressBar.Hide(progressBarFrame)
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
		Pathfinding.GoGatherSpot(jobId, helper.Id, helper.Model, self.Player, self.TeamId)
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
	if assignJobEvent then
		self._cleaner:Add(assignJobEvent.OnServerEvent:Connect(function(player: Player, helperId: string, jobId: number)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if not helperId or not jobId then return end

			self:AssignHelper(helperId, jobId)
		end))
	end

	-- Remote event to handle purchasing of job slots
	local purchaseJobSlotEvent = Events.GetRemote(Events.RemoteNames.PurchaseJobSlot)
	if purchaseJobSlotEvent then
		self._cleaner:Add(purchaseJobSlotEvent.OnServerEvent:Connect(function(player: Player, jobId: number)
			if self.Player ~= player or self.Owner ~= player.UserId then return end
			if not jobId then return end

			self:PurchaseJobSlot(jobId)
		end))
	end

	-- Remote event to update internal state when helpers are purchased
	local helperPurchased = Events.GetBindableEvent(Events.BindableNames.PurchasedHelper)
	if helperPurchased then
		self._cleaner:Add(helperPurchased.Event:Connect(function(data)
			local player: Player = data.Player
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			local helperState = DataService.GetPlayerInventory(self.Player)
			self:CreateHelpers(helperState)
		end))
	end

	-- Bindable Events for handling job cycle
	local helperAtGatheringLoc = Events.GetBindableEvent(Events.BindableNames.HelperAtGatheringLoc)
	if helperAtGatheringLoc then
		self._cleaner:Add(helperAtGatheringLoc.Event:Connect(function(data)
			local helperId: string = data.Id
			local jobId: number = data.JobId
			local player: Player = data.Player

			if self.Player ~= player or self.Owner ~= player.UserId then return end
			local helper = self.Helpers[helperId]
			if not helper then return end

			self:BeginGathering(helper, jobId)
		end))
	end

	local helperAtUnloadingLoc = Events.GetBindableEvent(Events.BindableNames.HelperAtUnloadingLoc)
	if helperAtUnloadingLoc then
		self._cleaner:Add(helperAtUnloadingLoc.Event:Connect(function(data)
			local helperId: string = data.Id
			local jobId: number = data.JobId
			local player: Player = data.Player

			if self.Player ~= player or self.Owner ~= player.UserId then return end
			local helper = self.Helpers[helperId]
			if not helper then return end

			self:StartJob(helper, jobId)
		end))
	end

	-- //TODO - Perhaps change the name, it's confusing. This is the chainmanager sending fish to me
	local sendStorageFish = Events.GetBindableEvent(Events.BindableNames.SendStorageFish)
	if sendStorageFish then
		self._cleaner:Add(sendStorageFish.Event:Connect(function(data: SendStorageFishData)
			local helperId: string = data.HelperId
			local jobId: number = data.JobId
			local player: Player = data.Player

			if self.Player ~= player or self.Owner ~= player.UserId then return end
			local helper = self.Helpers[helperId]
			if not helper then return end

			if helper.CurrentAssignment ~= jobId then return end

			local amount = data.Amount
			if amount then helper:AddResource(amount) end
			Pathfinding.GoUnloadSpot(jobId, helper.Id, helper.Model, self.Player, self.TeamId)
		end))
	end

	local jobDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetJobData)
	if jobDataEvent then jobDataEvent.OnServerInvoke = function(player: Player)
		if self.Player ~= player then return end
		return self.JobState
	end end

	local unlockJobEvent = Events.GetBindableEvent(Events.BindableNames.JobUnlocked)
	if unlockJobEvent then unlockJobEvent.Event:Connect(function(jobId: number)
		if jobId and typeof(jobId) == "number" then self:UnlockJob(jobId) end
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
