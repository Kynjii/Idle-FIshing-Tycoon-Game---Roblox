local getColor3 = function(value, fallback)
	if typeof(value) == "Color3" then
		return value
	elseif type(value) == "function" then
		local result = value()
		if typeof(result) == "Color3" then return result end
	end
	return fallback
end

return getColor3
