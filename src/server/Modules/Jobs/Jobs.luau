local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local taggedJobLocations = CollectionService:GetTagged("JobLocation")

export type JobState = {
	Id: number,
	Category: "Fishing" | "Woodcutting" | "Mining" | "Transporting",
	Label: string,
	Location: Vector3?,
	Route: { Vector3 }?,
	Slots: {
		MaxSlots: number,
		LockedSlots: number,
		AssignedHelpers: {
			[number]: { Name: string, Level: number, QualityId: number },
		},
	},
	Player: Player,
}

local Jobs = {}
Jobs.Data = {
	[1] = {
		Id = 1,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 1",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
	[2] = {
		Id = 2,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 2",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
	[3] = {
		Id = 3,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 3",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
	[4] = {
		Id = 4,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 4",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
	[5] = {
		Id = 5,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 5",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
	[6] = {
		Id = 6,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Label = "Pier 6",
		Slots = {
			MaxSlots = 3,
			LockedSlots = 2,
			AssignedHelpers = {},
		},
	},
}

function Jobs.GetJobLocation(jobId: number): Vector3
	local position = nil
	for _, taggedJobLocation: Part in ipairs(taggedJobLocations) do
		local taggedJobLocationJobId = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.JobId)
		if taggedJobLocationJobId ~= jobId then continue end

		local isUnloadLoc = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.UnloadLoc)
		if not isUnloadLoc then continue end
		position = taggedJobLocation.Position
	end

	return position
end

function Jobs.GetJobRoute(jobId: number): { [number]: Vector3 }
	local route = {}
	for _, taggedJobLocation: Part in ipairs(taggedJobLocations) do
		local taggedJobLocationJobId = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.JobId)
		if taggedJobLocationJobId ~= jobId then return end

		local pathStep = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.PathStep)
		route[pathStep] = taggedJobLocation.Position
	end

	return route
end

function Jobs.GetMaxSlots(): { [number]: number }
	local data = {}
	for i, job in ipairs(Jobs.Data) do
		data[i] = job.Slots.MaxSlots
	end

	return data
end

return Jobs
