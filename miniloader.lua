local miniloader = {}

local filters = require("filters")
local ontick = require("lualib.ontick")
local util = require("util")

function miniloader.pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return util.moveposition(entity.position, util.offset(util.opposite_direction(entity.direction), 0.75, 0))
	end
	return entity.position
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

		-- temporarily remove items on the belt so they don't spill on the ground
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

		-- put items back on the belt now that we're in the proper orientation
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

function miniloader.has_filter(entity)
	if not filters.allowed_categories then
		return true
	end
	local inserters = miniloader.get_loader_inserters(entity)
	return inserters[1].get_filter(1) ~= nil
end

function miniloader.set_filter(entity)
	log("set_filter starting on "..util.entitylog(entity))
	if not settings.startup["miniloader-item-restrictions"].value then
		log("set_filter: filters are disabled")
		return
	end
	local new_item = filters.position_acceptable_item(entity.surface, miniloader.pickup_position(entity))
	local inserters = miniloader.get_loader_inserters(entity)
	local old_item = inserters[1].get_filter(1)
	for i = 1, #inserters do
		inserters[i].set_filter(1, new_item)
	end
	if old_item ~= new_item then
		local display_text = {"miniloader-message.unlocked"}
		if new_item then
			display_text = {"miniloader-message.locked", {"item-name."..new_item}}
		end
		entity.surface.create_entity{
			name="flying-text",
			position=entity.position,
			text=display_text,
			color={r=.8,g=1,b=.8,a=.5},
		}
		log("set loader "..serpent.line(entity.position).." to "..(new_item or "nil"))
	end

	if new_item == nil then
		miniloader.register_uninitialized(entity)
	else
		miniloader.unregister_uninitialized(entity)
	end
end

function miniloader.reset_all_filters()
	log("starting reset_all_filters")
	for _, surface in pairs(game.surfaces) do
		for _, entity in ipairs(surface.find_entities_filtered{type="underground-belt"}) do
			if util.is_miniloader(entity) then
				miniloader.set_filter(entity)
			end
		end
	end
end

local function position_key(entity)
	return entity.surface.name .. "@" .. entity.position.x .. "," .. entity.position.y
end

local uninitialized_loaders_iter
local function check_uninitialized()
	uninitialized_loaders_iter, entity = next(global.uninitialized_loaders, uninitialized_loaders_iter)
	if uninitialized_loaders_iter then
		miniloader.set_filter(entity)
	end
end

function miniloader.register_uninitialized(entity)
	local key = position_key(entity)
	local new_value = global.uninitialized_loaders[key] == nil
	global.uninitialized_loaders[key] = entity
	if new_value then
		-- reset iterator due to modification to table
		uninitialized_loaders_iter = nil
	end
	ontick.register(check_uninitialized, 60)
end

function miniloader.unregister_uninitialized(entity)
	if not global.uninitialized_loaders then
		return
	end
	global.uninitialized_loaders[position_key(entity)] = nil
	-- reset iterator due to modification to table
	uninitialized_loaders_iter = nil
	if not next(global.uninitialized_loaders) then
		ontick.unregister(check_uninitialized)
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
    miniloader.set_filter(entity)
end

function miniloader.num_inserters(entity)
	local speed = entity.prototype.belt_speed
	if speed < 0.1 then return 2
	else return 6 end
end

return miniloader