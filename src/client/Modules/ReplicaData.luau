local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
Replica:RequestData()

local PlayerData = {}

PlayerData = {
	Currencies = { Gold = 0 },
	RealmBuffs = {},
}

PlayerData.StateChanged = Signal.new()

local function setCurrency(name: string, v: number)
	if not v then return end

	PlayerData.Currencies[name] = v or 0
	PlayerData.StateChanged:Fire(PlayerData)
end

local function setRealmBuff(name: string, buff)
	if not buff.CurrentValue then return end

	PlayerData.RealmBuffs[name] = buff and buff.CurrentValue or ""
	PlayerData.StateChanged:Fire(PlayerData)
end

Replica.OnNew("PlayerState", function(replica)
	local data = replica.Data

	-- Initial snapshot
	if data.Currencies then
		for k, n in pairs(data.Currencies) do
			if typeof(n) == "number" then setCurrency(k, n) end
		end
	end

	if data.RealmBuffs then
		for k, buff in pairs(data.RealmBuffs) do
			if buff.CurrentValue then setRealmBuff(k, buff) end
		end
	end

	-- Subscribe to patches
	local subscribed: { [string]: boolean } = {}

	local function subscribeCurrency(key: string)
		if subscribed[key] then return end
		subscribed[key] = true
		replica:OnSet({ "Currencies", key }, function(v)
			if typeof(v) == "number" then setCurrency(key, v) end
		end)
	end

	local function subscribeRealmBuffs(key: string)
		if subscribed[key] then return end
		subscribed[key] = true
		replica:OnSet({ "RealmBuffs", key }, function(v)
			setRealmBuff(key, v)
		end)
	end

	-- Subscribe realm buffs
	if data.RealmBuffs then
		for key in pairs(data.RealmBuffs) do
			subscribeRealmBuffs(key)
		end
	end

	-- Subscribe currencies
	if data.Currencies then
		for key in pairs(data.Currencies) do
			subscribeCurrency(key)
		end
	end
end)

return PlayerData
