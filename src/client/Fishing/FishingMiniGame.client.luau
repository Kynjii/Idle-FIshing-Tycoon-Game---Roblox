local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("FishingMiniGame")
local hitBarContainer = screenGui:WaitForChild("Frame"):WaitForChild("HitBarContainer")
local emojiContainer = screenGui:WaitForChild("Frame"):WaitForChild("SuccessContainer")

local hitBoxContainer = hitBarContainer:FindFirstChild("HitBoxContainer", true) :: Frame
local hitMarker = hitBarContainer:FindFirstChild("HitMarker") :: ImageLabel
local catchButton = hitBarContainer:FindFirstChild("CatchButton") :: TextButton

local fishCounterContainer = screenGui:WaitForChild("Frame"):WaitForChild("FishCounterContainer")
local progressBar, pbFrame = ProgressBar.Create({ Color = "Green", Parent = fishCounterContainer })
ProgressBar.Reset(pbFrame)
ProgressBar.Show(fishCounterContainer)

local elements = {
	[0] = emojiContainer:FindFirstChild("0"),
	[1] = emojiContainer:FindFirstChild("1"),
	[2] = emojiContainer:FindFirstChild("2"),
	[3] = emojiContainer:FindFirstChild("3"),
}

local startX = 0
local endX = 1
local up = true

RunService.Heartbeat:Connect(function(deltaTime: number)
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

local hitArea1 = hitBoxContainer
local hitArea2 = hitBoxContainer:FindFirstChild("InnerHit")
local hitArea3 = hitBoxContainer:FindFirstChild("Bullseye")

local function checkObjectsOverlap(a: GuiObject, b: GuiObject)
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

local function animate(area: number)
	local element: Frame = elements[area]

	if element then
		element.Visible = true

		local emoji = element.SuperHappy
		local bg = element.BG

		local tweenGoal = {
			ImageTransparency = 0,
		}

		local tweenInfo = TweenInfo.new(0.5)
		local tween1 = TweenService:Create(emoji, tweenInfo, tweenGoal)
		local tween2 = TweenService:Create(bg, tweenInfo, tweenGoal)

		tween1.Completed:Once(function()
			emoji.ImageTransparency = 1
			element.Visible = false
		end)

		tween2.Completed:Once(function()
			bg.ImageTransparency = 1
		end)

		tween1:Play()
		tween2:Play()
	end
end

local function relocateHitContainer()
	if hitArea1 then
		local randX = math.random()

		hitArea1.Size = UDim2.fromScale(math.clamp(randX, 0.18, 0.3), 1)

		hitArea1.Position = UDim2.fromScale(randX, 0.5)
	end
end

local hp = {
	[0] = 0,
	[1] = 10,
	[2] = 20,
	[3] = 30,
}

local fishMaxHp = 170
local currentFishHP = 0
local isLosingHP = false

local function startLosingHP()
	if isLosingHP then return end
	isLosingHP = true
	task.wait(1)
	task.spawn(function()
		while isLosingHP do
			currentFishHP -= fishMaxHp / 30

			if currentFishHP <= 0 then
				currentFishHP = 0
				isLosingHP = false
			end

			ProgressBar.Update(pbFrame, currentFishHP, fishMaxHp)
			task.wait(1)
		end
	end)
end

if catchButton then
	catchButton.Activated:Connect(function()
		local isOverLapping1 = checkObjectsOverlap(hitMarker, hitArea1)
		local isOverLapping2 = checkObjectsOverlap(hitMarker, hitArea2)
		local isOverLapping3 = checkObjectsOverlap(hitMarker, hitArea3)

		local area = 0

		if isOverLapping1 then area = 1 end
		if isOverLapping2 then area = 2 end
		if isOverLapping3 then area = 3 end

		animate(area)

		local hpAdded = hp[area]
		local currentHp = currentFishHP

		local newHp = currentHp + hpAdded
		currentFishHP = newHp

		if newHp >= fishMaxHp then
			print("WOOOHOOO!")
			currentFishHP = 0
		end
		relocateHitContainer()

		ProgressBar.Update(pbFrame, currentFishHP, fishMaxHp)

		if area > 0 then startLosingHP() end
	end)
end
