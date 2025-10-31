local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local taggedJobLocations = CollectionService:GetTagged("JobLocation")

function getJobLocation(jobId: number): Vector3
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

function getJobRoute(jobId: number): { [number]: Vector3 }
	local route = {}
	for _, taggedJobLocation: Part in ipairs(taggedJobLocations) do
		local taggedJobLocationJobId = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.JobId)
		if taggedJobLocationJobId ~= jobId then return end

		local pathStep = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.PathStep)
		route[pathStep] = taggedJobLocation.Position
	end

	return route
end

local Jobs = {}
Jobs.Data = {
	[1] = {
		Id = 1,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_1",
		Location = getJobLocation(1),
		Route = getJobRoute(1),
		MaxSlots = 3,
	},
	[2] = {
		Id = 2,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_2",
		Location = getJobLocation(2),
		Route = getJobRoute(2),
		MaxSlots = 3,
	},
	[3] = {
		Id = 3,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_3",
		Location = getJobLocation(3),
		Route = getJobRoute(3),
		MaxSlots = 3,
	},
	[4] = {
		Id = 4,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_4",
		Location = getJobLocation(4),
		Route = getJobRoute(4),
		MaxSlots = 3,
	},
	[5] = {
		Id = 5,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_5",
		Location = getJobLocation(5),
		Route = getJobRoute(5),
		MaxSlots = 3,
	},
	[6] = {
		Id = 6,
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_6",
		Location = getJobLocation(6),
		Route = getJobRoute(6),
		MaxSlots = 3,
	},
}

function Jobs.GetMaxSlots(): { [number]: number }
	local data = {}
	for i, job in ipairs(Jobs.Data) do
		data[i] = job.MaxSlots
	end

	return data
end

return Jobs
