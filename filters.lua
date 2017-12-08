local filters = {
    allowed_categories = nil
}

local util = require("util")

local output_inventories = {
    defines.inventory.cargo_wagon,
    defines.inventory.chest,
    defines.inventory.assembling_machine_output,
    defines.inventory.furnace_result,
    defines.inventory.burnt_result,
    defines.inventory.item_main,
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

local function transport_line_acceptable_item(entity)
    for i = 1, 1000 do
        local tl = entity.get_transport_line(i)
        if tl == nil then
            return nil
        end
        for name, _ in pairs(tl.get_contents()) do
            if is_acceptable_item(name) then
                return name
            end
        end
    end
end

local function inventory_acceptable_item(entity)
    for _, inventory_index in ipairs(output_inventories) do
        local inventory = entity.get_inventory(inventory_index)
        if inventory then
            for name, _ in pairs(inventory.get_contents()) do
                if is_acceptable_item(name) then
                    return name
                end
            end
        end
    end
    return nil
end

local function entity_acceptable_item(entity)
    if has_transport_line(entity) then
        return transport_line_acceptable_item(entity)
    end
    return inventory_items(entity)
end

local function position_acceptable_item(surface, position)
    for _, entity in ipairs(surface.find_entities_filtered {position = position}) do
        local item = entity_acceptable_item(entity)
        if item ~= nil then
            return item
        end
    end
    return nil
end

function filters.set_loader_filter(entity)
    local item = position_acceptable_item(entity.surface, util.pickup_position(entity))
    for _, inserter in ipairs(util.get_loader_inserters(entity)) do
        inserter.set_filter(1, item)
    end
end

return filters
