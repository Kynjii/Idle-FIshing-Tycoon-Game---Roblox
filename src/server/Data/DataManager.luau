local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FFGHelpers = require(ReplicatedStorage.Shared.Utils.FFGHelpers)
local PlayerDataTemplate = require(script.Parent.PlayerDataTemplate)
local Replica = require(ServerScriptService.Server.ReplicaServer)
local PlayerStateToken = Replica.Token("PlayerState")

local DataManager = {}
DataManager.Profiles = {}
DataManager.Replicas = {}

function DataManager.AttachReplica(player: Player, profile)
	FFGHelpers.PrintLog("Attaching Replica for: ", player)
	local replica = Replica.New({
		Token = PlayerStateToken,
		Data = {
			Currencies = {
				Gold = profile.Data.Currencies.Gold or PlayerDataTemplate.Currencies.Gold,
			},
		},
	})
	FFGHelpers.PrintLog("New Replica is: ", replica)
	replica:Subscribe(player)
	DataManager.Replicas[player] = replica
	return replica
end

function DataManager.DetachReplica(player: Player)
	FFGHelpers.PrintLog("Detaching Replica for: ", player)
	local replica = DataManager.Replicas[player]
	if replica then
		replica:Destroy()
		DataManager.Replicas[player] = nil
	end
end

function DataManager.Earn(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to earn: ", currencyType)
		return
	end
	if typeof(amount) ~= "number" or amount <= 0 then
		FFGHelpers.PrintLog("The amount is either not a number or <= 0: ", currencyType)
		return
	end
	if typeof(currencyType) ~= "string" then
		FFGHelpers.PrintLog("The currencyType is not a string: ", currencyType)
		return
	end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	local newValue = current + amount
	profile.Data.Currencies[currencyType] = newValue

	local replica = DataManager.Replicas[player]
	if replica then
		replica:Set({ "Currencies", currencyType }, newValue)
	end
end

function DataManager.CanAfford(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	return (tonumber(profile.Data.Currencies[currencyType]) or 0) >= amount
end

function DataManager.Spend(player: Player, currencyType: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	if typeof(amount) ~= "number" or amount <= 0 then
		return
	end
	if typeof(currencyType) ~= "string" then
		return
	end

	local current = tonumber(profile.Data.Currencies[currencyType]) or 0
	if current < amount then
		return
	end

	local newValue = current - amount
	profile.Data.Currencies[currencyType] = newValue

	local replica = DataManager.Replicas[player]
	if replica then
		replica:Set({ "Currencies", currencyType }, newValue)
	end
end

function DataManager.ClearProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to clear profile data for: ", player)
		return
	end

	profile.Data = nil

	FFGHelpers.PrintLog("Cleared Profile Data: ", profile)
end

function DataManager.CreateNewProfileData(player: Player, profile)
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to create new profile data for: ", player)
		return
	end

	local resetDataTemplate = TableUtil.Copy(PlayerDataTemplate, true)
	profile.Data = resetDataTemplate

	FFGHelpers.PrintLog("Created Profile Data: ", profile)
end

function DataManager.ResetAllPlayerData(player: Player)
	local profile = DataManager.Profiles[player]
	if not profile then
		FFGHelpers.PrintLog("No profile found when attempting to reset data for: ", player)
		return
	end

	DataManager.ClearProfileData(player, profile)
	DataManager.DetachReplica(player)

	DataManager.CreateNewProfileData(player, profile)
	DataManager.AttachReplica(player, profile)
end

return DataManager
