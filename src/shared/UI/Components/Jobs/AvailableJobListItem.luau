--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)
local Events = require(ReplicatedStorage.Shared.Events.Events)
local HelperType = require(ReplicatedStorage.Shared.Types.Classes.HelperType)
local Button = require(ReplicatedStorage.Shared.UI.Components.Buttons.Button)
local KinUI = require(ReplicatedStorage.Shared.UI.KinUI)
local Format = require(ReplicatedStorage.Shared.Utils.Format)
local AvailableJobListItem = {}

function AvailableJobListItem.Create(
	props: {
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
	},
	helperSelectedState: StringValue
)
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
	KinUI.ApplyList(container, Enum.FillDirection.Vertical)

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Parent = container
	KinUI.SetPadding(uIPadding, "M")

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
	textLabel.TextScaled = true
	textLabel.Parent = container

	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.fromScale(1, 0.7)
	mainContainer.BackgroundTransparency = 1
	mainContainer.AutomaticSize = Enum.AutomaticSize.Y
	mainContainer.LayoutOrder = 2
	KinUI.ApplyList(mainContainer, Enum.FillDirection.Horizontal, { VAlign = Enum.VerticalAlignment.Center, HFlex = Enum.UIFlexAlignment.SpaceBetween })
	mainContainer.Parent = container

	local slotContainer = Instance.new("Frame")
	slotContainer.Name = "SlotContainer"
	slotContainer.Size = UDim2.fromScale(0.8, 1)
	slotContainer.AutomaticSize = Enum.AutomaticSize.Y
	slotContainer.LayoutOrder = 1
	slotContainer.BackgroundTransparency = 1
	slotContainer.Parent = mainContainer
	local list = KinUI.ApplyList(slotContainer, Enum.FillDirection.Vertical, {})
	KinUI.SetGap(list, "S")

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
		slotMainContainer.Name = "SlotMainContainer"
		slotMainContainer.ZIndex = 5
		slotMainContainer.Size = UDim2.fromScale(0.75, 1)
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
		KinUI.ApplyList(JobListBg, Enum.FillDirection.Horizontal, { HFlex = Enum.UIFlexAlignment.SpaceEvenly, VAlign = Enum.VerticalAlignment.Center })
		KinUI.AddPadding(JobListBg, "L")

		local helperName = Instance.new("TextLabel")
		helperName.Name = "HelperName"
		helperName.Size = UDim2.fromScale(0.7, 0.9)
		helperName.TextXAlignment = Enum.TextXAlignment.Left
		helperName.BackgroundTransparency = 1
		helperName.Font = FFGEnum.THEME.bigFont
		helperName.TextColor3 = isTaken and FFGEnum.QUALITIES[props.Slots.AssignedHelpers[i].QualityId].Color or FFGEnum.THEME.color.white
		helperName.Text = isTaken and props.Slots.AssignedHelpers[i] and props.Slots.AssignedHelpers[i].Name or ""
		helperName.TextScaled = true
		helperName.Parent = JobListBg

		local helperLevel = Instance.new("TextLabel")
		helperLevel.Name = "HelperLevel"
		helperLevel.Size = UDim2.fromScale(0.25, 0.9)
		helperLevel.BackgroundTransparency = 1
		helperLevel.Font = FFGEnum.THEME.bigFont
		helperLevel.TextColor3 = FFGEnum.THEME.color.white
		helperLevel.Text = isTaken and `Level {props.Slots.AssignedHelpers[i].Level}` or ""
		helperLevel.TextColor3 = FFGEnum.THEME.color.Green
		helperLevel.TextScaled = true
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
			KinUI.ApplyAspect(lockedIcon, 16 / 9)
			lockedIcon.Parent = slot
		end

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
			local formattedAmount = Format.CurrencyNumber(props.Slots.UnlockCost or 0)
			buttonText = `{formattedAmount}`
		end

		local actionButton = Button.Create({ Color = buttonColor, CurrencyType = buttonCurrency, Text = buttonText, Size = UDim2.fromScale(0.2, 1) })
		actionButton.Position = UDim2.fromScale(0.9, 0.5)
		actionButton.Name = isTaken and "UnassignButon" or isLocked and "PuchaseButton" or "ActionButton"

		if not isTaken and not isLocked then actionButton.Visible = false end

		actionButton.Activated:Connect(function()
			local helperData = props.Slots.AssignedHelpers[i]
			local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
			if isTaken and helperData then
				if helperData then
					local unassignedJobId = 0
					if assignJobEvent then assignJobEvent:FireServer({ helperId = helperData.Id, jobId = unassignedJobId }) end
				end
			else
				if helperSelectedState then
					local selectedHelperId = helperSelectedState.Value
					if selectedHelperId ~= "" then
						local job_Id = props.Id
						if assignJobEvent then assignJobEvent:FireServer({ helperId = selectedHelperId, jobId = job_Id }) end

						helperSelectedState.Value = ""
					end
				end
			end

			if isLocked then
				local buySlotEvent = Events.GetRemote(Events.RemoteNames.PurchaseJobSlot)
				if buySlotEvent then buySlotEvent:FireServer(props.Id) end
			end
		end)

		local baseText = buttonText
		local baseImage = actionButton.Image
		local buttonIcon = actionButton:FindFirstChild("CurrencyIcon", true) :: ImageLabel?

		-- State Listener
		if helperSelectedState then
			helperSelectedState.Changed:Connect(function(value: any)
				if value ~= "" then
					if not isTaken and not isLocked then
						actionButton.Visible = true
						local buttonText = actionButton:FindFirstChild("ButtonText", true) :: TextLabel?
						if buttonText then buttonText.Text = "Assign" end

						actionButton.Image = FFGEnum.UI.Buttons.ButtonImages.SquareColor.Yellow

						if buttonIcon then buttonIcon.Visible = false end
					end
				else
					if not isTaken and not isLocked then actionButton.Visible = false end
					local buttonText = actionButton:FindFirstChild("ButtonText", true) :: TextLabel?
					if buttonText then buttonText.Text = baseText end

					actionButton.Image = baseImage

					if buttonIcon then buttonIcon.Visible = true end
				end
			end)
		end

		actionButton.Parent = slot

		slot.Parent = slotContainer
	end

	local assignButton = Instance.new("ImageButton")
	assignButton.Name = "QuickAssignButton"
	assignButton.Position = UDim2.fromScale(0.8, 0.5)
	assignButton.ImageColor3 = FFGEnum.THEME.color.white
	assignButton.BackgroundTransparency = 1
	assignButton.LayoutOrder = 2
	assignButton.Image = FFGEnum.UI.Buttons.ButtonImages.Assign
	assignButton.ScaleType = Enum.ScaleType.Fit
	assignButton.Size = UDim2.fromScale(0.2, 0.5)
	assignButton.Parent = mainContainer
	KinUI.ApplyAspect(assignButton, 16 / 9)

	local baseColor = assignButton.ImageColor3
	assignButton.MouseEnter:Connect(function()
		assignButton.ImageColor3 = FFGEnum.THEME.hoverStrokeColor
	end)

	assignButton.MouseLeave:Connect(function()
		assignButton.ImageColor3 = baseColor
	end)

	-- Quick Assign (assigns the first helper it finds)
	assignButton.Activated:Connect(function()
		local numOfAssignedHelpers = #props.Slots.AssignedHelpers
		if numOfAssignedHelpers == props.Slots.MaxSlots then return end
		local availableSlots = (props.Slots.MaxSlots - lockedSlots) - numOfAssignedHelpers
		if availableSlots == 0 then return end

		local getHelperInventory = Events.GetRemoteFn(Events.RemoteFunctionNames.GetHelperInventory)

		if getHelperInventory then
			local data = getHelperInventory:InvokeServer()
			if data then
				for _, helper in pairs(data) do
					local typedHelper = helper :: HelperType.HelperInstance
					if typedHelper.CurrentAssignment > 0 then continue end

					local assignJobEvent = Events.GetRemote(Events.RemoteNames.AssignJob)
					if assignJobEvent then assignJobEvent:FireServer({ typedHelper.Id, props.Id }) end
					break
				end
			end
		end
	end)

	local assignText = Instance.new("TextLabel")
	assignText.Font = FFGEnum.THEME.bigFont
	assignText.TextColor3 = FFGEnum.THEME.color.white
	assignText.BackgroundTransparency = 1
	assignText.AnchorPoint = FFGEnum.THEME.alignment.anchor.bottom
	assignText.Position = FFGEnum.THEME.alignment.position.top
	assignText.TextScaled = true
	assignText.Size = UDim2.fromScale(1, 0.3)
	assignText.Text = "Quick Assign"
	assignText.Parent = assignButton

	container.Parent = availableJobTemplate

	return availableJobTemplate
end

return AvailableJobListItem
