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

function util.memoize(f)
	local cache = {}
	return function(...)
		local args = {...}
		local crawl = cache
		for i=1,#args-1 do
			local arg = args[i]
			if not crawl[arg] then
				crawl[arg] = {}
			end
			crawl = crawl[arg]
		end
		-- result should be in crawl, if available
		local last_arg = args[#args]
		local res = crawl[last_arg]
		if res ~= nil then
			return unpack(res)
		end
		-- need to evaluate and store
		res = {f(...)}
		crawl[last_arg] = res
		return unpack(res)
	end
end

function util.entitylog(entity)
	return entity.name .. "@" .. entity.position.x .. "," .. entity.position.y
end

return util