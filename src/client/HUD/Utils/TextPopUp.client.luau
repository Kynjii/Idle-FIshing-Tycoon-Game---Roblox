local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Replica = require(ReplicatedStorage.Shared.ReplicaClient)
local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)
local Format = require(ReplicatedStorage.Shared.Utils.Format)

local player = Players.LocalPlayer
local hud: Frame = DeepWait(player, "PlayerGui", "HUD", "Main")

local currencyTemplate = hud:FindFirstChild("CurrencyTextLabelTemplate", true)

local currencyLabels = {}

local function animate(currencyLabel: TextLabel)
	if currencyLabel then
		local baseSize = currencyLabel.Size
		local tweenGoal = {
			Size = baseSize + UDim2.fromScale(0.1, 0.1),
		}

		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(currencyLabel, tweenInfo, tweenGoal)

		tween:Play()

		tween.Completed:Connect(function()
			currencyLabel.Size = baseSize
			tween:Destroy()
		end)
	end
end

local function setCurrency(name: string, v: number)
	if not v then return end
	local currencyLabel: TextLabel

	if currencyLabels[name] then
		currencyLabel = currencyLabels[name]
	else
		currencyLabel = currencyTemplate:Clone() :: TextLabel
		currencyLabel.Name = name .. "_LabelClone"
		currencyLabel.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
		currencyLabel.Position = UDim2.fromScale(0.539, 0.526)
		currencyLabel.Size = UDim2.fromScale(0.9, 0.9)
		currencyLabel.Font = FFGEnum.THEME.normalFont
		currencyLabel.TextScaled = true
		currencyLabel.Visible = true
		currencyLabel.Parent = currencyTemplate.Parent
		currencyLabels[name] = currencyLabel
	end

	animate(currencyLabel)

	currencyLabel.FontFace.Bold = true
	currencyLabel.Text = Format.CurrencyNumber(v)
end

Replica.OnNew("PlayerState", function(replicaData)
	-- Set intial snapshot
	local goldAmount = replicaData.Data.Currencies.Gold
	setCurrency("Gold", goldAmount)

	-- Currencies
	replicaData:OnSet({ "Currencies", "Gold" }, function(newValue)
		setCurrency("Gold", newValue)
	end)
end)

Replica.RequestData()
