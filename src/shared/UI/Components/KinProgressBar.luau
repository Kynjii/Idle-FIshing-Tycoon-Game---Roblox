local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Ripple = require(ReplicatedStorage.Packages.Ripple)
local e = React.createElement

type Props = {
    state: number?,
}

local KinProgressBar = {}

function KinProgressBar.component(props: Props)
    local progressRef = React.useRef(nil)

    React.useEffect(function()
        local progressBar: ImageLabel = progressRef.current
        if not progressBar then
            return
        end

        Ripple.createTween(progressBar, {
            easing = "linear",
            duration = 0.5,
            start = true,
            goal = {
                Size = UDim2.fromScale(props.state or 0, 1),
            },
        })
    end, { props.state })

    return e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = 2,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.8, 1),
    }, {
        progressBG = e("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Image = "rbxassetid://79661382966531",
            ImageColor3 = Color3.fromRGB(6, 38, 65),
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Slice,
            Size = UDim2.fromScale(1, 1),
            SliceCenter = Rect.new(62, 72, 72, 77),
        }, {
            progressBar = e("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://79661382966531",
                ImageColor3 = Color3.fromRGB(62, 255, 62),
                Position = UDim2.fromScale(0, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.fromScale(0, 1),
                SliceCenter = Rect.new(62, 72, 72, 77),
                ZIndex = 2,
                ref = progressRef,
            }),
        }),
    })
end

return KinProgressBar
