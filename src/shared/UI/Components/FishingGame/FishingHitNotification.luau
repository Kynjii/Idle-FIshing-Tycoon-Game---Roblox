local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local RCharm = require(ReplicatedStorage.Packages.RCharm)
local React = require(ReplicatedStorage.Packages.React)
local ReactRipple = require(ReplicatedStorage.Packages.ReactRipple)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Format = require(ReplicatedStorage.Shared.Utils.Format)

local useTween = ReactRipple.useTween
local e = React.createElement

local FishingHitNotification = {}

local colorMap = {
    [0] = Color3.fromRGB(226, 23, 16),
    [1] = Color3.fromRGB(255, 255, 127),
    [2] = Color3.fromRGB(255, 169, 21),
    [3] = Color3.fromRGB(120, 255, 16),
}

function FishingHitNotification.component(props: { AreaHitAtom: Charm.Atom<{ Area: number, Amount: number }> })
    local areaHit = RCharm.useAtom(props.AreaHitAtom).Area
    local hitAmount = RCharm.useAtom(props.AreaHitAtom).Amount

    local color = colorMap[areaHit]
    local formattedText = Format.CurrencyNumber(hitAmount)

    local instanceBinding, instanceTween = useTween(1, { easing = "linear", duration = 0.5 })

    React.useEffect(function()
        if areaHit == -1 then
            return
        end

        instanceTween:setGoal(0)
        instanceTween:start()
    end, { props })

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.385945),
        Size = UDim2.fromScale(0.311134, 0.525346),
    }, {
        hitNotification = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.3),
            Size = UDim2.fromScale(0.5, 0.5),
        }, {
            hitIcon = e("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = instanceBinding:map(function(p)
                    return p
                end),
                Image = FFGEnum.UI.Icons.Sword,
                Position = UDim2.fromScale(0.2, 0.5),
                ImageColor = color,
                Size = UDim2.fromScale(0.4, 0.55),
                ZIndex = 5,
            }, {
                uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
            }),

            hitTextLabel = e("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                TextTransparency = instanceBinding:map(function(p)
                    return p
                end),
                Font = FFGEnum.THEME.bigFont,
                Position = UDim2.fromScale(0.65, 0.5),
                Size = UDim2.fromScale(0.55, 0.3),
                TextColor3 = color,
                TextScaled = true,
                Text = formattedText,
            }),

            hitIconShadow = e("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ImageTransparency = instanceBinding:map(function(p)
                    return p
                end),
                Image = FFGEnum.UI.Icons.Sword,
                ImageColor3 = Color3.new(),
                Position = UDim2.fromScale(0.21, 0.51),
                Size = UDim2.fromScale(0.4, 0.55),
            }, {
                uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
            }),
        }),
    })
end

return FishingHitNotification
