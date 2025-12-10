local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

return e("ScreenGui", {
    Enabled = false,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, {
    main = e("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(1.005, 0.01),
        Size = UDim2.fromScale(0.134183, 0.98),
    }, {
        uIListLayout = e("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),

        currencies = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Position = UDim2.fromScale(0.5, 0.839594),
            Size = UDim2.fromScale(1, 0.071),
        }, {
            uIListLayout = e("UIListLayout", {
                Padding = UDim.new(0.15, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),

            frame = e("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0.866515),
            }, {
                bG = e("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }, {
                    hudBackground = e("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://98587631484236",
                        ImageColor3 = Color3.fromRGB(188, 150, 0),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Rotation = 180,
                        ScaleType = Enum.ScaleType.Slice,
                        Size = UDim2.fromScale(1, 1),
                        SliceCenter = Rect.new(14, 30, 17, 34),
                        ZIndex = 0,
                    }),

                    bG = e("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://140479491794392",
                        ImageColor3 = Color3.fromRGB(202, 181, 42),
                        Position = UDim2.fromScale(0.5, 0.5),
                        ScaleType = Enum.ScaleType.Slice,
                        Size = UDim2.fromScale(1, 1),
                        SliceCenter = Rect.new(22, 22, 23, 23),
                        ZIndex = 5,
                    }),
                }),

                container = e("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }, {
                    currencyTextLabelTemplate = e("TextLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                        Interactable = false,
                        LayoutOrder = 2,
                        Position = UDim2.fromScale(0.538998, 0.526316),
                        RichText = true,
                        Size = UDim2.fromScale(0.900306, 1.05263),
                        Text = "10k",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        TextStrokeTransparency = 0,
                        Visible = false,
                        ZIndex = 5,
                    }, {
                        uIPadding = e("UIPadding", {
                            PaddingBottom = UDim.new(0.0270408, 0),
                            PaddingLeft = UDim.new(0.01, 0),
                            PaddingTop = UDim.new(0.0270408, 0),
                        }),

                        uIStroke = e("UIStroke", {
                            LineJoinMode = Enum.LineJoinMode.Bevel,
                            Thickness = 2,
                        }),
                    }),

                    uIPadding = e("UIPadding", {
                        PaddingBottom = UDim.new(0.05, 0),
                        PaddingLeft = UDim.new(0.05, 0),
                        PaddingRight = UDim.new(0.05, 0),
                    }),
                }),

                icon = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://113802680310061",
                    LayoutOrder = 1,
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromScale(0.262281, 1.10947),
                }, {
                    uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
                }),
            }),
        }),
    }),
})
