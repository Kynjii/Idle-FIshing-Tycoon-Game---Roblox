local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Fish = require(ServerScriptService.Server.Classes.Fish)
local Difficulty = require(ServerScriptService.Server.Classes.Modules.Difficulty)
local Notification = require(ServerScriptService.Server.Classes.Modules.Notification)
local FishingXP = require(ServerScriptService.Server.Data.FishingXP)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local Animator = require(ReplicatedStorage.Shared.Utils.Animator)

-- //SECTION - Tagged Fishing Locations within Workspace
local taggedFishingLocs = CollectionService:GetTagged("FishingLocation")
-- //!SECTION

-- //SECTION - Fishing Sessions Management
local FishingSessions = {}
-- //!SECTION

local FishingManager = {}
FishingManager.__index = FishingManager

type FishingManager = typeof(setmetatable({}, FishingManager))

function FishingManager.New(player: Player, teamId: number, currentRealm: number): FishingManager
	local self = setmetatable({}, FishingManager)

	self.Player = player
	self.Owner = self.Owner or player.UserId
	self.TeamId = teamId
	self.RealmId = currentRealm
	self.CurrentFishingLocTier = 1
	self.CurrentFishingLocId = 1
	self.FishingLocations = self:GetLocations()
	self.GeneratedFish = {}
	self.FishingSessions = FishingSessions

	self._cleaner = Trove.new()

	self:SetupProximityPrompts()

	self:AttachAttListeners()

	return self
end

function FishingManager.GetLocations(self: FishingManager)
	local locations = {}

	local index = 1
	for _, location in pairs(taggedFishingLocs) do
		local taggedLocationTeamId = location:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedLocationTeamId and taggedLocationTeamId ~= self.TeamId then continue end

		locations[index] = location
		index += 1
	end

	return locations
end

function FishingManager.StartFishingSession(self: FishingManager, player: Player, fishConfig: Fish.Fish, tier: number)
	local sessionId = HttpService:GenerateGUID(false)

	-- Calculate difficulty factors for the minigame
	local playerData = { FishingLevel = 1 } -- TODO: Get actual player data
	local rodData = self:GetPlayerRod()
	local difficultyFactor = Difficulty.GetDifficultyFactor(playerData, rodData, fishConfig)
	local playerPower = Difficulty.GetPlayerPower(playerData, rodData)
	local fishPower = Difficulty.GetFishPower(fishConfig)
	local powerRatio = playerPower / math.max(fishPower, 1)

	-- Calculate escape attempts based on power ratio (higher if player is stronger)
	local baseEscapeAttempts = 3
	local escapeAttempts = math.floor(baseEscapeAttempts + (powerRatio - 1.0) * 2) -- +2 attempts per power ratio above 1
	escapeAttempts = math.clamp(escapeAttempts, 1, 6) -- Min 1, max 6 attempts

	-- Calculate minimum hits before escape attempts can trigger (higher if player is stronger)
	local baseMinHits = 3
	local minHitsBeforeEscape = math.floor(baseMinHits + (powerRatio - 1.0) * 2) -- +2 hits per power ratio above 1
	minHitsBeforeEscape = math.clamp(minHitsBeforeEscape, 1, 8) -- Min 1, max 8 hits

	-- Calculate minigame modifiers based on power ratio and difficulty
	local minigameConfig = {
		-- Hit zone size: Better when overpowered, harder when underpowered
		HitZoneSize = math.clamp(0.20 + (rodData.Stats.LineControl * 0.02) + (powerRatio - 1.0) * 0.1, 0.08, 0.40),

		-- Marker speed: Slower when underpowered (struggle), faster when overpowered (easy)
		MarkerSpeed = math.clamp(0.6 + (powerRatio - 1.0) * 0.4 - (rodData.Stats.Stability * 0.05), 0.15, 2.5),

		-- HP decay rate: Reduced when overpowered
		DecayRate = math.clamp(0.8 + (difficultyFactor * 0.8) - (powerRatio - 1.0) * 0.4 - (rodData.Stats.Stability * 0.15), 0.2, 3.0),

		-- Heal amount per hit: Increased when overpowered
		HealMultiplier = math.clamp(1.0 + (rodData.Stats.ReelPower * 0.02) + (powerRatio - 1.0) * 0.2 - (difficultyFactor * 0.15), 0.4, 2.5),

		-- Fish escape attempts: More forgiving when player is stronger
		EscapeAttempts = escapeAttempts,

		-- Minimum hits before escape attempts can trigger: Higher for stronger players
		MinHitsBeforeEscape = minHitsBeforeEscape,
	}

	self.FishingSessions[sessionId] = {
		Player = player,
		Fish = fishConfig,
		Tier = tier,
		StartedAt = os.clock(),
		DifficultyFactor = difficultyFactor,
		MinigameConfig = minigameConfig,
	}

	-- Send fishConfig + sessionId + difficulty config to client
	Events.FireEvent(Events.RemoteNames.StartFishingMiniGame, player, {
		Fish = fishConfig,
		Rod = rodData,
		Tier = tier,
		SessionId = sessionId,
		MinigameConfig = minigameConfig, -- NEW: Send difficulty-based config
	})

	return sessionId
end

function FishingManager.ValidateAndScoreFishing(self: FishingManager, player: Player, sessionId: string, result: {})
	local session = self.FishingSessions[sessionId]
	if not session then return false, "Invalid session", false end
	if session.Player ~= player then return false, "Wrong player", false end

	local now = os.clock()
	local elapsed = now - session.StartedAt

	-- Anti-cheat: Check duration
	if elapsed < 1.0 then
		print("Fishing validation failed: Too fast completion")
		return false, "Too fast", false
	end

	if elapsed > 300 then -- Max 5 minutes
		print("Fishing validation failed: Too slow completion")
		return false, "Too slow", false
	end

	-- Clamp client-reported values to prevent exploitation
	local clampedDuration = math.clamp(result.Duration or elapsed, 1, 300)
	local maxPossibleHits = math.floor(clampedDuration * 3) -- Assume max 3 hits per second
	local totalHits = math.clamp(result.TotalHits or 0, 0, maxPossibleHits)
	local perfectHits = math.clamp(result.PerfectHits or 0, 0, totalHits)

	-- Get player data for difficulty calculation
	local playerData = { FishingLevel = 1 } -- TODO: Replace with actual player data
	local rodData = self:GetPlayerRod()

	-- Calculate difficulty factor
	local difficultyFactor = Difficulty.GetDifficultyFactor(playerData, rodData, session.Fish)
	local playerPower = Difficulty.GetPlayerPower(playerData, rodData)
	local fishPower = Difficulty.GetFishPower(session.Fish)

	-- Server-side scoring system with power scaling
	local score = totalHits * 1 + perfectHits * 2

	-- Dynamic required score based on power difference
	local powerRatio = playerPower / math.max(fishPower, 1)
	local baseRequirement = 8 -- Base hits needed

	-- If player power >> fish power, much easier catch
	local scaledRequirement = baseRequirement / math.max(powerRatio, 0.5)
	local requiredScore = math.ceil(math.clamp(scaledRequirement, 1, 15)) -- Min 1, max 15

	-- Additional validation: Check if client claims success
	local clientClaimsSuccess = result.Success == true

	-- Server decision: Fish is caught if all conditions are met
	local fishCaught = clientClaimsSuccess and score >= requiredScore and elapsed >= 1.0

	print(
		string.format(
			"Fishing validation - Player: %s, Score: %d/%d, Duration: %.1fs, Difficulty: %.2f, Caught: %s",
			player.Name,
			score,
			requiredScore,
			elapsed,
			difficultyFactor,
			tostring(fishCaught)
		)
	)

	-- Debug: Show difficulty breakdown
	print(
		string.format(
			"  Fish: %s %s (Q%d, T%d) | Rod: %s (Q%d) | Player: Lvl%d",
			session.Fish.Species,
			session.Fish.Variant,
			session.Fish.QualityId,
			session.Tier,
			rodData.Name,
			rodData.QualityId,
			playerData.FishingLevel
		)
	)
	print(string.format("  Hits: %d total, %d perfect | Client claimed: %s | Time valid: %s", totalHits, perfectHits, tostring(clientClaimsSuccess), tostring(elapsed >= 1.0)))
	print(string.format("  Power: Player=%.1f vs Fish=%.1f (ratio=%.2fx) | Req=%.1f→%d", playerPower, fishPower, powerRatio, scaledRequirement, requiredScore))

	-- Store fish data before cleanup
	local fishData = session.Fish

	-- Clean up session
	self.FishingSessions[sessionId] = nil

	return true,
		"Validation complete",
		fishCaught,
		{
			Score = score,
			RequiredScore = requiredScore,
			Difficulty = difficultyFactor,
			Duration = elapsed,
			TotalHits = totalHits,
			PerfectHits = perfectHits,
			FishData = fishData,
		}
end

function FishingManager.GetRandomFish(self: FishingManager, fishingLocTier: number, fishingLocId: number)
	local fish = Fish.New({}, self.Player, self.TeamId, fishingLocTier, fishingLocId, self.RealmId)
	if fish then self.GeneratedFish[fish.Id] = fish end
	return fish
end

function FishingManager.SaveCaughtFish(self: FishingManager, caughtFish: Fish.Fish)
	if not self.GeneratedFish[caughtFish.Id] then return end

	local fish = self.GeneratedFish[caughtFish.Id]
	fish:Save()

	local updateCaughtFishEvent = Events.GetBindableEvent(Events.BindableNames.UpdateCaughtFish)
	if updateCaughtFishEvent then updateCaughtFishEvent:Fire({ Player = self.Player, Fish = self.GeneratedFish[caughtFish.Id] }) end
	local grantFishToolEvent = Events.GetBindableEvent(Events.BindableNames.FishCaught)
	if grantFishToolEvent then grantFishToolEvent:Fire({ Player = self.Player, Fish = self.GeneratedFish[caughtFish.Id]:Serialize() }) end

	Notification.SendSuccess(self.Player, `You caught a {fish.Name}`)
end

function FishingManager.GetPlayerRod(self: FishingManager)
	-- TODO: Replace with actual player rod data from inventory/equipment
	return {
		Name = "Fishing Rod of Doom",
		QualityId = 2,
		BaseDmg = 10,
		Stats = {
			ReelPower = 3, -- ★★★☆☆☆ (3/6 stars)
			LineControl = 2, -- ★★☆☆☆☆ (2/6 stars)
			Stability = 2, -- ★★☆☆☆☆ (2/6 stars)
		},
		Perks = {
			-- Example perks that could be added
			-- "Perfect Hook", "Forgiving Line", "Tide Sync"
		},
	}
end

function FishingManager.SetupProximityPrompts(self: FishingManager)
	for _, location in pairs(self.FishingLocations) do
		local taggedLocationTeamId = location:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedLocationTeamId ~= self.TeamId then continue end

		local taggedLocationTier = location:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedLocationId = location:GetAttribute(FFGEnum.ATTRIBUTES.LocationId)

		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ObjectText = `Tier {taggedLocationTier}`
		proximityPrompt.ActionText = "Begin Fishing"
		proximityPrompt:SetAttribute(FFGEnum.ATTRIBUTES.Tier, taggedLocationTier)
		proximityPrompt.Parent = location

		self._cleaner:Add(proximityPrompt.Triggered:Connect(function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			self.CurrentFishingLocTier = taggedLocationTier
			self.CurrentFishingLocId = taggedLocationId

			local fishConfig = self:GetRandomFish(taggedLocationTier, taggedLocationId)
			self:StartFishingSession(player, fishConfig, taggedLocationTier)

			proximityPrompt.Enabled = false
		end))

		local gameEndedEvent = Events.GetRemote(Events.RemoteNames.GameEnded)
		if gameEndedEvent then
			self._cleaner:Add(gameEndedEvent.OnServerEvent:Connect(function(player: Player, tier: number)
				if self.Player ~= player or self.Owner ~= player.UserId then return end

				local promptTier = proximityPrompt:GetAttribute(FFGEnum.ATTRIBUTES.Tier)

				if tier ~= promptTier then return end

				proximityPrompt.Enabled = true
			end))
		end
	end
end

local ANIMATIONS = {
	FishCaught1 = "FishCaught1",
}

function FishingManager.PlayerAnim(self: FishingManager, player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local animation: Animation = Animator.GetAnimation(ANIMATIONS.FishCaught1)

	if animator then
		local animationTrack: AnimationTrack = animator:LoadAnimation(animation)
		animationTrack.Priority = Enum.AnimationPriority.Action

		task.wait()
		animationTrack:Play()
	end
end

function FishingManager.ApplyFishingXP(self: FishingManager, stats)
	local pdata = DataService.GetSkillData(self.Player, "Fishing")

	-- Get fish data from stats
	local fishData = stats.FishData
	if not fishData then
		warn("No fish data in stats for XP calculation")
		return
	end

	-- Calculate XP reward based on fish and performance
	local xpReward = self:CalculateFishingXPReward(fishData, stats, pdata.FishingLevel)

	-- Apply XP and check for level ups
	local oldLevel = pdata.FishingLevel
	local oldXP = pdata.FishingXP

	local newLevel, newXP = FishingXP.AddXP(oldLevel, oldXP, xpReward)

	local dataToSave = {
		FishingLevel = newLevel,
		FishingXP = newXP,
		TotalForNextLevel = FishingXP.GetTotalForLevel(newLevel + 1),
		TotalForCurrentLevel = FishingXP.GetTotalForLevel(newLevel),
	}
	DataService.UpdateSkillData(self.Player, "Fishing", dataToSave)

	-- Notify player of XP gain
	Events.FireEvent(Events.RemoteNames.LootNotification, self.Player, { ItemImage = "Fishing", Text = string.format("+%d Fishing XP", xpReward) })

	-- Handle level up
	if newLevel > oldLevel then
		Events.FireEvent(Events.RemoteNames.LootNotification, self.Player, { ItemImage = "Fishing", Text = string.format("🎣 Fishing Level Up! Level %d → %d", oldLevel, newLevel) })

		-- Log level up for debugging
		print(string.format("%s reached Fishing Level %d! (+%d XP)", self.Player.Name, newLevel, xpReward))

		-- //TODO: Unlock new content based on level
		-- self:CheckForUnlocks(newLevel)
	else
		-- Show progress towards next level
		local xpToNext = FishingXP.GetXPToNextLevel(newLevel, newXP)
		print(string.format("%s gained %d Fishing XP (%d more needed for level %d)", self.Player.Name, xpReward, xpToNext, newLevel + 1))
	end
end

function FishingManager.CalculateFishingXPReward(self: FishingManager, fishData, stats, playerLevel: number): number
	-- Base XP from fish quality and tier
	local baseXP = 5 + (fishData.QualityId * 8) + ((fishData.Tier or 1) * 4)

	-- Performance bonus: perfect hits give significant bonus
	local perfectRatio = stats.PerfectHits / math.max(stats.TotalHits, 1)
	local performanceBonus = 1.0 + (perfectRatio * 0.5) -- Up to +50% for all perfect hits

	-- Difficulty bonus: harder fish give more XP
	local difficultyBonus = 1.0 + (stats.Difficulty - 1.0) * 0.3 -- +30% per difficulty point above 1

	-- Duration bonus: faster catches get small bonus (encourages skill)
	local durationBonus = 1.0
	if stats.Duration < 10 then
		durationBonus = 1.2 -- +20% for quick catches
	elseif stats.Duration < 20 then
		durationBonus = 1.1 -- +10% for decent speed
	end

	-- Calculate final XP
	local finalXP = baseXP * performanceBonus * difficultyBonus * durationBonus

	-- Round to nearest integer
	finalXP = math.floor(finalXP + 0.5)

	-- Ensure minimum XP (even bad catches give something)
	finalXP = math.max(finalXP, 3)

	return finalXP
end

function FishingManager.AttachAttListeners(self: FishingManager)
	local getFishItemEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishItem)
	if getFishItemEvent then
		getFishItemEvent.OnServerInvoke = function(player: Player)
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			return { Fish = self:GetRandomFish(self.CurrentFishingLocTier, self.CurrentFishingLocId), Rod = self:GetPlayerRod() }
		end
		self._cleaner:Add(getFishItemEvent)
	end

	local fishingResultEvent = Events.GetRemote(Events.RemoteNames.FishingResult)
	if fishingResultEvent then
		self._cleaner:Add(fishingResultEvent.OnServerEvent:Connect(function(player: Player, sessionId: string, result: {})
			if self.Player ~= player or self.Owner ~= player.UserId then return end

			local isValid, message, fishCaught, stats = self:ValidateAndScoreFishing(player, sessionId, result)
			if not isValid then
				print("Invalid fishing attempt by:", player.Name, "Reason:", message)
				-- Optionally kick player or log incident for repeated offenses
				return
			end

			-- Check if fish escaped due to too many failures
			if result.Success == false and result.EscapeReason then
				local escapeAttempts = tonumber(result.EscapeAttempts) or 3
				print(string.format("Fish escaped from %s. Reason: %s (Attempts: %d)", player.Name, tostring(result.EscapeReason), escapeAttempts))
				if Notification and Notification.SendAlert then Notification.SendAlert(player, string.format("The fish got away after %d escape attempts!", escapeAttempts)) end
				return
			end

			if fishCaught then
				-- SERVER authorizes the catch
				local fishData = stats.FishData
				if fishData then
					self:SaveCaughtFish(fishData)
					self:ApplyFishingXP(stats)
					self:PlayerAnim(player)
					print(string.format("Fish caught by %s! Score: %d/%d", player.Name, stats.Score, stats.RequiredScore))
				else
					print("Missing fish data for successful catch by:", player.Name)
				end
			else
				print(string.format("Fish escaped from %s. Score: %d/%d (insufficient)", player.Name, stats.Score, stats.RequiredScore))
				if Notification and Notification.SendAlert then Notification.SendAlert(player, "The fish got away! Try to land more perfect hits.") end
			end
		end))
	end
end

-- //SECTION - Cleanup
function FishingManager.Destroy(self: FishingManager)
	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil
	self.Owner = nil
	self.TeamId = nil
	self.RealmId = nil
end
-- //!SECTION

return FishingManager
