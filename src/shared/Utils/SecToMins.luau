local SecToMins = {}

function SecToMins.GetString(seconds)
	if seconds > 60 then
		local minutes = math.floor(seconds / 60)
		local remainingSeconds = seconds % 60
		if remainingSeconds < 10 then remainingSeconds = `0{seconds % 60}` end
		return `{minutes}:{remainingSeconds}`
	else
		return `{seconds}`
	end
end

return SecToMins
