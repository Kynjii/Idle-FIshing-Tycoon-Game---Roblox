local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopGUI = require(ReplicatedStorage.Shared.UI.Components.Shop.ShopGUI)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)

local function story(target)
	local instance = ShopGUI.Create()
	local uiFrame = instance:FindFirstChild("PanelContainer")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	KinUI.AddStroke(frame, "L")
	frame.Parent = target

	uiFrame.Parent = frame

	local innerWindow = uiFrame:FindFirstChild("InnerWindow", true)
	ShopGUI.RenderInfoPanel(
		innerWindow,
		{
			BaseCost = 16000,
			CurrencyType = "Gold",
			CurrentAssignment = 0,
			Description = "A crew member specialized in Transporting Fish from the Port to the Market.",
			Entity = "Helper",
			Id = "50bf32f2-deae-4a0f-9420-9ec0e27a9d99",
			IsPurchased = true,
			ItemImage = "rbxassetid://135331905621652",
			JobCategory = "Transporting",
			Level = 1,
			MaxLevel = 100,
			Name = "Transporter",
			Owner = 8984765705,
			QualityId = 3,
			RealmId = 1,
			ResourceInStorage = 0,
			Stats = {
				FishValue = 0.1,
				LoadTime = 8,
				Storage = 62,
				WalkSpeed = 6,
			},
			StorageFull = true,
			TeamId = 1,
			UpgradeCost = 17280,
			UpgradeStage = 1,
		}
	)

	return function()
		uiFrame:Destroy()
	end
end

return story
