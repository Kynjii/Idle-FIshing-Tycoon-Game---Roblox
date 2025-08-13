local RunService = game:GetService("RunService")
local FFGHelpers = {}

FFGHelpers.deepWait = function(parent, ...)
	local result = parent
	for _, name in ipairs({ ... }) do
		result = result:WaitForChild(name)
	end
	return result
end

FFGHelpers.GetStoreName = function()
	return RunService:IsStudio() and "Staging" or "Live"
end

FFGHelpers.PrintLog = function(msg: string, v: any)
	if RunService:IsStudio() then
		if not v then
			print(msg)
		else
			print(msg, v)
		end
	end
end

FFGHelpers.SUFFIXES = {
	{ value = 1e54, symbol = "Et" }, -- Eternium
	{ value = 1e51, symbol = "St" }, -- Starwoven
	{ value = 1e48, symbol = "Vs" }, -- Voidshard
	{ value = 1e45, symbol = "Tg" }, -- Thronesteel
	{ value = 1e42, symbol = "Sk" }, -- Skyglass
	{ value = 1e39, symbol = "Nf" }, -- Nightfur
	{ value = 1e36, symbol = "Op" }, -- Opalflame
	{ value = 1e33, symbol = "Ar" }, -- Arcanite
	{ value = 1e30, symbol = "Lp" }, -- Lumipaw
	{ value = 1e27, symbol = "Al" }, -- Astralite
	{ value = 1e24, symbol = "Dr" }, -- Dragonite
	{ value = 1e21, symbol = "Ct" }, -- Celestite
	{ value = 1e18, symbol = "My" }, -- Mythril
	{ value = 1e15, symbol = "Qa" }, -- Quadrillion
	{ value = 1e12, symbol = "T" }, -- Trillion
	{ value = 1e9, symbol = "B" }, -- Billion
	{ value = 1e6, symbol = "M" }, -- Million
	{ value = 1e3, symbol = "K" }, -- Thousand
}

return FFGHelpers
