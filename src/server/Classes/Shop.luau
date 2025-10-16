local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local ClassVisualizer = require(ServerScriptService.Server.Classes.Modules.ClassVisualizer)
local EventListeners = require(ServerScriptService.Server.Classes.Modules.EventListeners)
local ProximityPrompt = require(ServerScriptService.Server.Classes.Modules.ProximityPrompt)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

local Shop = {}
Shop.__index = Shop

type Shop = typeof(setmetatable({}, Shop))

local DEFAULTS = {
	Entity = FFGEnum.CLASS.ENTITY_NAME.Shop,
	RealmId = 1,
	Name = "Shop",
}

-- //SECTION - Constructor
function Shop.New(state: { [string]: any }?, player: Player, model: Model, teamId: number): Shop
	local self = setmetatable({}, Shop)

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
	self.Id = self.Id or HttpService:GenerateGUID(false)
	self.TeamId = teamId
	self.Owner = self.Owner or player.UserId
	self.Model = model
	self.Entity = self.Entity or DEFAULTS.Entity
	self.Player = player

	self:AttachEventListeners()

	self._cleaner = Trove.new()

	return self
end
-- //!SECTION

-- //SECTION - UI Setup
function Shop.Initialize(self: Shop): ()
	self:Show()
	self:CanCollide()

	-- Setup UI components
	if self.Model then self:SetupProximityPrompt(self.Model) end
end

function Shop.SetupProximityPrompt(self: Shop, model: Model): ()
	local proximityPrompt: ProximityPrompt = self._cleaner and self._cleaner:Add(Instance.new("ProximityPrompt"))
	proximityPrompt.Parent = model

	ProximityPrompt.CreatePP(proximityPrompt, self :: any)
end
-- //!SECTION

-- //SECTION - Visibility and Collision
function Shop.Show(self: Shop): ()
	ClassVisualizer.Show(self.VisualRoot)
end

function Shop.Hide(self: Shop): ()
	ClassVisualizer.Hide(self.VisualRoot)
end

function Shop.CanCollide(self: Shop): ()
	ClassVisualizer.CanCollide(self.VisualRoot)
end

function Shop.CannotCollide(self: Shop): ()
	ClassVisualizer.CannotCollide(self.VisualRoot)
end
-- //!SECTION

-- //SECTION - Loading and Saving
function Shop.Serialize(self: Shop): { [string]: any }
	return {
		Entity = self.Entity,
		Id = self.Id,
		Owner = self.Owner,
		RealmId = self.RealmId,
	}
end

function Shop.Save(self: Shop): ()
	DataService.SaveShopState(self.Player, self.Id, self:Serialize())
end
-- //!SECTION

-- //SECTION - Event Listeners
function Shop.AttachEventListeners(self: Shop)
	EventListeners.Attach(self :: any)
end
-- //!SECTION

-- //SECTION - Cleanup
function Shop.Destroy(self: Shop)
	self:Hide()
	self:CannotCollide()

	pcall(function()
		self:Save()
	end)

	if self._cleaner then
		self._cleaner:Clean()
		self._cleaner = nil
	end

	self.Player = nil :: any
	self.Model = nil :: any
end
-- //!SECTION

return Shop
