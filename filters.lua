local filters = {}

local patterns = {
    -- generic
    "-ore$",

    -- angelsrefining
    "^angels-ore",
    "^angels-.*-nugget",
    "^angels-.*-pebbles",
    "^angels-.*-slag",
    -- angelssmelting
    "^processed-",
}

-- bulk items that don't fit the above patterns
local items = {
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
    "slag",
}


return filters