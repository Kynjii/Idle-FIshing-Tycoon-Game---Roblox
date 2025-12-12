local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local RC = require(ReplicatedStorage.Packages["React-charm"])
local PlayerStateService = require(ReplicatedStorage.Shared.Atoms.PlayerStateService)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
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
    local fishingLevelState: FishingLevelState = RC.useAtom(PlayerStateService.State.FishingSkillState)

    local state = fishingLevelState
    local xp = state.FishingXP or 0
    local current = state.TotalForCurrentLevel or 0
    local next = state.TotalForNextLevel or 0

    local currentLevelProgress = xp - current
    local xpNeededForThisLevel = next - current

    local progress = (xpNeededForThisLevel > 0) and math.clamp(currentLevelProgress / xpNeededForThisLevel, 0, 1) or 0

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
            AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
            BackgroundTransparency = 1,
            Font = FFGEnum.THEME.bigFont,
            LayoutOrder = 1,
            Position = FFGEnum.THEME.alignment.position.center,
            Size = UDim2.fromScale(0.1, 1),
            Text = `{fishingLevelState.FishingLevel}`,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
        }, {
            uIStroke = e("UIStroke", {
                Thickness = 2,
            }),
        }),

        nextLevel = e("TextLabel", {
            AnchorPoint = FFGEnum.THEME.alignment.anchor.center,
            BackgroundTransparency = 1,
            Font = FFGEnum.THEME.bigFont,
            LayoutOrder = 3,
            Position = FFGEnum.THEME.alignment.position.center,
            Size = UDim2.fromScale(0.1, 1),
            Text = `{fishingLevelState.FishingLevel + 1}`,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
        }, {
            uIStroke = e("UIStroke", {
                Thickness = 2,
            }),
        }),

        KinProgressBar.component({ state = progress }),
    })
end

return FishingSkillBar
