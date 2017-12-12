local filters = {
	allowed_categories = {"bulk"},
}

local output_inventories = {
	defines.inventory.cargo_wagon,
	defines.inventory.chest,
	defines.inventory.assembling_machine_output,
	defines.inventory.furnace_result,
	defines.inventory.burnt_result,
	defines.inventory.lab_input,
	defines.inventory.rocket_silo_result,
	defines.inventory.turret_ammo,
	defines.inventory.roboport_robot
}

local patterns = {
	bulk = {
		-- generic
		"-ore$",
		-- angelsrefining
		"^angels-ore",
		"^angels-.*-nugget",
		"^angels-.*-pebbles",
		"^angels-.*-slag",
		-- angelssmelting
		"^processed-"
	}
}

-- bulk items that don't fit the above patterns
local items = {
	bulk = {
		-- base
		"coal",
		"landfill",
		"stone",
		"sulfur",
		-- bobores
		"quartz",
		-- bobplates
		"carbon",
		-- angelsrefining
		"stone-crushed",
		"slag"
	}
}

local function has_transport_line(entity)
	return entity.type == "transport-belt" or entity.type == "underground-belt" or entity.type == "splitter" or
		entity.type == "loader"
end

local function is_in_category(item_name, category)
	for _, it in ipairs(items[category]) do
		if item_name == it then
			return true
		end
	end
	for _, pat in ipairs(patterns[category]) do
		if string.match(item_name, pat) then
			return true
		end
	end
	return false
end

local acceptable_item_cache = {}

local function is_acceptable_item(item_name)
	if filters.allowed_categories == nil then
		return true
	end
	if acceptable_item_cache[item_name] then
		return true
	end
	for _, category in ipairs(filters.allowed_categories) do
		if is_in_category(item_name, category) then
			acceptable_item_cache[item_name] = true
			return true
		end
	end
	acceptable_item_cache[item_name] = false
	return false
end

local function transport_line_index(entity, position)
	if entity.type ~= "splitter" then
		return 1
	end
	--[[
		      57
		      ^^
		7<          >5
		5<          >7
		      vv
		      75
	]]
	if (entity.direction == defines.direction.north and position.x > entity.position.x) or
		(entity.direction == defines.direction.east and position.y > entity.position.y) or
		(entity.direction == defines.direction.south and position.x < entity.position.x) or
		(entity.direction == defines.direction.west and position.y < entity.position.y) then
		return 7
	end
	-- NW / SE
	return 5
end

--[[
	splitter
	1 > 5
	2 > 6
	3 > 7
	4 > 8
	"line" > "split_line"
	primary left/right
	secondary left/right
]]
local function transport_line_acceptable_item(entity, position)
	local tli = transport_line_index(entity, position)
	for i = tli, tli+1 do
		local tl = entity.get_transport_line(i)
		if #tl > 0 and tl[1].valid_for_read and is_acceptable_item(tl[1].name) then
			return name
		end
	end
end

local entity_inventories_cache = {}
local function entity_output_inventory(entity)
	local cache_entry = entity_inventories_cache[entity.type]
	if cache_entry then
		return cache_entry
	end
	for _, inventory_index in ipairs(output_inventories) do
		if entity.get_inventory(inventory_index) then
			entity_inventories_cache[entity.type] = inventory_index
			log("for type "..entity.type.." found inventory: "..inventory_index)
			return inventory_index
		end
	end
end

local function inventory_has_acceptable(inventory)
	local contents = inventory.get_contents()
	for name, _ in pairs(contents) do
		if is_acceptable_item(name) then
			return true
		end
	end
	return false
end

local function inventory_acceptable_item(entity)
	local inventory = entity.get_inventory(entity_output_inventory(entity))
	if not inventory_has_acceptable(inventory) then
		return nil
	end

	-- if something is acceptable, take the one in the first slot
	for i=1,#inventory do
		if inventory[i].valid_for_read then
			local name = inventory[i].name
			if is_acceptable_item(name) then
				return name
			end
		end
	end
	return nil
end

local function entity_acceptable_item(entity, position)
	if has_transport_line(entity) then
		return transport_line_acceptable_item(entity, position)
	end
	return inventory_acceptable_item(entity)
end

function filters.position_acceptable_item(surface, position)
	for _, entity in ipairs(surface.find_entities_filtered{position = position}) do
		local item = entity_acceptable_item(entity, position)
		if item ~= nil then
			return item
		end
	end
	return nil
end

return filters
