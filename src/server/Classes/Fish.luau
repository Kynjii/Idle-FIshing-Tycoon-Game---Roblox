local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local FishCalculators = require(ServerScriptService.Server.Classes.Modules.FishCalculators)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Fish,
	RealmId = 1,
	Weight = 1,
	QualityId = 1,
}

local Fish = {}
Fish.__index = Fish

export type Fish = {
	Entity: string,
	Id: string,
	Player: Player,
	RealmId: number,
	Owner: number,
	Model: Model?,
	TeamId: number,
	Species: string,
	Variant: string,
	ItemImage: string,
	Name: string,
	QualityId: number,
	Quality: string,
	MaxHP: number,
	Weight: number,
	_cleaner: any,
}

-- //SECTION - Helpers
-- //!SECTION

-- //SECTION - Constructor
function Fish.New(state, player: Player, teamId: number, fishingLocTier: number, currentRealm: number): Fish
	local self = setmetatable({}, Fish)

	-- Start with default stats as base
	for key, value in pairs(DEFAULTS) do
		self[key] = value
	end

	-- Override with provided state values
	if state then
		for key, value in pairs(state) do
			self[key] = value
		end
	end

	-- Calculate derived properties
	self.Entity = state.Entity or DEFAULTS.Entity
	self.Id = state.Id or HttpService:GenerateGUID(false)
	self.Player = player
	self.Owner = state.Owner or self.Owner or player.UserId
	self.RealmId = currentRealm
	self.TeamId = teamId

	self.Model = nil

	local specieData = FishCalculators.ChooseSpecie(fishingLocTier, self.RealmId)
	self.Species = state.Species or specieData.Species
	self.Variant = state.Variant or specieData.Variant
	self.SpeciesKey = state.SpeciesKey or specieData.SpeciesKey
	self.ItemImage = state.ItemImage or specieData.ItemImage
	self.Name = state.Name or specieData.Name
	self.NameKey = state.NameKey or specieData.NameKey

	-- Define quality first
	self.QualityId = state.QualityId or self:DefineQuality(fishingLocTier)
	self.Quality = FFGEnum.QUALITIES[self.QualityId]
	self.MaxHP, self.Weight = self:CalculateStats()

	self._cleaner = Trove.new()

	return self
end
-- //!SECTION

-- //SECTION - Model
function Fish.CreateModel(self: Fish)
	--
end
-- //!SECTION

-- //SECTION - Calculations
function Fish.CalculateStats(self: Fish)
	return FishCalculators.GenerateStats(self.QualityId)
end

function Fish.DefineQuality(self: Fish, fishingLocTier: number?): number?
	return FishCalculators.ChooseQuality(fishingLocTier)
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Fish.Serialize(self: Fish): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		RealmId = self.RealmId,
		TeamId = self.TeamId,
		Owner = self.Owner,
		Name = self.Name,
		NameKey = self.NameKey,
		Species = self.Species,
		SpeciesKey = self.SpeciesKey,
		Variant = self.Variant,
		QualityId = self.QualityId,
		MaxHP = self.MaxHP,
		Weight = self.Weight,
		ItemImage = self.ItemImage,
	}
end

function Fish.Save(self: Fish): ()
	DataService.SaveFish(self.Player, self:Serialize())
end
-- //!SECTION

-- //SECTION - Cleanup
function Fish.Destroy(self: Fish)
	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
end
-- //!SECTION

return Fish
