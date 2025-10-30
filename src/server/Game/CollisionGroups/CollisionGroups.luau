local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local CollisionGroups = {}
CollisionGroups.Groups = {
	GROUP_NPC = "Helpers",
	GROUP_PLAYERS = "Players",
}

pcall(function()
	PhysicsService:RegisterCollisionGroup(CollisionGroups.Groups.GROUP_NPC)
end)
pcall(function()
	PhysicsService:RegisterCollisionGroup(CollisionGroups.Groups.GROUP_PLAYERS)
end)

-- Define relations AFTER both are registered
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Groups.GROUP_NPC, CollisionGroups.Groups.GROUP_PLAYERS, false)
PhysicsService:CollisionGroupSetCollidable(CollisionGroups.Groups.GROUP_NPC, CollisionGroups.Groups.GROUP_NPC, false)

-- Utility: assign group to all current + future BaseParts in a model
local function bindCollisionGroup(model: Instance, groupName: string)
	-- existing parts
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.CollisionGroup = groupName end
	end
	-- future parts (accessories, clones, R15 scale parts, etc.)
	model.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then obj.CollisionGroup = groupName end
	end)
end

-- Tag players
local function onCharacterAdded(char: Model)
	bindCollisionGroup(char, CollisionGroups.Groups.GROUP_PLAYERS)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(onCharacterAdded)
	if plr.Character then onCharacterAdded(plr.Character) end
end)

function CollisionGroups.SetNpcCollisionGroup(npcModel: Model)
	if npcModel then bindCollisionGroup(npcModel, CollisionGroups.Groups.GROUP_NPC) end
end

return CollisionGroups
