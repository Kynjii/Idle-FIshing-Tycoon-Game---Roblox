local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

return e("ScreenGui", {
    DisplayOrder = 5,
    Enabled = false,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, {
    skillBarContainer = e("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.99),
        Size = UDim2.fromScale(0.4, 0.04),
    }),
})
