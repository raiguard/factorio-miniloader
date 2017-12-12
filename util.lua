local util = {}

-- Position adjustments

function util.moveposition(position, offset)
	return {x=position.x + offset.x, y=position.y + offset.y}
end

function util.offset(direction, longitudinal, orthogonal)
	if direction == 0 then --north
		return {x=orthogonal, y=-longitudinal}
	end

	if direction == 4 then -- south
		return {x=-orthogonal, y=longitudinal}
	end

	if direction == 2 then -- east
		return {x=longitudinal, y=orthogonal}
	end

	if direction == 6 then -- west
		return {x=-longitudinal, y=-orthogonal}
	end
end

function util.move_box(box, offset)
	return {
		left_top = util.moveposition(box.left_top, offset),
		right_bottom = util.moveposition(box.right_bottom, offset),
	}
end

-- Direction utilities

function util.is_ns(direction)
	return direction == 0 or direction == 4
end

function util.is_ew(direction)
	return direction == 2 or direction == 6
end

function util.opposite_direction(direction)
	if direction >= 4 then
		return direction - 4
	end
	return direction + 4
end

-- underground-belt utilities

-- underground_side returns the "back" or hood side of the underground belt
function util.underground_side(ug_belt)
	if ug_belt.belt_to_ground_type == "output" then
		return util.opposite_direction(ug_belt.direction)
	end
	return ug_belt.direction
end

-- belt_side returns the "front" side of the underground belt
function util.belt_side(ug_belt)
	if ug_belt.belt_to_ground_type == "input" then
		return util.opposite_direction(ug_belt.direction)
	end
	return ug_belt.direction
end

-- miniloader utilities

function util.is_miniloader(entity)
	return string.find(entity.name, "miniloader$") ~= nil
end

local on_tick_handlers = {}
local function on_tick_meta_handler(event)
	for handler, interval in pairs(on_tick_handlers) do
		if event.tick % interval == 0 then
			handler()
		end
	end
end

function util.register_on_tick(f, interval)
	on_tick_handlers[f] = interval
	script.on_event(defines.events.on_tick, on_tick_meta_handler)
end

function util.unregister_on_tick(f)
	on_tick_handlers[f] = nil
	if not next(on_tick_handlers) then
		script.on_event(defines.events.on_tick, nil)
	end
end

return util