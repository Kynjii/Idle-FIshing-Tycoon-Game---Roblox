local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicaData = require(StarterPlayer.StarterPlayerScripts.Client.Modules.ReplicaData)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local FormatNumber = require(ReplicatedStorage.Shared.Utils.FormatNumber)

local player = Players.LocalPlayer
local hud = DeepWait(player, "PlayerGui", "HUD")

local currencyTemplate = DeepWait(hud, "Currencies", "Currency", "CurrencyContainer", "CurrencyTextLabelTemplate")
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

	currencyLabel.Font = FFGEnum.FONT
	currencyLabel.Text = FormatNumber(v)
	currencyLabel.TextSize = currencyLabel.AbsoluteSize.Y / 2
end

local realmBuffLabels = {}

local function setRealmBuff(name: string, buff)
	if not buff.CurrentValue then return end
	local buffLabel: TextLabel

	if realmBuffLabels[name] then
		buffLabel = realmBuffLabels[name]
	else
		buffLabel = realmBuffsTemplate:Clone() :: TextLabel
		buffLabel.Name = name .. "_LabelClone"
		buffLabel.Parent = realmBuffsTemplate.Parent
		buffLabel.Visible = true
		realmBuffLabels[name] = buffLabel
	end

	buffLabel.Font = FFGEnum.FONT
	local value = buff.CurrentValue * 100
	local isPlus = buff.IsPlus
	if isPlus then
		buffLabel.Text = "+" .. FormatNumber(value) .. "%" .. " " .. buff.Label
	else
		buffLabel.Text = "-" .. FormatNumber(value) .. "%" .. " " .. buff.Label
	end
	buffLabel.TextSize = buffLabel.AbsoluteSize.Y / 2
end

ReplicaData.StateChanged:Connect(function(playerData)
	local data = playerData

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
end)
