-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local RunService = game:GetService("RunService")
-- local TweenService = game:GetService("TweenService")

-- local satchel = require(ReplicatedStorage.Packages.Satchel)
-- local Events = require(ReplicatedStorage.Shared.Events.Events)
-- local ProgressBar = require(ReplicatedStorage.Shared.UI.Components.ProgressBar)
-- local Format = require(ReplicatedStorage.Shared.Utils.Format)

-- local player = Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")

-- local screenGui = playerGui:WaitForChild("FishingMiniGame") :: ScreenGui
-- local hitBarContainer = screenGui:WaitForChild("Frame"):WaitForChild("HitBarContainer")
-- local emojiContainer = screenGui:WaitForChild("Frame"):WaitForChild("SuccessContainer")

-- local hitBoxContainer = hitBarContainer:FindFirstChild("HitBoxContainer", true) :: Frame
-- local hitMarker = hitBarContainer:FindFirstChild("HitMarker") :: ImageLabel
-- local catchButton = hitBarContainer:FindFirstChild("CatchButton") :: TextButton

-- local fishCounterContainer = screenGui:WaitForChild("Frame"):WaitForChild("FishCounterContainer")
-- local _progressBar, pbFrame = ProgressBar.Create({ Color = "Green", Parent = fishCounterContainer })
-- ProgressBar.Reset(pbFrame)
-- ProgressBar.Show(fishCounterContainer)

-- type PlayerRod = { Name: string, QualityId: number, BaseDmg: number }
-- type Fish = { Id: string, QualityId: number, MaxHP: number, Species: string, Variant: string }

-- local hookedFish: Fish
-- local playerRod: PlayerRod
-- local currentTier: number
-- local reelingSound = workspace.Audio.Reel

-- local elements = {
--     [0] = emojiContainer:FindFirstChild("0"),
--     [1] = emojiContainer:FindFirstChild("1"),
--     [2] = emojiContainer:FindFirstChild("2"),
--     [3] = emojiContainer:FindFirstChild("3"),
-- }

-- local startX = 0
-- local endX = 1
-- local up = true

-- local gameStarted = false

-- local isButtonHeld = false
-- local markerConnection = nil

-- local currentSessionId = nil
-- local totalHits = 0
-- local perfectHits = 0
-- local goodHits = 0
-- local okHits = 0

-- local currentFishHP = 0
-- local isLosingHP = false

-- local minigameConfig = {
--     HitZoneSize = 0.25,
--     MarkerSpeed = 0.5,
--     DecayRate = 1.0,
--     HealMultiplier = 1.0,
-- }

-- local hitTimeline = {}

-- local elapsed = 0
-- RunService.Heartbeat:Connect(function(dt)
--     if gameStarted then
--         elapsed += dt
--     end
-- end)

-- function startGame(value: boolean)
--     resetProgress()
--     resetHitMarker()
--     relocateHitContainer()

--     gameStarted = value

--     if value then
--         up = true
--         elapsed = 0
--         hitTimeline = {}
--         totalHits = 0
--         perfectHits = 0
--         goodHits = 0
--         okHits = 0
--         currentFishHP = 0
--         isLosingHP = false
--     else
--         isButtonHeld = false
--         isLosingHP = false
--         if markerConnection then
--             markerConnection:Disconnect()
--             markerConnection = nil
--         end
--         Events.FireEvent(Events.RemoteNames.GameEnded, player, currentTier)
--     end

--     if value then
--         markerConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
--             if not gameStarted or not isButtonHeld then
--                 return
--             end

--             local currentX = hitMarker.Position.X.Scale
--             local markerSpeed = minigameConfig.MarkerSpeed

--             if up then
--                 hitMarker.Position = hitMarker.Position + UDim2.fromScale(deltaTime * markerSpeed, 0)
--             else
--                 hitMarker.Position = hitMarker.Position - UDim2.fromScale(deltaTime * markerSpeed, 0)
--             end

--             if currentX >= endX then
--                 up = false
--             elseif currentX <= startX then
--                 up = true
--             end
--         end)
--     end
-- end

-- function showGame(value: boolean)
--     screenGui.Enabled = value

--     -- Stop reeling sound when closing game
--     if reelingSound.IsPlaying then
--         reelingSound:Stop()
--     end

--     if value then
--         satchel:SetBackpackEnabled(false)
--     else
--         satchel:SetBackpackEnabled(true)
--     end
-- end

-- function handleClosingGameUI()
--     local character = player.Character.PrimaryPart
--     local originalPosition = character.CFrame.Position

--     while true do
--         local distance = player:DistanceFromCharacter(originalPosition)
--         if distance >= 8 then
--             showGame(false)
--             startGame(false)
--             break
--         end

--         task.wait(0.5)
--     end
-- end

-- local hitArea1 = hitBoxContainer
-- local hitArea2 = hitBoxContainer:FindFirstChild("InnerHit")
-- local hitArea3 = hitBoxContainer:FindFirstChild("Bullseye")

-- function checkObjectsOverlap(a: GuiObject, b: GuiObject)
--     local aAbsPos = a.AbsolutePosition
--     local aAbsSize = a.AbsoluteSize

--     local bAbsPos = b.AbsolutePosition
--     local bAbsSize = b.AbsoluteSize

--     local aLeft = aAbsPos.X
--     local bLeft = bAbsPos.X

--     local aRight = aLeft + aAbsSize.X
--     local bRight = bLeft + bAbsSize.X

--     return aLeft < bRight and aRight > bLeft
-- end

-- function animate(area: number, hpAdded: number)
--     local element: Frame = elements[area]

--     if element then
--         element.Visible = true

--         local emoji = element.SuperHappy
--         local bg = element.BG
--         local text = element.TextLabel
--         text.Text = Format.CurrencyNumber(hpAdded)

--         local tweenGoal = {
--             ImageTransparency = 0,
--         }

--         local tweenGoal2 = {
--             TextTransparency = 0,
--         }

--         local tweenInfo = TweenInfo.new(0.5)
--         local tween1 = TweenService:Create(emoji, tweenInfo, tweenGoal)
--         local tween2 = TweenService:Create(bg, tweenInfo, tweenGoal)
--         local tween3 = TweenService:Create(text, tweenInfo, tweenGoal2)

--         tween1.Completed:Once(function()
--             emoji.ImageTransparency = 1
--             element.Visible = false
--         end)

--         tween2.Completed:Once(function()
--             bg.ImageTransparency = 1
--         end)

--         tween3.Completed:Once(function()
--             text.TextTransparency = 1
--         end)

--         tween1:Play()
--         tween2:Play()
--         tween3:Play()
--     end
-- end

-- function resetProgress()
--     ProgressBar.Reset(pbFrame)
-- end

-- function resetHitMarker()
--     hitMarker.Position = UDim2.fromScale(0, 0.5)
-- end

-- function relocateHitContainer()
--     if hitArea1 then
--         local hitZoneSize = minigameConfig.HitZoneSize
--         local minPosition = 0.1 -- Minimum 10% from left edge
--         local maxPosition = 1 - hitZoneSize - 0.1 -- Maximum with 10% margin from right edge
--         local randX = minPosition + math.random() * (maxPosition - minPosition)

--         hitArea1.Size = UDim2.fromScale(hitZoneSize, 1)
--         hitArea1.Position = UDim2.fromScale(randX, 0.5)
--     end
-- end

-- function startLosingHP()
--     if isLosingHP then
--         return
--     end
--     isLosingHP = true

--     task.spawn(function()
--         while isLosingHP and gameStarted do
--             task.wait(1)

--             -- visual decay only, server will re-simulate for real
--             local baseDecay = hookedFish.MaxHP / 40
--             local actualDecay = baseDecay * minigameConfig.DecayRate

--             currentFishHP -= actualDecay
--             if currentFishHP < 0 then
--                 currentFishHP = 0
--             end

--             -- keep UI in sync
--             ProgressBar.Update(pbFrame, currentFishHP, hookedFish.MaxHP)

--             -- visually: fish "gets away" when HP drains
--             if currentFishHP <= 0 then
--                 isLosingHP = false

--                 local fishingResult = {
--                     Success = false, -- client thinks it failed
--                     Duration = elapsed,
--                     Hits = hitTimeline, -- server uses this
--                 }

--                 local fishingResultEvent = Events.GetRemote(Events.RemoteNames.FishingResult)
--                 if fishingResultEvent and currentSessionId then
--                     fishingResultEvent:FireServer(currentSessionId, fishingResult)
--                 end

--                 showGame(false)
--                 startGame(false)
--                 break
--             end
--         end
--     end)
-- end

-- local function buttonReleased()
--     isButtonHeld = false

--     if reelingSound.IsPlaying then
--         reelingSound:Stop()
--     end

--     if markerConnection then
--         markerConnection:Disconnect()
--         markerConnection = nil
--     end

--     local isOverLapping1 = checkObjectsOverlap(hitMarker, hitArea1)
--     local isOverLapping2 = checkObjectsOverlap(hitMarker, hitArea2)
--     local isOverLapping3 = checkObjectsOverlap(hitMarker, hitArea3)

--     resetHitMarker()

--     local area = 0
--     if isOverLapping1 then
--         area = 1
--     end
--     if isOverLapping2 then
--         area = 2
--     end
--     if isOverLapping3 then
--         area = 3
--     end

--     -- record raw input for server replay
--     table.insert(hitTimeline, {
--         time = elapsed,
--         area = area,
--     })

--     -- local stats for display / debugging
--     if area > 0 then
--         totalHits += 1
--         if area == 3 then
--             perfectHits += 1
--         elseif area == 2 then
--             goodHits += 1
--         elseif area == 1 then
--             okHits += 1
--         end
--     end

--     -- heal / miss logic for visual HP
--     local baseHeal = playerRod.BaseDmg * area
--     local actualHeal = baseHeal * minigameConfig.HealMultiplier
--     animate(area, actualHeal)

--     local newHp = currentFishHP

--     if area > 0 then
--         newHp += actualHeal
--     else
--         -- miss penalty also affected by difficulty
--         local missPenalty = playerRod.BaseDmg * minigameConfig.DecayRate
--         newHp -= missPenalty
--     end

--     if newHp < 0 then
--         newHp = 0
--     end
--     currentFishHP = newHp

--     -- update UI bar
--     ProgressBar.Update(pbFrame, currentFishHP, hookedFish.MaxHP)

--     -- client-side "I filled the bar!" claim
--     if currentFishHP >= hookedFish.MaxHP then
--         -- send fishing result to server for authoritative validation
--         local fishingResult = {
--             Success = true,
--             Duration = elapsed,
--             Hits = hitTimeline,
--         }

--         local fishingResultEvent = Events.GetRemote(Events.RemoteNames.FishingResult)
--         if fishingResultEvent and currentSessionId then
--             fishingResultEvent:FireServer(currentSessionId, fishingResult)
--         end

--         showGame(false)
--         startGame(false)
--         return
--     end

--     relocateHitContainer()

--     -- start decay loop after first successful hit
--     if area > 0 then
--         startLosingHP()
--     end
-- end

-- local function buttonPressed()
--     isButtonHeld = true

--     if not reelingSound.IsPlaying then
--         reelingSound:Play()
--     end

--     if not markerConnection and gameStarted then
--         markerConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
--             if not gameStarted or not isButtonHeld then
--                 return
--             end

--             local currentX = hitMarker.Position.X.Scale
--             local markerSpeed = minigameConfig.MarkerSpeed

--             if up then
--                 hitMarker.Position = hitMarker.Position + UDim2.fromScale(deltaTime * markerSpeed, 0)
--             else
--                 hitMarker.Position = hitMarker.Position - UDim2.fromScale(deltaTime * markerSpeed, 0)
--             end

--             if currentX >= endX then
--                 up = false
--             elseif currentX <= startX then
--                 up = true
--             end
--         end)
--     end
-- end

-- if catchButton then
--     catchButton.InputBegan:Connect(function(input)
--         if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
--             buttonPressed()
--         end
--     end)
-- end

-- if catchButton then
--     catchButton.InputEnded:Connect(function(input)
--         if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
--             buttonReleased()
--         end
--     end)
-- end

-- local startGameEvent = Events.GetRemote(Events.RemoteNames.StartFishingMiniGame)
-- if startGameEvent then
--     startGameEvent.OnClientEvent:Connect(function(data)
--         isLosingHP = false
--         startGame(false)
--         task.wait()

--         currentFishHP = 0
--         ProgressBar.Reset(pbFrame)

--         hookedFish = data.Fish
--         playerRod = data.Rod

--         if data.MinigameConfig then
--             minigameConfig = data.MinigameConfig
--         end

--         currentTier = data.Tier
--         currentSessionId = data.SessionId

--         showGame(true)
--         startGame(true)

--         handleClosingGameUI()
--     end)
-- end
