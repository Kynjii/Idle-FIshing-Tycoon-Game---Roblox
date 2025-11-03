local ServerScriptService = game:GetService("ServerScriptService")

local EntityNameplate = require(ServerScriptService.Server.Modules.EntityNameplate.EntityNameplate)

local function story(target)
	local nameplate = EntityNameplate.Create({
		Level = 55,
		Name = "Fishing Boat",
		JobCategory = "Transporting",
		MaxStorage = 546,
		QualityId = 6,
		UpgradeStage = 5,
	})
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 150, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(58, 56, 211)
	frame.Parent = target

	-- BillboardGui doesn't work with UILabs, needs to grab the main frame instead
	local mainContainer = nameplate:FindFirstChild("Main", true)
	mainContainer.Parent = frame

	return function()
		nameplate:Destroy()
	end
end

return story
