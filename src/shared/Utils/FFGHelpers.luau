local FFGHelpers = {}

FFGHelpers.deepWait = function(parent, ...)
	local result = parent
	for _, name in ipairs({ ... }) do
		result = result:WaitForChild(name)
	end
	return result
end

return FFGHelpers
