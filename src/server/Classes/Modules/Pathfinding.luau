local PFS = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Jobs = require(ServerScriptService.Server.Modules.Jobs.Jobs)

local PathFinding = {}

function PathFinding.GetRoute(jobId: number)
	return Jobs.Data[jobId].Route
end

-- Shared pathfinding function to reduce code duplication
local function pathfindToDestinations(npc, humanoid, helperId, destinations, completionEvent, jobId)
	-- Function to create path to a single destination
	local function createPathToDestination(startPos, destination)
		local path = PFS:CreatePath({
			AgentCanJump = true,
			AgentCanClimb = true,
			AgentRadius = 2,
			AgentHeight = 5,
			Costs = {
				Water = math.huge,
			},
		})

		-- Use task.spawn instead of coroutines for async operations
		local pathSuccess = false
		local waypoints = nil

		task.spawn(function()
			local success, errorMessage = pcall(function()
				path:ComputeAsync(startPos, destination)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				waypoints = path:GetWaypoints()
				pathSuccess = true
			else
				warn("Pathfinding failed:", errorMessage or path.Status)
				-- Try direct movement as fallback
				waypoints = { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
				pathSuccess = true
			end
		end)

		-- Wait for path computation with timeout
		local timeoutStart = tick()
		while not pathSuccess and tick() - timeoutStart < 2 do
			RunService.Heartbeat:Wait()
		end

		if not pathSuccess then
			-- Fallback to direct movement immediately
			return { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
		end

		return waypoints
	end

	-- Improved movement function with smoother transitions
	local function moveAlongWaypoints(waypoints, destinationIndex)
		if not waypoints or #waypoints == 0 then return false end

		local currentWaypointIndex = 1

		-- Movement loop with better performance
		while currentWaypointIndex <= #waypoints do
			if not npc.Parent or not humanoid.Parent then return false end

			local waypoint = waypoints[currentWaypointIndex]

			-- Handle jump waypoints
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end

			-- Move to waypoint
			humanoid:MoveTo(waypoint.Position)

			-- Wait for movement or timeout
			local moveStartTime = tick()
			local moveTimeout = 8
			local reachedWaypoint = false

			while not reachedWaypoint and tick() - moveStartTime < moveTimeout do
				if not npc.Parent or not humanoid.Parent then return false end

				-- Check if close to current waypoint
				local distanceToWaypoint = (npc.PrimaryPart.Position - waypoint.Position).Magnitude

				-- More aggressive waypoint completion - reduces stopping
				if distanceToWaypoint < 6 then
					reachedWaypoint = true
				elseif tick() - moveStartTime > 1 and distanceToWaypoint > 20 then
					-- If NPC is far away after 1 second, it might be stuck
					warn("Helper", helperId, "might be stuck, skipping waypoint", currentWaypointIndex)
					reachedWaypoint = true
				end

				-- Use Heartbeat for better performance
				RunService.Heartbeat:Wait()
			end

			if not reachedWaypoint then warn("Helper", helperId, "timed out at waypoint", currentWaypointIndex) end

			currentWaypointIndex = currentWaypointIndex + 1
		end

		return true
	end

	-- Main pathfinding loop
	task.spawn(function()
		for i, destination in ipairs(destinations) do
			if not npc.Parent or not humanoid.Parent then
				warn("Helper", helperId, "was destroyed during pathfinding")
				return
			end

			-- Create path from current position to destination
			local waypoints = createPathToDestination(npc.PrimaryPart.Position, destination)

			if not waypoints then
				warn("Failed to create path to destination", i, "for helper", helperId)
				return
			end

			-- Move along the waypoints for this destination
			local success = moveAlongWaypoints(waypoints, i)

			if not success then
				warn("Failed to complete movement to destination", i, "for helper", helperId)
				return
			end
		end

		-- Fire completion event
		if Events.GetBindableEvent(completionEvent) then Events.FireBindableEvent(completionEvent, { Id = helperId, JobId = jobId }) end
	end)
end

function PathFinding.GoGatherSpot(jobId: number, helperId: string, npcModel: Model, player: Player)
	local npc = npcModel
	local humanoid: Humanoid = npc:WaitForChild("Humanoid")

	if not npc.PrimaryPart then
		warn("NPC has no primary part")
		return
	end

	local route = PathFinding.GetRoute(jobId)
	local reversed = TableUtil.Reverse(route)

	if not reversed or #reversed == 0 then
		warn("Invalid route for job", jobId)
		return
	end

	-- Skip the first destination since NPC is teleported there
	if #reversed > 1 then
		table.remove(reversed, 1)
	else
		Events.FireBindableEvent(Events.BindableNames.HelperAtGatheringLoc, { Id = helperId, JobId = jobId })
		return
	end

	pathfindToDestinations(npc, humanoid, helperId, reversed, Events.BindableNames.HelperAtGatheringLoc, jobId)
end

function PathFinding.GoUnloadSpot(jobId: number, helperId: string, npcModel: Model, player: Player)
	local npc = npcModel
	local humanoid: Humanoid = npc:WaitForChild("Humanoid")

	if not npc.PrimaryPart then
		warn("NPC has no primary part")
		return
	end

	local route = PathFinding.GetRoute(jobId)

	if not route or #route == 0 then
		warn("Invalid route for job", jobId)
		return
	end

	-- Skip the first destination since NPC is already there
	if #route > 1 then
		table.remove(route, 1)
	else
		Events.FireBindableEvent(Events.BindableNames.HelperAtUnloadingLoc, { Id = helperId, JobId = jobId })
		return
	end

	pathfindToDestinations(npc, humanoid, helperId, route, Events.BindableNames.HelperAtUnloadingLoc, jobId)
end

return PathFinding
