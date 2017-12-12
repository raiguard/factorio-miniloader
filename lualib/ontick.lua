--[[
    Utilities for managing the on_tick event, periodically invoking
    handlers with staggered invocation.
]]

local M = {}

local on_tick_handlers = {}
local function on_tick_meta_handler(event)
	for handler, interval in pairs(on_tick_handlers) do
		if event.tick % interval == 0 then
			handler()
		end
	end
end

function M.register(f, interval)
	on_tick_handlers[f] = interval
	script.on_event(defines.events.on_tick, on_tick_meta_handler)
end

function M.unregister(f)
	on_tick_handlers[f] = nil
	if not next(on_tick_handlers) then
        script.on_event(defines.events.on_tick, nil)
	end
end

return M