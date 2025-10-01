local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Theme = {
	font = Font.fromId(12187371840),

	color = {
		panel = Color3.fromRGB(181, 136, 99), -- Oak
		border = Color3.fromRGB(92, 64, 51), -- Walnut frame
		text = Color3.fromRGB(250, 240, 210), -- Parchment
		subtle = Color3.fromRGB(95, 85, 80), -- Stone/secondary text

		red = Color3.fromRGB(249, 65, 68),
		orange = Color3.fromRGB(243, 114, 44),
		amber = Color3.fromRGB(248, 150, 30),
		coral = Color3.fromRGB(249, 132, 74),
		yellow = Color3.fromRGB(249, 199, 79),

		green = Color3.fromRGB(144, 190, 109),
		teal = Color3.fromRGB(67, 170, 139),
		tealBlue = Color3.fromRGB(77, 144, 142),
		slateBlue = Color3.fromRGB(87, 117, 144),
		blue = Color3.fromRGB(39, 125, 161),

		white = Color3.fromRGB(255, 255, 255),
		black = Color3.fromRGB(20, 20, 20),
	},

	intent = {
		accent = Color3.fromRGB(67, 170, 139),
		success = Color3.fromRGB(144, 190, 109),
		info = Color3.fromRGB(39, 125, 161),
		warning = Color3.fromRGB(248, 150, 30),
		danger = Color3.fromRGB(249, 65, 68),
		notice = Color3.fromRGB(249, 199, 79),
		muted = Color3.fromRGB(87, 117, 144),
	},

	-- Sizing/styling
	radius = 8,
	padding = 10,
	strokeTransparency = 0.25,

	sizes = {
		button = UDim2.fromScale(0.40, 0.10),
		panel = UDim2.fromScale(0.80, 0.50),
	},

	button = {
		image = "rbxassetid://80427328338898",
		hoverImage = "rbxassetid://80427328338898",
		pressedImage = "rbxassetid://72623624680339",
	},

	textColor = {
		[FFGEnum.CLASS.ENTITY_NAME.Boat] = Color3.fromRGB(92, 64, 51),
		[FFGEnum.CLASS.ENTITY_NAME.Tender] = Color3.fromRGB(181, 136, 99),
		[FFGEnum.CLASS.ENTITY_NAME.PortStorage] = Color3.fromRGB(249, 132, 74),
		[FFGEnum.CLASS.ENTITY_NAME.Building] = Color3.fromRGB(39, 125, 161),
	},
}

return Theme
