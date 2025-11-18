local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Events = require(ReplicatedStorage.Shared.Events.Events)
local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
local Format = require(ReplicatedStorage.Shared.Utils.Format)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("FishingMiniGame") :: ScreenGui
local hitBarContainer = screenGui:WaitForChild("Frame"):WaitForChild("HitBarContainer")
local emojiContainer = screenGui:WaitForChild("Frame"):WaitForChild("SuccessContainer")

local hitBoxContainer = hitBarContainer:FindFirstChild("HitBoxContainer", true) :: Frame
local hitMarker = hitBarContainer:FindFirstChild("HitMarker") :: ImageLabel
local catchButton = hitBarContainer:FindFirstChild("CatchButton") :: TextButton

local fishCounterContainer = screenGui:WaitForChild("Frame"):WaitForChild("FishCounterContainer")
local _progressBar, pbFrame = ProgressBar.Create({ Color = "Green", Parent = fishCounterContainer })
ProgressBar.Reset(pbFrame)
ProgressBar.Show(fishCounterContainer)

type PlayerRod = { Name: string, QualityId: number, BaseDmg: number }
type Fish = { Id: string, QualityId: number, MaxHP: number, Species: string, Variant: string }

local hookedFish: Fish
local playerRod: PlayerRod
local currentTier: number

local elements = {
	[0] = emojiContainer:FindFirstChild("0"),
	[1] = emojiContainer:FindFirstChild("1"),
	[2] = emojiContainer:FindFirstChild("2"),
	[3] = emojiContainer:FindFirstChild("3"),
}

local startX = 0
local endX = 1
local up = true

local gameStarted = false

RunService.Heartbeat:Connect(function(deltaTime: number)
	if not gameStarted then return end
	local currentX = hitMarker.Position.X.Scale

	if up then
		hitMarker.Position = hitMarker.Position + UDim2.fromScale(deltaTime / 2, 0)
	else
		hitMarker.Position = hitMarker.Position - UDim2.fromScale(deltaTime / 2, 0)
	end

	if currentX >= endX then
		up = false
	elseif currentX <= startX then
		up = true
	end
end)

function startGame(value: boolean)
	gameStarted = value

	if not value then Events.FireEvent(Events.RemoteNames.GameEnded, player, currentTier) end
end

function showGame(value: boolean)
	screenGui.Enabled = value
end

function handleClosingGameUI()
	local character = player.Character.PrimaryPart
	local originalPosition = character.CFrame.Position

	while true do
		local distance = player:DistanceFromCharacter(originalPosition)
		if distance >= 8 then
			showGame(false)
			startGame(false)
			break
		end

		task.wait(0.5)
	end
end

local hitArea1 = hitBoxContainer
local hitArea2 = hitBoxContainer:FindFirstChild("InnerHit")
local hitArea3 = hitBoxContainer:FindFirstChild("Bullseye")

function checkObjectsOverlap(a: GuiObject, b: GuiObject)
	local aAbsPos = a.AbsolutePosition
	local aAbsSize = a.AbsoluteSize

	local bAbsPos = b.AbsolutePosition
	local bAbsSize = b.AbsoluteSize

	local aLeft = aAbsPos.X
	local bLeft = bAbsPos.X

	local aRight = aLeft + aAbsSize.X
	local bRight = bLeft + bAbsSize.X

	return aLeft < bRight and aRight > bLeft
end

function animate(area: number, hpAdded: number)
	local element: Frame = elements[area]

	if element then
		element.Visible = true

		local emoji = element.SuperHappy
		local bg = element.BG
		local text = element.TextLabel
		text.Text = Format.CurrencyNumber(hpAdded)

		local tweenGoal = {
			ImageTransparency = 0,
		}

		local tweenGoal2 = {
			TextTransparency = 0,
		}

		local tweenInfo = TweenInfo.new(0.5)
		local tween1 = TweenService:Create(emoji, tweenInfo, tweenGoal)
		local tween2 = TweenService:Create(bg, tweenInfo, tweenGoal)
		local tween3 = TweenService:Create(text, tweenInfo, tweenGoal2)

		tween1.Completed:Once(function()
			emoji.ImageTransparency = 1
			element.Visible = false
		end)

		tween2.Completed:Once(function()
			bg.ImageTransparency = 1
		end)

		tween3.Completed:Once(function()
			text.TextTransparency = 1
		end)

		tween1:Play()
		tween2:Play()
		tween3:Play()
	end
end

function resetProgress()
	ProgressBar.Reset(pbFrame)
end

function resetHitMarker()
	hitMarker.Position = UDim2.fromScale(0, 0.5)
end

function relocateHitContainer()
	if hitArea1 then
		local randX = math.random()

		hitArea1.Size = UDim2.fromScale(math.clamp(randX, 0.18, 0.3), 1)

		hitArea1.Position = UDim2.fromScale(randX, 0.5)
	end
end

local currentFishHP = 0
local isLosingHP = false

function startLosingHP()
	if isLosingHP then return end
	isLosingHP = true
	task.wait(1)
	task.spawn(function()
		while isLosingHP do
			currentFishHP -= hookedFish.MaxHP / 40

			if currentFishHP <= 0 then
				currentFishHP = 0
				isLosingHP = false
			end

			ProgressBar.Update(pbFrame, currentFishHP, hookedFish.MaxHP)
			task.wait(1)
		end
	end)
end

local getFishingDataEvent = Events.GetRemoteFn(Events.RemoteFunctionNames.GetFishItem)
local caughtFishEvent = Events.GetRemote(Events.RemoteNames.FishCaught)

if catchButton then
	catchButton.Activated:Connect(function()
		local isOverLapping1 = checkObjectsOverlap(hitMarker, hitArea1)
		local isOverLapping2 = checkObjectsOverlap(hitMarker, hitArea2)
		local isOverLapping3 = checkObjectsOverlap(hitMarker, hitArea3)

		local area = 0

		if isOverLapping1 then area = 1 end
		if isOverLapping2 then area = 2 end
		if isOverLapping3 then area = 3 end

		local hpAdded = playerRod.BaseDmg * area
		animate(area, hpAdded)
		local currentHp = currentFishHP

		local newHp = currentHp + hpAdded
		if area == 0 then newHp = currentHp - playerRod.BaseDmg end
		currentFishHP = newHp

		if newHp >= hookedFish.MaxHP then
			currentFishHP = 0

			caughtFishEvent:FireServer(hookedFish)

			local data = getFishingDataEvent:InvokeServer()
			if data then
				hookedFish = data.Fish
				playerRod = data.Rod
			end
		end
		relocateHitContainer()

		ProgressBar.Update(pbFrame, currentFishHP, hookedFish.MaxHP)

		if area > 0 then startLosingHP() end
	end)
end

local startGameEvent = Events.GetRemote(Events.RemoteNames.StartFishingMiniGame)
if startGameEvent then
	startGameEvent.OnClientEvent:Connect(function(data: { Fish: {}, Rod: {}, Tier: number })
		currentTier = data.Tier

		resetHitMarker()
		resetProgress()

		showGame(true)
		startGame(true)

		hookedFish = data.Fish
		playerRod = data.Rod

		handleClosingGameUI()
	end)
end
