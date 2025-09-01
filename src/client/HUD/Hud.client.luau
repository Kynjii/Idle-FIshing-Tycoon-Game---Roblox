local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
Replica.RequestData()

local player = Players.LocalPlayer
local hud = FFGHelpers.deepWait(player, "PlayerGui", "HUD")

local labels = {
	Gold = FFGHelpers.deepWait(hud, "Currencies", "Gold", "TextLabel"),
}

local current = {
	Gold = 0,
}

-- Formats with 0–2 decimals depending on size, strips trailing .0
local function fmt(n: number): string
	local absn = math.abs(n)

	-- choose suffix if >= 1e3
	for _, s in ipairs(FFGHelpers.SUFFIXES) do
		if absn >= s.value then
			local v = n / s.value
			local av = math.abs(v)
			local decimals
			if av >= 100 then
				decimals = 0
			elseif av >= 10 then
				decimals = 1
			else
				decimals = 2
			end
			local out = string.format("%." .. decimals .. "f", v)
			out = out:gsub("(%..-)0+$", "%1"):gsub("%.$", "") -- trim trailing zeros/dot
			return out .. s.symbol
		end
	end

	-- no suffix (< 1e3)
	if absn >= 100 then
		return string.format("%.0f", n)
	elseif absn >= 10 then
		return (string.format("%.1f", n):gsub("(%..-)0+$", "%1"):gsub("%.$", ""))
	else
		return (string.format("%.2f", n):gsub("(%..-)0+$", "%1"):gsub("%.$", ""))
	end
end

local function setCurrency(name: string, v: number)
	local label = labels[name]
	if not label then return end
	current[name] = v

	label.Font = FFGEnum.FONT
	label.Text = fmt(v)
end

Replica.OnNew("PlayerState", function(replica)
	local data = replica.Data

	-- Initial snapshot
	if data.Currencies then
		for k, n in pairs(data.Currencies) do
			if typeof(n) == "number" then setCurrency(k, n) end
		end
	end

	-- Subscribe to currency patches
	local subscribed: { [string]: boolean } = {}

	local function subscribeCurrency(key: string)
		if subscribed[key] then return end
		subscribed[key] = true
		replica:OnSet({ "Currencies", key }, function(v)
			if typeof(v) == "number" then setCurrency(key, v) end
		end)
	end

	-- Subscribe for all labels in the HUD
	for key in pairs(labels) do
		subscribeCurrency(key)
	end
	-- Also subscribe for any currencies that arrived in the initial snapshot
	if data.Currencies then
		for key in pairs(data.Currencies) do
			subscribeCurrency(key)
		end
	end
end)
