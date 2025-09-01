local setInterval = function(fn, interval)
	return task.spawn(function()
		while true do
			fn()
			task.wait(interval)
		end
	end)
end

return setInterval
