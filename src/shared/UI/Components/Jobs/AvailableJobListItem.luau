--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local AnimateButtonHover = require(ReplicatedStorage.Shared.UI.AnimateButtonHover)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local UIConfig = require(ReplicatedStorage.Shared.UI.UIConfig)
local AvailableJobListItem = {}

function AvailableJobListItem.Create(props: {
	Id: number,
	Category: "Fishing" | "Woodcutting" | "Mining" | "Transporting",
	Label: string,
	Slots: {
		MaxSlots: number,
		LockedSlots: number,
		AssignedHelpers: {
			[number]: { Id: string, Name: string, Level: number, QualityId: number },
		},
		UnlockCost: number?,
	},
	Player: Player,
})
	local availableJobTemplate = Instance.new("Frame")
	availableJobTemplate.AutomaticSize = Enum.AutomaticSize.Y
	availableJobTemplate.Name = "AvailableJobTemplate"
	availableJobTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	availableJobTemplate.BackgroundTransparency = 1
	availableJobTemplate.Position = UDim2.fromScale(0.5, 0.5)
	availableJobTemplate.Size = UDim2.fromScale(1, 1)

	local bG = Instance.new("ImageLabel")
	bG.Name = "BG"
	bG.AnchorPoint = Vector2.new(0.5, 0.5)
	bG.BackgroundTransparency = 1
	bG.Image = "rbxassetid://82464405703579"
	bG.Position = UDim2.fromScale(0.5, 0.5)
	bG.ScaleType = Enum.ScaleType.Slice
	bG.Size = UDim2.fromScale(1, 1)
	bG.SliceCenter = Rect.new(45, 45, 45, 45)
	bG.Parent = availableJobTemplate

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.fromScale(1, 1)
	UIConfig.ApplyList(container, Enum.FillDirection.Vertical)

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Parent = container
	UIConfig.SetPadding(uIPadding, "M")

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "JobName"
	textLabel.LayoutOrder = 1
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Font = FFGEnum.THEME.bigFont
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0.49, 0.2)
	textLabel.Text = props.Label or ""
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = 14
	UIConfig.ApplyTextConstraints(textLabel, "body")
	textLabel.Parent = container

	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.fromScale(1, 0.7)
	mainContainer.BackgroundTransparency = 1
	mainContainer.AutomaticSize = Enum.AutomaticSize.Y
	mainContainer.LayoutOrder = 2
	UIConfig.ApplyList(mainContainer, Enum.FillDirection.Horizontal, { VAlign = Enum.VerticalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })
	mainContainer.Parent = container

	local slotContainer = Instance.new("Frame")
	slotContainer.Name = "SlotContainer"
	slotContainer.Size = UDim2.fromScale(0.7, 1)
	slotContainer.AutomaticSize = Enum.AutomaticSize.Y
	slotContainer.LayoutOrder = 1
	slotContainer.BackgroundTransparency = 1
	slotContainer.Parent = mainContainer
	local list = UIConfig.ApplyList(slotContainer, Enum.FillDirection.Vertical, { VAlign = Enum.VerticalAlignment.Center })
	UIConfig.SetGap(list, "S")

	local lockedSlots: number = props.Slots.LockedSlots
	for i = 1, props.Slots.MaxSlots do
		local isTaken = true
		if not props.Slots.AssignedHelpers[i] then isTaken = false end

		local isLocked = false
		-- Min number of slots available will always be 1
		if i > 1 then
			-- Max number of locked slots will always be 2
			if lockedSlots == 2 then
				isLocked = true
				lockedSlots -= 1
			elseif lockedSlots == 1 then
				if i == 3 then
					isLocked = true
					lockedSlots = 0
				end
			end
		end

		local slot = Instance.new("Frame")
		slot.Name = "SlotListItem"
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromScale(1, 0.4)

		local slotMainContainer = Instance.new("Frame")
		slotMainContainer.ZIndex = 5
		slotMainContainer.Size = UDim2.fromScale(0.7, 1)
		slotMainContainer.BackgroundTransparency = 1
		slotMainContainer.Parent = slot

		local JobListBg = Instance.new("ImageLabel")
		JobListBg.Name = "JobListBg"
		JobListBg.Size = UDim2.fromScale(1, 1)
		JobListBg.BackgroundTransparency = 1
		JobListBg.Image = FFGEnum.UI.Frames.ListItem
		JobListBg.ScaleType = Enum.ScaleType.Slice
		JobListBg.SliceCenter = Rect.new(45, 45, 45, 45)

		if isLocked then
			JobListBg.ImageColor3 = FFGEnum.THEME.color.textMuted
			JobListBg.ImageTransparency = 0.25
		end
		JobListBg.Parent = slotMainContainer
		UIConfig.ApplyList(JobListBg, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceBetween })

		local helperName = Instance.new("TextLabel")
		helperName.Name = "HelperName"
		helperName.Size = UDim2.fromScale(0.7, 1)
		helperName.TextXAlignment = Enum.TextXAlignment.Left
		helperName.BackgroundTransparency = 1
		helperName.Font = FFGEnum.THEME.bigFont
		helperName.TextColor3 = isTaken and FFGEnum.QUALITIES[props.Slots.AssignedHelpers[i].QualityId].Color or FFGEnum.THEME.color.white
		helperName.Text = isTaken and props.Slots.AssignedHelpers[i] and props.Slots.AssignedHelpers[i].Name or ""

		UIConfig.ApplyTextConstraints(helperName, "caption")
		helperName.Parent = JobListBg

		local helperLevel = Instance.new("TextLabel")
		helperLevel.Name = "HelperLevel"
		helperLevel.Size = UDim2.fromScale(0.3, 1)
		helperLevel.BackgroundTransparency = 1
		helperLevel.Font = FFGEnum.THEME.bigFont
		helperLevel.TextColor3 = FFGEnum.THEME.color.white
		helperLevel.Text = isTaken and `Level {props.Slots.AssignedHelpers[i].Level}` or ""
		UIConfig.ApplyTextConstraints(helperLevel, "caption")
		helperLevel.Parent = JobListBg

		if isLocked then
			local lockedIcon = Instance.new("ImageLabel")
			lockedIcon.Name = "lockedIcon"
			lockedIcon.Size = UDim2.fromScale(0.2, 0.2)
			lockedIcon.AnchorPoint = FFGEnum.THEME.alignment.anchor.center
			lockedIcon.Position = UDim2.fromScale(0.35, 0.5)
			lockedIcon.BackgroundTransparency = 1
			lockedIcon.ZIndex = 5
			lockedIcon.Image = FFGEnum.UI.Icons.PadLock
			lockedIcon.ScaleType = Enum.ScaleType.Fit
			UIConfig.ApplyAspect(lockedIcon, 16 / 9)
			lockedIcon.Parent = slot
		end

		if isTaken or isLocked then
			local buttonColor: string
			if isTaken then
				buttonColor = "Red"
			else
				buttonColor = "Green"
			end

			local buttonCurrency: string
			if isTaken then
				buttonCurrency = "None"
			else
				buttonCurrency = "Gold"
			end

			local buttonText: string
			if isTaken then
				buttonText = "-"
			else
				buttonText = `{props.Slots.UnlockCost or "Buy"}`
			end

			local actionButton = Button.Create({ Color = buttonColor, CurrencyType = buttonCurrency, Text = buttonText, Size = UDim2.fromScale(0.4, 1) })
			actionButton.Position = UDim2.fromScale(0.9, 0.5)
			actionButton.Name = isLocked and "UnassignButon" or isLocked and "PuchaseButton" or ""

			actionButton.Activated:Connect(function()
				if isTaken then
					local helperData = props.Slots.AssignedHelpers[i]
					if helperData then
						local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
						local unassignedJobId = 0
						if assignJobEvent then assignJobEvent:FireServer(helperData.Id, unassignedJobId) end
					end
				end

				if isLocked then
					local buySlotEvent = Events.GetRemote(Events.RemoteNames.PurchaseJobSlot)
					if buySlotEvent then buySlotEvent:FireServer(props.Id) end
				end
			end)

			actionButton.Parent = slot
		end

		slot.Parent = slotContainer
	end

	local assignButton = Instance.new("ImageButton")
	assignButton.Name = "AssignButton"
	assignButton.LayoutOrder = 2
	assignButton.Position = UDim2.fromScale(0.8, 0.5)
	assignButton.BackgroundTransparency = 1
	assignButton.Image = "rbxassetid://119147831935362"
	assignButton.ScaleType = Enum.ScaleType.Fit
	assignButton.Size = UDim2.fromScale(0.2, 0.5)
	UIConfig.ApplyAspect(assignButton, 16 / 9)
	assignButton.Parent = mainContainer

	local baseSize = assignButton.Size
	assignButton.MouseEnter:Connect(function()
		AnimateButtonHover.Enter(assignButton, baseSize)
	end)

	assignButton.MouseLeave:Connect(function()
		AnimateButtonHover.Leave(assignButton, baseSize)
	end)

	-- Quick Assign (assigns the first helper it finds)
	assignButton.Activated:Connect(function()
		local numOfAssignedHelpers = #props.Slots.AssignedHelpers
		if numOfAssignedHelpers == props.Slots.MaxSlots then return end
		local availableSlots = (props.Slots.MaxSlots - lockedSlots) - numOfAssignedHelpers
		if availableSlots == 0 then return end

		local getPlayerInventory = Events.GetRemoteFn(Events.RemoteFunctionNames.GetPlayerInventory)

		if getPlayerInventory then
			local data = getPlayerInventory:InvokeServer()
			if data then
				for _, helper in pairs(data) do
					local typedHelper = helper :: HelperType.HelperInstance
					if typedHelper.CurrentAssignment > 0 then continue end

					local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
					if assignJobEvent then assignJobEvent:FireServer(typedHelper.Id, props.Id) end
					break
				end
			end
		end
	end)

	container.Parent = availableJobTemplate

	return availableJobTemplate
end

return AvailableJobListItem
