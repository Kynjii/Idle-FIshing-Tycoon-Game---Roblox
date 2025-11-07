local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local SimplePath = require(ServerScriptService.Server.Libs.SimplePath)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)

local PathFinding = {}

function PathFinding.GetRoute(jobId: number, teamId: number)
	return Jobs.GetJobRoute(jobId, teamId)
end

local function pathfindToDestinations(npc, helperId, destinations, completionEvent, jobId, player, teamId)
	local function createPathToDestination()
		local agentParameters = {
			AgentCanJump = true,
			AgentCanClimb = true,
			AgentRadius = 2,
			AgentHeight = 5,
			Costs = {
				Water = math.huge,
				PierLeg = 900,
			},
		}

		local path = SimplePath.new(npc, agentParameters)

		return path
	end

	local path = createPathToDestination()
	if not path then error(`No path found: {path}, {npc}, {helperId}, {jobId}, {player}, {teamId}`) end
	local IsStudio = RunService:IsStudio()
	if IsStudio then path.Visualize = true end
	local goalNum = 1
	local destination = destinations[goalNum]

	path.Blocked:Connect(function()
		path:Run(destination)
	end)

	path.Error:Connect(function(errorType)
		path:Run(destination)
	end)

	path:Run(destination)

	path.Reached:Connect(function()
		goalNum += 1
		if destinations[goalNum] then
			destination = destinations[goalNum]
			path:Run(destination)
		else
			-- Fire completion event
			if Events.GetBindableEvent(completionEvent) then Events.FireBindableEvent(completionEvent, { Id = helperId, JobId = jobId, Player = player }) end
		end
	end)
end

function PathFinding.GoGatherSpot(jobId: number, helperId: string, npcModel: Model, player: Player, teamId: number)
	local npc = npcModel

	if not npc.PrimaryPart then
		warn("NPC has no primary part")
		return
	end

	local route = PathFinding.GetRoute(jobId, teamId)
	local reversed = TableUtil.Reverse(route)

	if not reversed or #reversed == 0 then
		warn("Invalid route for job", jobId)
		return
	end

	-- Skip the first destination since NPC is teleported there
	if #reversed > 1 then
		table.remove(reversed, 1)
	else
		Events.FireBindableEvent(Events.BindableNames.HelperAtGatheringLoc, { Id = helperId, JobId = jobId, Player = player })
		return
	end

	pathfindToDestinations(npc, helperId, reversed, Events.BindableNames.HelperAtGatheringLoc, jobId, player, teamId)
end

function PathFinding.GoUnloadSpot(jobId: number, helperId: string, npcModel: Model, player: Player, teamId: number)
	local npc = npcModel

	if not npc.PrimaryPart then
		warn("NPC has no primary part")
		return
	end

	local route = PathFinding.GetRoute(jobId, teamId)

	if not route or #route == 0 then
		warn("Invalid route for job", jobId)
		return
	end

	-- Skip the first destination since NPC is already there
	if #route > 1 then
		table.remove(route, 1)
	else
		Events.FireBindableEvent(Events.BindableNames.HelperAtUnloadingLoc, { Id = helperId, JobId = jobId, Player = player })
		return
	end

	pathfindToDestinations(npc, helperId, route, Events.BindableNames.HelperAtUnloadingLoc, jobId, player, teamId)
end

return PathFinding
