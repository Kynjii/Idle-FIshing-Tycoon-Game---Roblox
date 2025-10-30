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
		table.remove(reversed, 1) -- Remove first destination
	else
		-- If only one destination and we're teleported there, we're done!
		local helperAtGatheringLocationEvent = Events.GetBindableEvent(Events.BindableNames.HelperAtGatheringLoc)
		if helperAtGatheringLocationEvent then Events.FireBindableEvent(Events.BindableNames.HelperAtGatheringLoc, { Id = helperId, JobId = jobId }) end
		return
	end

	-- Function to create path to a single destination
	local function createPathToDestination(destination)
		local path = PFS:CreatePath({
			AgentCanJump = true,
			AgentCanClimb = true,
			AgentRadius = 2,
			AgentHeight = 5,
			Costs = {
				Water = math.huge,
			},
		})

		-- Compute path asynchronously with timeout
		local pathSuccess = false
		local waypoints = nil

		spawn(function()
			local success, errorMessage = pcall(function()
				path:ComputeAsync(npc.PrimaryPart.Position, destination)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				waypoints = path:GetWaypoints()
				pathSuccess = true
			else
				warn("Pathfinding failed to", destination, ":", errorMessage or path.Status)
				-- Try direct movement as fallback
				if path.Status == Enum.PathStatus.NoPath then
					waypoints = { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
					pathSuccess = true
				end
			end
		end)

		-- Wait for path computation with timeout
		local timeoutStart = tick()
		while not pathSuccess and tick() - timeoutStart < 5 do
			RunService.Heartbeat:Wait()
		end

		if not pathSuccess then
			warn("Pathfinding timed out for helper", helperId, "to destination", destination)
			-- Try direct movement as last resort
			return { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
		end

		return waypoints
	end

	-- Function to move along waypoints for one destination
	local function moveAlongWaypoints(waypoints, destinationIndex)
		if not waypoints then return false end

		local moveTimeout = 15

		for i, waypoint in ipairs(waypoints) do
			if not npc.Parent or not humanoid.Parent then
				return false -- NPC was destroyed
			end

			-- Handle jump waypoints
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end

			-- Move to waypoint
			humanoid:MoveTo(waypoint.Position)

			-- Wait for movement with timeout
			local moveStartTime = tick()
			local reachedWaypoint = false

			local connection
			connection = humanoid.MoveToFinished:Connect(function(reached)
				reachedWaypoint = true
				if connection then connection:Disconnect() end
			end)

			-- Wait with timeout and yield properly
			while not reachedWaypoint and tick() - moveStartTime < moveTimeout do
				RunService.Heartbeat:Wait()

				-- Check if NPC is close enough to waypoint (stuck detection)
				if tick() - moveStartTime > 3 then
					local distanceToWaypoint = (npc.PrimaryPart.Position - waypoint.Position).Magnitude
					if distanceToWaypoint < 8 then
						reachedWaypoint = true
						break
					end
				end
			end

			if connection then connection:Disconnect() end

			if not reachedWaypoint then
				warn("Helper", helperId, "got stuck at waypoint", i, "for destination", destinationIndex + 1) -- +1 since we skipped first
				return false
			end
		end

		return true
	end

	-- Main pathfinding loop - go through remaining destinations
	spawn(function()
		local completedAllDestinations = false

		for i, destination in ipairs(reversed) do
			if not npc.Parent or not humanoid.Parent then
				warn("Helper", helperId, "was destroyed during pathfinding")
				return
			end

			-- Create path to this destination
			local waypoints = createPathToDestination(destination)

			if not waypoints then
				warn("Failed to create path to destination", i + 1, "for helper", helperId)
				return
			end

			-- Move along the waypoints for this destination
			local success = moveAlongWaypoints(waypoints, i)

			if not success then
				warn("Failed to complete movement to destination", i + 1, "for helper", helperId)
				return
			end
		end

		-- Only fire event if ALL destinations were completed successfully
		completedAllDestinations = true

		-- Fire event when all destinations reached
		local helperAtGatheringLocationEvent = Events.GetBindableEvent(Events.BindableNames.HelperAtGatheringLoc)
		if helperAtGatheringLocationEvent and completedAllDestinations then Events.FireBindableEvent(Events.BindableNames.HelperAtGatheringLoc, { Id = helperId, JobId = jobId }) end

		task.wait(0.2)
	end)
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
		table.remove(route, 1) -- Remove first destination
	else
		-- If only one destination and we're teleported there, we're done!
		local helperAtUnloadingLocEvent = Events.GetBindableEvent(Events.BindableNames.HelperAtUnloadingLoc)
		if helperAtUnloadingLocEvent then Events.FireBindableEvent(Events.BindableNames.HelperAtUnloadingLoc, { Id = helperId, JobId = jobId }) end
		return
	end

	-- Function to create path to a single destination
	local function createPathToDestination(destination)
		local path = PFS:CreatePath({
			AgentCanJump = true,
			AgentCanClimb = true,
			AgentRadius = 2,
			AgentHeight = 5,
			Costs = {
				Water = math.huge,
			},
		})

		-- Compute path asynchronously with timeout
		local pathSuccess = false
		local waypoints = nil

		spawn(function()
			local success, errorMessage = pcall(function()
				path:ComputeAsync(npc.PrimaryPart.Position, destination)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				waypoints = path:GetWaypoints()
				pathSuccess = true
			else
				warn("Pathfinding failed to", destination, ":", errorMessage or path.Status)
				-- Try direct movement as fallback
				if path.Status == Enum.PathStatus.NoPath then
					waypoints = { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
					pathSuccess = true
				end
			end
		end)

		-- Wait for path computation with timeout
		local timeoutStart = tick()
		while not pathSuccess and tick() - timeoutStart < 5 do
			RunService.Heartbeat:Wait()
		end

		if not pathSuccess then
			warn("Pathfinding timed out for helper", helperId, "to destination", destination)
			-- Try direct movement as last resort
			return { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
		end

		return waypoints
	end

	-- Function to move along waypoints for one destination
	local function moveAlongWaypoints(waypoints, destinationIndex)
		if not waypoints then return false end

		local moveTimeout = 15

		for i, waypoint in ipairs(waypoints) do
			if not npc.Parent or not humanoid.Parent then
				return false -- NPC was destroyed
			end

			-- Handle jump waypoints
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end

			-- Move to waypoint
			humanoid:MoveTo(waypoint.Position)

			-- Wait for movement with timeout
			local moveStartTime = tick()
			local reachedWaypoint = false

			local connection
			connection = humanoid.MoveToFinished:Connect(function(reached)
				reachedWaypoint = true
				if connection then connection:Disconnect() end
			end)

			-- Wait with timeout and yield properly
			while not reachedWaypoint and tick() - moveStartTime < moveTimeout do
				RunService.Heartbeat:Wait()

				-- Check if NPC is close enough to waypoint (stuck detection)
				if tick() - moveStartTime > 3 then
					local distanceToWaypoint = (npc.PrimaryPart.Position - waypoint.Position).Magnitude
					if distanceToWaypoint < 8 then
						reachedWaypoint = true
						break
					end
				end
			end

			if connection then connection:Disconnect() end

			if not reachedWaypoint then
				warn("Helper", helperId, "got stuck at waypoint", i, "for destination", destinationIndex + 1) -- +1 since we skipped first
				return false
			end
		end

		return true
	end

	-- Main pathfinding loop - go through remaining destinations
	spawn(function()
		local completedAllDestinations = false

		for i, destination in ipairs(route) do
			if not npc.Parent or not humanoid.Parent then
				warn("Helper", helperId, "was destroyed during pathfinding")
				return
			end

			-- Create path to this destination
			local waypoints = createPathToDestination(destination)

			if not waypoints then
				warn("Failed to create path to destination", i + 1, "for helper", helperId)
				return
			end

			-- Move along the waypoints for this destination
			local success = moveAlongWaypoints(waypoints, i)

			if not success then
				warn("Failed to complete movement to destination", i + 1, "for helper", helperId)
				return
			end
		end

		-- Only fire event if ALL destinations were completed successfully
		completedAllDestinations = true

		-- Fire event when all destinations reached
		local helperAtUnloadingLocEvent = Events.GetBindableEvent(Events.BindableNames.HelperAtUnloadingLoc)
		if helperAtUnloadingLocEvent and completedAllDestinations then Events.FireBindableEvent(Events.BindableNames.HelperAtUnloadingLoc, { Id = helperId, JobId = jobId }) end

		task.wait(0.2)
	end)
end

return PathFinding
