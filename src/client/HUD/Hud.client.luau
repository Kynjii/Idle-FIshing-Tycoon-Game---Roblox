local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
Replica.RequestData()

-- Grab your HUD pieces (runtime UI lives under PlayerGui, not StarterGui)
local player = Players.LocalPlayer
local hud = FFGHelpers.deepWait(player, "PlayerGui", "HUD")

local labels = {
	Gold = hud:WaitForChild("GoldLabel"),
	-- Pearls = hud:FindFirstChild("PearlsLabel"), -- add more when you create them
}

local current = {
	Gold = 0,
	-- Pearls = 0,
}

-- Pretty number formatter (1.2K / 3.4M / 5.6B)
local function fmt(n: number): string
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	end
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	end
	if n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function setCurrency(name: string, v: number)
	local label = labels[name]
	if not label then
		return
	end

	local prev = current[name] or 0
	current[name] = v

	-- update label text
	label.Text = string.format("%s: %s", name, fmt(v))

	-- flash color on change (green for gain, red for spend)
	if v ~= prev then
		local orig = label.TextColor3
		local flash = (v > prev) and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(230, 90, 90)
		label.TextColor3 = flash
		TweenService:Create(label, TweenInfo.new(0.25), { TextColor3 = orig }):Play()
	end
end

Replica.OnNew("PlayerState", function(replica)
	local data = replica.Data

	-- Initial snapshot
	if data.Currencies then
		for k, n in pairs(data.Currencies) do
			if typeof(n) == "number" then
				setCurrency(k, n)
			end
		end
	end

	-- Subscribe to currency patches (Gold + any others you add)
	-- This captures the key per iteration to avoid closure bugs.
	local subscribed: { [string]: boolean } = {}

	local function subscribeCurrency(key: string)
		if subscribed[key] then
			return
		end
		subscribed[key] = true
		replica:OnSet({ "Currencies", key }, function(v)
			if typeof(v) == "number" then
				setCurrency(key, v)
			end
		end)
	end

	-- Subscribe for all labels you have in the HUD (even if not present yet)
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
