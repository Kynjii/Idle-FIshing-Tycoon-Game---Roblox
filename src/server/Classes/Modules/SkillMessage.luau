local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local SkillTypes = require(ReplicatedStorage.Shared.Types.SkillTypes)
local SkillMessage = {}

function SkillMessage.Send(player: Player, text: string, skill: SkillTypes.SkillType)
	local data = {
		Text = text,
		Skill = skill,
	}

	Events.FireEvent(Events.RemoteNames.SkillMessage, player, data)
end

return SkillMessage
