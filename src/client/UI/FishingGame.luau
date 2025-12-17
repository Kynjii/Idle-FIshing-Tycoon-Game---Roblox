local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local RCharm = require(ReplicatedStorage.Packages.RCharm)
local React = require(ReplicatedStorage.Packages.React)
local Satchel = require(ReplicatedStorage.Packages.Satchel)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local FishingHitNotification = require(ReplicatedStorage.Shared.UI.Components.FishingGame.FishingHitNotification)
local FishingTimingBar = require(ReplicatedStorage.Shared.UI.Components.FishingGame.FishingTimingBar)
local KinProgressBar = require(ReplicatedStorage.Shared.UI.Components.KinProgressBar)
local e = React.createElement

local player = Players.LocalPlayer

type PlayerRod = { Name: string, QualityId: number, BaseDmg: number }
type Fish = { Id: string, QualityId: number, MaxHP: number, Species: string, Variant: string }

local hookedFish: Fish
local playerRod: PlayerRod
local currentTier: number
local reelingSound = workspace.Audio.Reel

local startY = 1
local endY = 0
local up = true

local gameStarted = false

local isButtonHeld = false
local markerConnection = nil

local currentSessionId = nil
local totalHits = 0
local perfectHits = 0
local goodHits = 0
local okHits = 0

local minigameConfig = {
    HitZoneSize = 0.25,
    MarkerSpeed = 0.5,
    DecayRate = 1.0,
    HealMultiplier = 1.0,
}

local hitTimeline = {}

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    if gameStarted then
        elapsed += dt
    end
end)

local FishingGame = {}
FishingGame.Atoms = {
    ShowGame = Charm.atom(false),
    StartGame = Charm.atom(false),
    CurrentFishHP = Charm.atom(0),
    FishHPProgress = Charm.atom(0),
    IsLosingHP = Charm.atom(false),
    HitMarkerPosition = Charm.atom(UDim2.fromScale(0.5, 1)),
    HitMarkerRef = Charm.atom(nil :: Instance?),
    HitArea1Ref = Charm.atom(nil :: Instance?),
    HitArea2Ref = Charm.atom(nil :: Instance?),
    HitArea3Ref = Charm.atom(nil :: Instance?),
    TargetSettings = Charm.atom({ Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0.5, 0.5) }),
    ButtonPressed = Charm.atom(false),
    AreaHit = Charm.atom({ Area = -1, Amount = -1 }),
}

type FishingGame = typeof(FishingGame)

function FishingGame.manager()
    local showGameAtom = RCharm.useAtom(FishingGame.Atoms.ShowGame)

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.4),
        Size = UDim2.fromScale(0.31, 0.52),
        Visible = showGameAtom,
    }, {
        fishingTimingBar = FishingTimingBar.component({
            ButtonPressedAtom = FishingGame.Atoms.ButtonPressed,
            HitMarkerPosition = FishingGame.Atoms.HitMarkerPosition,
            Refs = {
                HitMarker = FishingGame.Atoms.HitMarkerRef,
                Area1 = FishingGame.Atoms.HitArea1Ref,
                Area2 = FishingGame.Atoms.HitArea2Ref,
                Area3 = FishingGame.Atoms.HitArea3Ref,
            },
        }),
        fishingHitNotification = FishingHitNotification.component({ AreaHitAtom = FishingGame.Atoms.AreaHit }),
    })
end

local startGame = Charm.subscribe(FishingGame.Atoms.StartGame, function(newState)
    FishingGame.resetProgress()
    FishingGame.resetHitMarker()
    FishingGame.relocateHitContainer()

    if newState then
        up = true
        elapsed = 0
        hitTimeline = {}
        totalHits = 0
        perfectHits = 0
        goodHits = 0
        okHits = 0
        FishingGame.Atoms.CurrentFishHP(0)
        FishingGame.Atoms.IsLosingHP(false)
    else
        isButtonHeld = false
        FishingGame.Atoms.IsLosingHP(false)
        if markerConnection then
            markerConnection:Disconnect()
            markerConnection = nil
        end
        Events.FireEvent(Events.RemoteNames.GameEnded, player, currentTier)
    end

    if newState then
        markerConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
            if not gameStarted or not isButtonHeld then
                return
            end

            local currentY = FishingGame.Atoms.HitMarkerPosition().Y.Scale
            local markerSpeed = minigameConfig.MarkerSpeed

            if up then
                local newPosition = FishingGame.Atoms.HitMarkerPosition() - UDim2.fromScale(0, deltaTime * markerSpeed)
                FishingGame.Atoms.HitMarkerPosition(newPosition)
            else
                local newPosition = FishingGame.Atoms.HitMarkerPosition() + UDim2.fromScale(0, deltaTime * markerSpeed)
                FishingGame.Atoms.HitMarkerPosition(newPosition)
            end

            if currentY >= endY then
                up = false
            elseif currentY >= startY then
                up = true
            end
        end)
    end
end)

local showGame = Charm.subscribe(FishingGame.Atoms.ShowGame, function(newState)
    if reelingSound.IsPlaying then
        reelingSound:Stop()
    end

    if newState then
        Satchel:SetBackpackEnabled(false)
    else
        Satchel:SetBackpackEnabled(true)
    end
end)

function FishingGame.handleClosingGameUI(self: FishingGame)
    local character = player.Character.PrimaryPart
    local originalPosition = character.CFrame.Position

    while true do
        local distance = player:DistanceFromCharacter(originalPosition)
        if distance >= 8 then
            FishingGame.Atoms.ShowGame(false)
            FishingGame.Atoms.StartGame(false)
            break
        end

        task.wait(0.5)
    end
end

function FishingGame:checkObjectsOverlap(a: GuiObject, b: GuiObject)
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

function FishingGame:resetProgress()
    -- ProgressBar.Reset(pbFrame)
end

function FishingGame:resetHitMarker()
    FishingGame.Atoms.HitMarkerPosition(UDim2.fromScale(0.5, 1))
end

function FishingGame:relocateHitContainer()
    local hitZoneSize = minigameConfig.HitZoneSize
    local minPosition = 0.1
    local maxPosition = 1 - hitZoneSize - 0.1
    local randY = minPosition + math.random() * (maxPosition - minPosition)

    local hitArea1Size = UDim2.fromScale(1, hitZoneSize)
    local hitArea1Position = UDim2.fromScale(0.5, randY)

    FishingGame.Atoms.TargetSettings({ Size = hitArea1Size, Position = hitArea1Position })
end

function FishingGame:startLosingHP()
    if FishingGame.Atoms.IsLosingHP() then
        return
    end

    FishingGame.Atoms.IsLosingHP(true)

    while FishingGame.Atoms.IsLosingHP() and gameStarted do
        task.wait(1)

        local baseDecay = hookedFish.MaxHP / 40
        local actualDecay = baseDecay * minigameConfig.DecayRate

        local amount = FishingGame.Atoms.CurrentFishHP()
        local new = amount - actualDecay
        FishingGame.Atoms.CurrentFishHP(new)

        if FishingGame.Atoms.CurrentFishHP() < 0 then
            FishingGame.Atoms.CurrentFishHP(0)
        end

        local progress = KinProgressBar.CalculateProgress(FishingGame.Atoms.CurrentFishHP(), hookedFish.MaxHP)
        FishingGame.Atoms.FishHPProgress(progress)

        if FishingGame.Atoms.CurrentFishHP() <= 0 then
            FishingGame.Atoms.IsLosingHP(false)

            local fishingResult = {
                Success = false,
                Duration = elapsed,
                Hits = hitTimeline,
            }

            local fishingResultEvent = Events.GetRemote(Events.RemoteNames.FishingResult)
            if fishingResultEvent and currentSessionId then
                fishingResultEvent:FireServer(currentSessionId, fishingResult)
            end

            FishingGame.Atoms.ShowGame(false)
            FishingGame.Atoms.StartGame(false)
            break
        end
    end
end

local buttonReleased = Charm.subscribe(FishingGame.Atoms.ButtonPressed, function(isPressed)
    if isPressed then
        return
    end

    isButtonHeld = false

    if reelingSound.IsPlaying then
        reelingSound:Stop()
    end

    if markerConnection then
        markerConnection:Disconnect()
        markerConnection = nil
    end

    local isOverLapping1 = FishingGame.checkObjectsOverlap(FishingGame.Atoms.HitMarkerRef(), FishingGame.Atoms.HitArea1Ref())
    local isOverLapping2 = FishingGame.checkObjectsOverlap(FishingGame.Atoms.HitMarkerRef(), FishingGame.Atoms.HitArea2Ref())
    local isOverLapping3 = FishingGame.checkObjectsOverlap(FishingGame.Atoms.HitMarkerRef(), FishingGame.Atoms.HitArea3Ref())

    FishingGame.resetHitMarker()

    local area = 0
    if isOverLapping1 then
        area = 1
    end
    if isOverLapping2 then
        area = 2
    end
    if isOverLapping3 then
        area = 3
    end

    table.insert(hitTimeline, {
        time = elapsed,
        area = area,
    })

    if area > 0 then
        totalHits += 1
        if area == 3 then
            perfectHits += 1
        elseif area == 2 then
            goodHits += 1
        elseif area == 1 then
            okHits += 1
        end
    end

    local baseHeal = playerRod.BaseDmg * area
    local actualHeal = baseHeal * minigameConfig.HealMultiplier
    FishingGame.Atoms.AreaHit({ Area = area, Amount = actualHeal })

    local newHp = FishingGame.Atoms.CurrentFishHP()

    if area > 0 then
        newHp += actualHeal
    else
        local missPenalty = playerRod.BaseDmg * minigameConfig.DecayRate
        newHp -= missPenalty
    end

    if newHp < 0 then
        newHp = 0
    end
    FishingGame.Atoms.CurrentFishHP(newHp)

    local progress = KinProgressBar.CalculateProgress(FishingGame.Atoms.CurrentFishHP(), hookedFish.MaxHP)
    FishingGame.Atoms.FishHPProgress(progress)

    if FishingGame.Atoms.CurrentFishHP() >= hookedFish.MaxHP then
        local fishingResult = {
            Success = true,
            Duration = elapsed,
            Hits = hitTimeline,
        }

        local fishingResultEvent = Events.GetRemote(Events.RemoteNames.FishingResult)
        if fishingResultEvent and currentSessionId then
            fishingResultEvent:FireServer(currentSessionId, fishingResult)
        end

        FishingGame.Atoms.ShowGame(false)
        FishingGame.Atoms.StartGame(false)
        return
    end

    FishingGame.relocateHitContainer()

    if area > 0 then
        FishingGame.startLosingHP()
    end
end)

local buttonPressed = Charm.subscribe(FishingGame.Atoms.ButtonPressed, function(isPressed)
    if not isPressed then
        return
    end

    isButtonHeld = true

    if not reelingSound.IsPlaying then
        reelingSound:Play()
    end

    if not markerConnection and gameStarted then
        markerConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
            if not gameStarted or not isButtonHeld then
                return
            end

            local currentY = FishingGame.Atoms.HitMarkerPosition().Y.Scale
            local markerSpeed = minigameConfig.MarkerSpeed

            if up then
                local newPosition = FishingGame.Atoms.HitMarkerPosition() - UDim2.fromScale(0, deltaTime * markerSpeed)
                FishingGame.Atoms.HitMarkerPosition(newPosition)
            else
                local newPosition = FishingGame.Atoms.HitMarkerPosition() + UDim2.fromScale(0, deltaTime * markerSpeed)
                FishingGame.Atoms.HitMarkerPosition(newPosition)
            end

            if currentY >= endY then
                up = false
            elseif currentY <= startY then
                up = true
            end
        end)
    end
end)

local startGameEvent = Events.GetRemote(Events.RemoteNames.StartFishingMiniGame)
if startGameEvent then
    startGameEvent.OnClientEvent:Connect(function(data)
        FishingGame.Atoms.IsLosingHP(false)
        FishingGame.Atoms.StartGame(false)
        task.wait()

        FishingGame.Atoms.CurrentFishHP(0)

        hookedFish = data.Fish
        playerRod = data.Rod

        if data.MinigameConfig then
            minigameConfig = data.MinigameConfig
        end

        currentTier = data.Tier
        currentSessionId = data.SessionId

        FishingGame.Atoms.ShowGame(true)
        FishingGame.Atoms.StartGame(true)

        FishingGame.handleClosingGameUI()
    end)
end

return FishingGame
