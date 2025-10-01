local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Building = require(ServerScriptService.Server.Classes.Building)
local BuildingsManagerType = require(ReplicatedStorage.Shared.Types.Managers.BuildingsManagerType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local BuildingType = require(ReplicatedStorage.Shared.Types.Classes.BuildingType)
local taggedBuildings = CollectionService:GetTagged("Building")

type BuildingsManger = BuildingsManagerType.BuildingsManager

local BuildingsManager = {} :: BuildingsManger
BuildingsManager.__index = BuildingsManager

function BuildingsManager.New(realmData, player: Player, teamId: number)
	local self: BuildingsManger = setmetatable({}, BuildingsManager)

	self.Player = player
	self.TeamId = teamId

	self.BuildingModels = self:FindBuildingModels()
	local buildingsArr = realmData.Buildings
	local realmBuffs = realmData.Buffs
	self.Buildings = self:CreateBuildings(buildingsArr, realmBuffs)
	return self
end

function BuildingsManager:FindBuildingModels()
	local buildings = {}
	for _, taggedBuilding in ipairs(taggedBuildings) do
		local taggedBuildingTeamId = taggedBuilding:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		local buildingName = taggedBuilding:GetAttribute(FFGEnum.ATTRIBUTES.BuildingName)
		if taggedBuildingTeamId == self.TeamId then buildings[buildingName] = taggedBuilding end
	end
	return buildings
end

function BuildingsManager:CreateBuildings(buildingsData, realmBuffs)
	local buildings = {}

	for k, v in pairs(self.BuildingModels) do
		local existingBuilding = TableUtil.Find(buildingsData, function(building)
			return building.BuildingName == k
		end)
		if existingBuilding then buildings[k] = Building.New(existingBuilding or nil, self.Player, self.BuildingModels[k], realmBuffs) end
	end

	return buildings
end

function BuildingsManager:Initialize()
	for k, building in pairs(self.Buildings) do
		building:Initialize()
	end
end

-- //SECTION - Cleanup
function BuildingsManager:Destroy()
	for k, building in pairs(self.Buildings) do
		building:Destroy()
	end
end
-- //!SECTION

return BuildingsManager
