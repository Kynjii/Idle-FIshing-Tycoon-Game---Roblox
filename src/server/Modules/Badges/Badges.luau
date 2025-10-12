local BadgeService = game:GetService("BadgeService")

local Badges = {}

Badges.Ids = {
	AlphaBadge = 807520027129851,
}

function Badges.CheckAlphaBadgeStatus(player: Player)
	local success, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, Badges.Ids.AlphaBadge)

	if not success then
		warn("Error while checking if player has badge")
		return
	end

	if hasBadge then
		return
	else
		Badges.Award(player, Badges.Ids.AlphaBadge)
	end
end

function Badges.Award(player: Player, badgeId: number)
	local success, badgeInfo = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, badgeId)
	if success then
		if badgeInfo.IsEnabled then
			local awarded, errorMessage = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
			if not awarded then warn("Error while awarding badge:", errorMessage) end
		end
	else
		warn("Error while fetching badge info!")
	end
end

return Badges
