require "util"

local ingredients = {
	-- 52 I
	["bulk-miniloader"] = {
		{"underground-belt", 2},
		{"iron-plate", 16},
		{"engine-unit", 2},
	},
	-- 105 I, 27 C
	["miniloader"] = {
		{"underground-belt", 2},
		{"steel-plate", 8},
		{"fast-inserter", 6},
	},
	-- 174 I
	["fast-bulk-miniloader"] = {
		{"fast-underground-belt", 2},
		{"steel-plate", 8},
		{"engine-unit", 4},
	},
	-- 358 I, 128 C, 89 O
	["fast-miniloader"] = {
		{"fast-underground-belt", 2},
		{"steel-plate", 8},
		{"stack-inserter", 4},
	},
	-- 342 I, 12 C, 333 O
	["express-bulk-miniloader"] = {
		{"express-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	-- 628 I, 384 C, 174 O
	["express-miniloader"] = {
		{"express-underground-belt", 2},
		{"steel-plate", 8},
		{"stack-inserter", 6},
	},

	["green-bulk-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	["green-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"express-stack-inserter", 4},
	},
	["purple-bulk-miniloader"] = {
		{"green-underground-belt", 2},
		{"steel-plate", 8},
		{"electric-engine-unit", 4},
	},
	["purple-miniloader"] = {
		{"purple-underground-belt", 2},
		{"steel-plate", 8},
		{"express-stack-inserter", 6},
	},
}

local empty_sheet = {
	filename = "__core__/graphics/empty.png",
	priority = "very-low",
	width = 0,
	height = 0,
	frame_count = 1,
}

local function create_entity(prefix)
	local name = prefix .. "miniloader"

	local entity = util.table.deepcopy(data.raw["underground-belt"][prefix .. "underground-belt"])
	entity.name = name
	entity.minable.result = name
	entity.max_distance = 0
	entity.fast_replaceable_group = "miniloader"
	entity.selection_box = {{0, 0}, {0, 0}}
	entity.structure = {
		direction_in = {
			sheet = {
				filename = "__miniloader__/graphics/entity/" .. name .. ".png",
				priority = "extra-high",
				width = 128,
				height = 128,
			}
		},
		direction_out = {
			sheet = {
				filename = "__miniloader__/graphics/entity/" .. name .. ".png",
				priority = "extra-high",
				width = 128,
				height = 128,
				y = 128,
			}
		},
	}
	data:extend{entity}
end

local function create_item(prefix)
	local name = prefix .. "miniloader"

	local item = util.table.deepcopy(data.raw.item[prefix .. "underground-belt"])
	item.name = name
	item.icon = "__miniloader__/graphics/item/" .. name ..".png"
	item.order, _ = string.gsub(item.order, "^b%[underground%-belt%]", "e[miniloader]", 1)
	item.place_result = name

	data.raw["item"][name] = item
end

local function create_recipe(prefix)
	local name = prefix .. "miniloader"

	local recipe = {
		type = "recipe",
		name = name,
		enabled = false,
		energy_required = 1,
		ingredients = ingredients[name],
		result = name
	}

	data:extend{recipe}
end

local function create_technology(prefix, tech_prereqs)
	local name = prefix .. "miniloader"

	local main_prereq = data.raw["technology"][tech_prereqs[1]]
	local technology = {
		type = "technology",
		name = name,
		icon = "__miniloader__/graphics/technology/" .. name .. ".png",
		icon_size = 128,
		effects =
		{
			{
				type = "unlock-recipe",
				recipe = name
			}
		},
		prerequisites = tech_prereqs,
		unit = main_prereq.unit,
		order = main_prereq.order
	}

	data:extend{technology}
end

local function create_inserter(prefix)
	local base_entity = data.raw["underground-belt"][prefix .. "underground-belt"]
	local loader_name = prefix .. "miniloader"

	local loader_inserter = {
		type = "inserter",
		name = loader_name .. "-inserter",
		localised_name = {"entity-name." .. loader_name},
		-- this icon appears in the power usage UI
		icon = "__miniloader__/graphics/item/" .. loader_name .. ".png",
		icon_size = 32,
		flags = {"placeable-off-grid", "hide-alt-info"},
		max_health = base_entity.max_health,
		allow_custom_vectors = true,
		energy_per_movement = 2000,
		energy_per_rotation = 2000,
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
		},
		extension_speed = 1.0,
		rotation_speed = 1.0,
		collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
		selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
		pickup_position = {0, 0},
		insert_position = {0, 1.0},
		draw_held_item = false,
		platform_picture = { sheet = empty_sheet },
		hand_base_picture = empty_sheet,
		hand_open_picture = empty_sheet,
		hand_closed_picture = empty_sheet,
		circuit_wire_max_distance = default_circuit_wire_max_distance,
	}

	data:extend{loader_inserter}
end

local connector_definitions = circuit_connector_definitions.create(
	universal_connector_template,
	{
		{ variation = 24, main_offset = util.by_pixel(-5, -8.5), shadow_offset = util.by_pixel(10, -0.5), show_shadow = false },
		{ variation = 18, main_offset = util.by_pixel(5, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
		{ variation = 24, main_offset = util.by_pixel(-4.5, -8.5), shadow_offset = util.by_pixel(-2.5, 6), show_shadow = false },
		{ variation = 18, main_offset = util.by_pixel(5, -5), shadow_offset = util.by_pixel(5, -5), show_shadow = false },
	}
)

local function create_circuit_proxy(prefix)
	local name = prefix .. "miniloader-circuit-proxy"
	local loader_name = prefix .. "miniloader"
	local base_entity = data.raw["underground-belt"][prefix .. "underground-belt"]

	local proxy = {
		type = "pump",
		name = name,
		localised_name = {"entity-name."..loader_name},
		mineable = { mining_time = 1, result = loader_name },
		pumping_speed = 0,
		animations = empty_sheet,
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
			drain = "0kW",
		},
		energy_usage = (base_entity.speed / 0.03125 * 45) .. "kW",
		fluid_box = {
			pipe_connections = {},
		},
		circuit_wire_connection_points = connector_definitions.points,
		circuit_connector_sprites = connector_definitions.sprites,
		circuit_wire_max_distance = default_circuit_wire_max_distance,
	}

	for _,k in ipairs{"max_health", "collision_box", "selection_box", "resistances", "vehicle_impact_sound"} do
		proxy[k] = base_entity[k]
	end
	data:extend{proxy}
end

local function create_miniloader(prefix, tech_prereqs)
	create_entity(prefix)
	create_circuit_proxy(prefix)
	create_inserter(prefix)
	create_item(prefix)
	create_recipe(prefix)
	create_technology(prefix, tech_prereqs)
end

create_miniloader("", {"logistics-2", "engine"})
create_miniloader("fast-", {"miniloader", "stack-inserter"})
create_miniloader("express-", {"logistics-3", "fast-miniloader"})

-- Bob's support
if data.raw.technology["bob-logistics-4"] then
	create_miniloader("green-", {"bob-logistics-4", "express-miniloader"})
	if data.raw.technology["bob-logistics-5"] then
		create_miniloader("purple-", {"bob-logistics-5", "green-miniloader"})
	end
end
