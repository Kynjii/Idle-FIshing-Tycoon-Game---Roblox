local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Building = require(ServerScriptService.Server.Classes.Building)
local BuildingsManagerType = require(ReplicatedStorage.Shared.Types.Managers.BuildingsManagerType)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local taggedBuildings = CollectionService:GetTagged("Building")

-- //SECTION - BuildingManager Types
type BuildingsMangerInstance = BuildingsManagerType.BuildingsManagerInstance
-- //!SECTION

local BuildingsManager = {}
BuildingsManager.__index = BuildingsManager

type BuildingsManager = typeof(setmetatable({} :: BuildingsMangerInstance, BuildingsManager))

function BuildingsManager.New(realmData, player: Player, teamId: number)
	local self = setmetatable({} :: BuildingsMangerInstance, BuildingsManager)

	self.Player = player
	self.TeamId = teamId

	self.BuildingModels = self.FindBuildingModels()
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
		buildings[k] = Building.New(existingBuilding or {}, self.Player, self.BuildingModels[k], realmBuffs)
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
