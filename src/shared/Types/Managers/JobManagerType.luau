local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local JobManagerType = {}

export type JobManagerInstance = {
	-- Props
	Player: Player,
	TeamId: number,
	Owner: number,

	-- State
	Helpers: { [string]: HelperType.HelperInstance },
	JobState: { [number]: Jobs.JobState },

	-- Main Actions
	CreateHelpers: (self: JobManagerInstance, { [string]: HelperType.HelperInstance }) -> (),
	AssignJobs: (self: JobManagerInstance) -> (),
	AssignHelper: (self: JobManagerInstance, helperId: number, jobId: number) -> (),
	NumOfSlotsAvailable: (self: JobManagerInstance, jobId: number) -> number,

	-- Attribute listeners
	AttachAttListeners: (self: JobManagerInstance) -> (),

	-- Cleanup
	_cleaner: any?,
	Destroy: (self: JobManagerInstance) -> (),
}

export type JobManager = {
	New: (realmData: { [string]: any }, tier: number, player: Player, teamId: number, buildingClasses: { [number]: { [string]: any } }) -> JobManagerInstance,
}

return JobManagerType
