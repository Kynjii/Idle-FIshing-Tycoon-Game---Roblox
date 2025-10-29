local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local taggedJobLocations = CollectionService:GetTagged("JobLocation")

function getJobLocation(jobId: string): CFrame?
	for _, taggedJobLocation: Part in ipairs(taggedJobLocations) do
		local taggedJobLocationTeamId = taggedJobLocation:GetAttribute(FFGEnum.ATTRIBUTES.JobId)
		if taggedJobLocationTeamId == jobId then return taggedJobLocation.Position end
	end

	return nil
end

local Jobs = {}
Jobs.Data = {
	["job_id_1"] = {
		Id = "job_id_1",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_1",
		Location = getJobLocation("job_id_1"),
	},
	["job_id_2"] = {
		Id = "job_id_2",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_2",
		Location = getJobLocation("job_id_2"),
	},
	["job_id_3"] = {
		Id = "job_id_3",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_3",
		Location = getJobLocation("job_id_3"),
	},
	["job_id_4"] = {
		Id = "job_id_4",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_4",
		Location = getJobLocation("job_id_4"),
	},
	["job_id_5"] = {
		Id = "job_id_5",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_5",
		Location = getJobLocation("job_id_5"),
	},
	["job_id_6"] = {
		Id = "job_id_6",
		Category = FFGEnum.JOB_CATEGORY.Transporting,
		Ref = "FL_6",
		Location = getJobLocation("job_id_6"),
	},
}

return Jobs
