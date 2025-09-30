local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local Theme = require(ReplicatedStorage.Shared.Theme.Theme)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local hud = DeepWait(player, "PlayerGui", "HUD", "Main")

local currencyTemplate = DeepWait(hud, "Container", "Currencies", "Currency", "CurrencyContainer", "CurrencyTextLabelTemplate")
local realmBuffsTemplate = DeepWait(hud, "RealmBuffs", "Buffs", "BuffContainer", "BuffTextLabelTemplate")

local currencyLabels = {}

local function setCurrency(name: string, v: number)
	if not v then return end
	local currencyLabel: TextLabel

	if currencyLabels[name] then
		currencyLabel = currencyLabels[name]
	else
		currencyLabel = currencyTemplate:Clone() :: TextLabel
		currencyLabel.Name = name .. "_LabelClone"
		currencyLabel.Parent = currencyTemplate.Parent
		currencyLabel.Visible = true
		currencyLabels[name] = currencyLabel
	end

	currencyLabel.FontFace = Theme.font
	currencyLabel.Text = FormatNumber(v)
end

local realmBuffLabels = {}
local realmBuffCount = 0

local function setRealmBuff(name: string, buff)
	if not buff.CurrentValue then return end
	local buffLabel: TextLabel

	if realmBuffLabels[name] then
		buffLabel = realmBuffLabels[name]
	else
		realmBuffCount += 1
		buffLabel = realmBuffsTemplate:Clone() :: TextLabel
		buffLabel.Name = name .. "_LabelClone"
		buffLabel.LayoutOrder = realmBuffCount
		buffLabel.Parent = realmBuffsTemplate.Parent
		buffLabel.Visible = true
		realmBuffLabels[name] = buffLabel
	end

	buffLabel.FontFace = Theme.font
	local value = buff.CurrentValue * 100
	local isPlus = buff.IsPlus
	if isPlus then
		buffLabel.Text = "+" .. FormatNumber(value) .. "%" .. " " .. buff.Label
	else
		buffLabel.Text = "-" .. FormatNumber(value) .. "%" .. " " .. buff.Label
	end
end

Replica.OnNew("PlayerState", function(replicaData)
	local currentRealm = replicaData.Data.CurrentRealm or 1
	-- Set intial snapshot
	local goldAmount = replicaData.Data.Currencies.Gold
	setCurrency("Gold", goldAmount)

	local buffs = replicaData.Data.Realms[currentRealm].Buffs
	for name, buff in pairs(buffs) do
		setRealmBuff(name, buff)
	end

	-- Currencies
	replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
		setCurrency("Gold", newValue)
	end)
	-- Global Buffs
	-- //TODO - Set correct path once global buffs are defined
	-- replicaData:OnSet("GlobalBuffs", function(newValue, oldValue)
	-- 	setRealmBuff(newValue)
	-- end)

	-- Realm Buffs
	for name, buff in pairs(buffs) do
		replicaData:OnSet({ "Realms", currentRealm, "Buffs", name }, function(newValue)
			setRealmBuff(name, newValue)
		end)
	end
end)

Replica.RequestData()
