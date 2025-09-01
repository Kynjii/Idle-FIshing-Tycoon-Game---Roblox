local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local DataService = require(ServerScriptService.Server.Services.DataService)
local FFGHelpers = require(ServerScriptService.Server.Modules.FFGHelpers)

local giveGoldButton = FFGHelpers.deepWait(Workspace, "DevGiveGold")
local debounce = false
giveGoldButton.Touched:Connect(function(hit)
	print("Touched")
	if debounce then return end
	debounce = true

	local character = hit and hit:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then DataService.Earn(player, FFGEnum.CURRENCY_TYPES.Gold, 1000000000) end
	end

	task.delay(0.5, function()
		debounce = false
	end)
end)

local resetGoldButton = FFGHelpers.deepWait(Workspace, "DevResetGold")
local resetDebounce = false
resetGoldButton.Touched:Connect(function(hit)
	if resetDebounce then return end
	resetDebounce = true

	local character = hit and hit:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then DataService.ResetAllPlayerData(player) end
	end

	task.delay(1, function()
		resetDebounce = false
	end)
end)
