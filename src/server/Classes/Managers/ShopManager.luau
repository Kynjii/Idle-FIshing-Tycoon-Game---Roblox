local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Shop = require(ServerScriptService.Server.Classes.Shop)

-- //SECTION - Tagged Entities within Workspace
local taggedShops = CollectionService:GetTagged("Shop")
-- //!SECTION

local ShopManager = {}
ShopManager.__index = ShopManager

type ShopManager = typeof(setmetatable({}, ShopManager))

function ShopManager.New(shopData: { [string]: any }, player: Player, teamId: number)
	local self = setmetatable({}, ShopManager)

	self.Player = player
	self.TeamId = teamId
	self.Model = self:FindShopModel(teamId)

	local shopState = shopData
	self.Shop = Shop.New(shopState, player, self.Model, teamId)

	return self
end

function ShopManager:FindShopModel(teamId: number): Instance?
	for _, taggedShop in ipairs(taggedShops) do
		local taggedShopTeamId = taggedShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedShopTeamId == teamId then return taggedShop end
	end

	return nil
end

return ShopManager
