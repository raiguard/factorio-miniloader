local miniloader = {}

local filters = require("filters")
local util = require("util")

function miniloader.pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return util.moveposition(entity.position, util.offset(util.opposite_direction(entity.direction), 0.75, 0))
	end
	return util.moveposition(entity.position, util.offset(entity.direction, 0.25, 0))
end

function miniloader.drop_positions(entity)
	if entity.belt_to_ground_type == "output" then
		local chest_dir = util.opposite_direction(entity.direction)
		local p1 = util.moveposition(entity.position, util.offset(chest_dir, -0.25, 0.25))
		local p2 = util.moveposition(p1, util.offset(chest_dir, 0, -0.5))
		return {p1, p2}
	end
	local chest_dir = entity.direction
	local p1 = util.moveposition(entity.position, util.offset(chest_dir, 0.75, 0.25))
	local p2 = util.moveposition(p1, util.offset(chest_dir, 0, -0.5))
	return {p1, p2}
end

function miniloader.get_loader_inserters(entity)
	if entity == nil then
		error("got nil entity")
	end
	return entity.surface.find_entities_filtered{
		position = entity.position,
		name = entity.name .. "-inserter"
	}
end

function miniloader.set_orientation(entity, direction, type)
	if entity.belt_to_ground_type ~= type then
		-- need to destroy and recreate since belt_to_ground_type is read-only
		local surface = entity.surface
		local name = entity.name
		local position = entity.position
		local force = entity.force
		local from_transport_lines = {}
		for i=1, 2 do
			local tl = entity.get_transport_line(i)
			from_transport_lines[i] = tl.get_contents()
			tl.clear()
		end
		entity.destroy()
		entity = surface.create_entity{
			name = name,
			position = position,
			direction = direction,
			type = type,
			force = force,
		}
		for i=1, 2 do
			local tl = entity.get_transport_line(i)
			for name, count in pairs(from_transport_lines[i]) do
				tl.insert_at_back({name=name, count=count})
			end
		end
	else
		entity.direction = direction
	end
	miniloader.update_inserters(entity)
end

function miniloader.set_filter(entity)
	local item = filters.position_acceptable_item(entity.surface, miniloader.pickup_position(entity))
	local inserters = miniloader.get_loader_inserters(entity)
	if inserters[1].get_filter(1) ~= item then
		log("set loader "..serpent.line(entity.position).." to "..(item or "nil"))
	end

	for i = 1, #inserters do
		inserters[i].set_filter(1, item)
	end
	return item ~= nil
end

--[[
local function position_key(entity)
	return entity.surface.name .. "@" .. entity.position.x .. "," .. entity.position.y
end

local function miniloader_by_position_key(key)
	local surface, x, y = string.match(key, "^([^@]+)@([%d.-]+),([%d.-]+)$")
	if not surface then
		return nil
	end
	return game.surfaces[surface].find_entities_filtered{type="underground-belt", position={x, y}}[1]
end
]]

local uninitialized_loaders = {}
local uninitialized_loaders_iter
local function check_uninitialized()
	uninitialized_loaders_iter, _ = next(uninitialized_loaders, uninitialized_loaders_iter)
	if uninitialized_loaders_iter then
		local entity = miniloader_by_position_key(uninitialized_loaders_iter)
		if entity then
			--miniloader.update_inserters(entity)
		end
	end
end

function miniloader.register_uninitialized(entity)
	uninitialized_loaders[position_key(entity)] = true
	-- reset iterator due to modification to table
	uninitialized_loaders_iter = nil
	util.register_on_tick(check_uninitialized, 1)
end

function miniloader.unregister_uninitialized(entity)
	uninitialized_loaders[position_key(entity)] = nil
	-- reset iterator due to modification to table
	uninitialized_loaders_iter = nil
	if not next(uninitialized_loaders) then
		util.unregister_on_tick(check_uninitialized)
	end
end

function miniloader.update_inserters(entity)
	local inserters = miniloader.get_loader_inserters(entity)
	local pickup = miniloader.pickup_position(entity)
	local drop = miniloader.drop_positions(entity)

	local n = #inserters
	for i = 1, n / 2 do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[1]
		inserters[i].direction = inserters[i].direction
	end
	for i = n / 2 + 1, n do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[2]
		inserters[i].direction = inserters[i].direction
    end
    local found_item = miniloader.set_filter(entity)
	if not found_item then
		miniloader.register_uninitialized(entity)
    else
		miniloader.unregister_uninitialized(entity)
    end
end

function miniloader.num_inserters(entity)
	local speed = entity.prototype.belt_speed
	if speed < 0.1 then return 2
	else return 6 end
end

return miniloader