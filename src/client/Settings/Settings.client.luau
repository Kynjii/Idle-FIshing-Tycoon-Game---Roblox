-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Events = require(ReplicatedStorage.Shared.Events.Events)
-- local DeepWait = require(ReplicatedStorage.Shared.Utils.DeepWait)

-- local player = Players.LocalPlayer
-- local settingsGui: ScreenGui = DeepWait(player, "PlayerGui", "Settings")

-- local settingsOpened = false

-- local settingsBtn = settingsGui:FindFirstChild("SettingsButton", true) :: ImageButton
-- local settingsModal = settingsGui:FindFirstChild("SettingsModal", true) :: Frame
-- local confirmationModal = settingsGui:FindFirstChild("ConfirmationModal", true) :: Frame

-- if settingsBtn then
-- 	local function toggleSettings()
-- 		if settingsOpened then
-- 			settingsOpened = false
-- 			settingsModal.Visible = false
-- 			confirmationModal.Visible = false
-- 		else
-- 			settingsOpened = true
-- 			settingsModal.Visible = true
-- 		end
-- 	end

-- 	settingsBtn.MouseButton1Click:Connect(function()
-- 		toggleSettings()
-- 	end)
-- end

-- if settingsModal then
-- 	local resetButton = settingsModal:FindFirstChild("ResetButton", true) :: ImageButton

-- 	if resetButton then resetButton.Activated:Connect(function()
-- 		confirmationModal.Visible = true
-- 		settingsModal.Visible = false
-- 	end) end
-- end

-- if confirmationModal then
-- 	local confirmationButton_NO = confirmationModal:FindFirstChild("No", true) :: ImageButton
-- 	local confirmationButton_YES = confirmationModal:FindFirstChild("Yes", true) :: ImageButton

-- 	if confirmationButton_NO then confirmationButton_NO.Activated:Connect(function()
-- 		confirmationModal.Visible = false
-- 		settingsModal.Visible = true
-- 	end) end

-- 	local function handleReset()
-- 		local resetEvent = Events.GetRemote(Events.RemoteNames.GameReset)
-- 		resetEvent:FireServer(player)

-- 		confirmationModal.Visible = false
-- 		settingsModal.Visible = false
-- 	end

-- 	if confirmationButton_YES then confirmationButton_YES.Activated:Connect(function()
-- 		handleReset()
-- 	end) end
-- end
