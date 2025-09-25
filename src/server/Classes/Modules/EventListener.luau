local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = require(ReplicatedStorage.Shared.Events.Events)

local EventListener = {}
EventListener.Events = {}

function EventListener.Init()
	for name, event in pairs(Events.RemoteNames) do
		EventListener.Events[name] = Events.GetRemote(name)
	end

	print(EventListener.Events)
end

return EventListener
