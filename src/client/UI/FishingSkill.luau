local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local React = require(ReplicatedStorage.Packages.React)
local RC = require(ReplicatedStorage.Packages["React-charm"])
local PlayerStateService = require(ReplicatedStorage.Shared.Atoms.PlayerStateService)
local KinProgressBar = require(ReplicatedStorage.Shared.UI.Components.KinProgressBar)
local e = React.createElement

type FishingLevelState = {
    FishingLevel: number?,
    FishingXP: number?,
    TotalForNextLevel: number?,
    TotalForCurrentLevel: number?,
}

local FishingSkillBar = {}

function FishingSkillBar.component()
    local _fishingLevelState: FishingLevelState, _setFishingLevelState = RC.useAtom(PlayerStateService.State.FishingSkillState)

    local progress = Charm.computed(function()
        local newState = table.clone(_fishingLevelState) :: FishingLevelState
        local newXpAmount = newState.FishingXP or 0
        local totalForCurrentLevel = newState.TotalForCurrentLevel or 0
        local totalForNextLevel = newState.TotalForNextLevel or 0

        local currentLevelProgress = newXpAmount - totalForCurrentLevel
        local xpNeededForThisLevel = totalForNextLevel - totalForCurrentLevel

        local progress = (xpNeededForThisLevel > 0) and math.clamp(currentLevelProgress / xpNeededForThisLevel, 0, 1) or 0

        return progress
    end)

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.99),
        Size = UDim2.fromScale(0.4, 0.04),
    }, {
        uIListLayout = e("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly,
        }),

        currentLevel = e("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
            LayoutOrder = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.1, 1),
            Text = `{_fishingLevelState.FishingLevel}`,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
        }, {
            uIStroke = e("UIStroke", {
                Thickness = 2,
            }),
        }),

        nextLevel = e("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
            LayoutOrder = 3,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.1, 1),
            Text = `{_fishingLevelState.FishingLevel + 1}`,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
        }, {
            uIStroke = e("UIStroke", {
                Thickness = 2,
            }),
        }),

        KinProgressBar.component({ state = progress() }),
    })
end

return FishingSkillBar
