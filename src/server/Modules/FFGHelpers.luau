local RunService = game:GetService("RunService")
local FFGHelpers = {}

FFGHelpers.GetStoreName = function()
	return RunService:IsStudio() and "Staging" or "Live"
end

FFGHelpers.PrintLog = function(...: any)
	if RunService:IsStudio() then print(...) end
end

return FFGHelpers
