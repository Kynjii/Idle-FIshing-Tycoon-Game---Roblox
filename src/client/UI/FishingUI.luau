local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

return e("ScreenGui", {
    Enabled = false,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, {
    frame = e("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.7, 0.7),
    }, {
        hitBarContainer = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.767742),
            Size = UDim2.fromScale(0.473447, 0.127516),
        }, {
            hitMarker = e("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://122480152315849",
                ImageColor3 = Color3.fromRGB(0, 255, 17),
                Position = UDim2.fromScale(0, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.fromScale(0.01, 1.1),
                SliceCenter = Rect.new(4, 29, 5, 31),
                ZIndex = 10,
            }, {
                uIStroke = e("UIStroke", {
                    LineJoinMode = Enum.LineJoinMode.Bevel,
                    Thickness = 2.1,
                }),
            }),

            uIStroke = e("UIStroke", {
                Thickness = 1.6,
            }),

            uICorner = e("UICorner"),

            catchButton = e("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(32, 13, 175),
                FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                Position = UDim2.fromScale(0.5, 1.1),
                Size = UDim2.fromScale(0.5, 0.5),
                Text = "Hold to Reel",
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
                TextStrokeTransparency = 0.7,
            }, {
                uICorner = e("UICorner"),

                uIStroke = e("UIStroke", {
                    Thickness = 2.6,
                }),
            }),

            inner = e("CanvasGroup", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
            }, {
                hitBoxContainer = e("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(250, 255, 196),
                    Position = UDim2.fromScale(0.908629, 0.5),
                    Size = UDim2.fromScale(0.317259, 1),
                }, {
                    uICorner = e("UICorner"),

                    innerHit = e("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 234, 1),
                        Position = UDim2.fromScale(0.496328, 0.5),
                        Size = UDim2.fromScale(0.537337, 1),
                        ZIndex = 2,
                    }, {
                        uICorner = e("UICorner"),
                    }),

                    bullseye = e("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 157, 0),
                        Position = UDim2.fromScale(0.492656, 0.5),
                        Size = UDim2.fromScale(0.236239, 1),
                        ZIndex = 5,
                    }, {
                        uICorner = e("UICorner"),
                    }),
                }),

                uICorner = e("UICorner"),
            }),
        }),

        fishCounterContainer = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.622005),
            Size = UDim2.fromScale(0.5, 0.0817956),
        }, {
            fishIcon = e("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1.1, 0.5),
                Size = UDim2.fromScale(0.1, 1),
                ZIndex = 10,
            }, {
                bG = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://77902342248833",
                    ImageColor3 = Color3.fromRGB(0, 153, 255),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 5,
                }),

                bG2 = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://91163708935372",
                    ImageColor3 = Color3.fromRGB(0, 7, 141),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }),
            }),
        }),

        successContainer = e("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.385945),
            Size = UDim2.fromScale(0.311134, 0.525346),
        }, {
            var_3 = e("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Visible = false,
            }, {
                bG = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://91163708935372",
                    ImageColor3 = Color3.fromRGB(65, 39, 0),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }),

                superHappy = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://105204636581390",
                    ImageColor3 = Color3.fromRGB(255, 157, 0),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.279, 0.275),
                    Size = UDim2.fromScale(0.266, 0.55),
                    ZIndex = 5,
                }, {
                    uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
                }),

                textLabel = e("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                    Position = UDim2.fromScale(0.720617, 0.281987),
                    Size = UDim2.fromScale(0.558766, 0.292045),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    TextTransparency = 1,
                }),
            }),

            var_2 = e("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Visible = false,
            }, {
                bG = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://91163708935372",
                    ImageColor3 = Color3.fromRGB(50, 46, 0),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }),

                superHappy = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://105204636581390",
                    ImageColor3 = Color3.fromRGB(255, 234, 1),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.279, 0.275),
                    Size = UDim2.fromScale(0.266, 0.55),
                    ZIndex = 5,
                }, {
                    uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
                }),

                textLabel = e("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                    Position = UDim2.fromScale(0.720617, 0.281987),
                    Size = UDim2.fromScale(0.558766, 0.292045),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    TextTransparency = 1,
                }),
            }),

            var_1 = e("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Visible = false,
            }, {
                bG = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://91163708935372",
                    ImageColor3 = Color3.fromRGB(57, 58, 45),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }),

                superHappy = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://105204636581390",
                    ImageColor3 = Color3.fromRGB(250, 255, 196),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.279, 0.275),
                    Size = UDim2.fromScale(0.266, 0.55),
                    ZIndex = 5,
                }, {
                    uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
                }),

                textLabel = e("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                    Position = UDim2.fromScale(0.720617, 0.281987),
                    Size = UDim2.fromScale(0.558766, 0.292045),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    TextTransparency = 1,
                }),
            }),

            var_0 = e("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
            }, {
                bG = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://91163708935372",
                    ImageColor3 = Color3.fromRGB(65, 0, 0),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                }),

                superHappy = e("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://105204636581390",
                    ImageColor3 = Color3.fromRGB(255, 0, 0),
                    ImageTransparency = 1,
                    Position = UDim2.fromScale(0.279383, 0.274955),
                    Size = UDim2.fromScale(0.266367, 0.549909),
                    ZIndex = 5,
                }, {
                    uIAspectRatioConstraint = e("UIAspectRatioConstraint"),
                }),

                textLabel = e("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    FontFace = Font.new("rbxasset://fonts/families/Bangers.json"),
                    Position = UDim2.fromScale(0.720617, 0.281987),
                    Size = UDim2.fromScale(0.558766, 0.292045),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    TextTransparency = 1,
                }),
            }),
        }),
    }),
})
