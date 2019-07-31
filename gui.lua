local circuit = require "circuit"
local event = require "lualib.event"
local ontick = require "lualib.ontick"
local util = require "lualib.util"

local entity_camera = require "lualib.entity-camera"
local titlebar = require "lualib.titlebar"

-- how often to poll ControlBehavior settings when a miniloader-inserter GUI is open
local POLL_INTERVAL = 15

local monitored_entities = {}

local function should_monitor_entity(entity)
  return util.is_miniloader(entity) or util.is_miniloader_inserter(entity)
end

local function monitor_open_guis(_)
  if not next(monitored_entities) then
    ontick.unregister(monitor_open_guis)
  end
  for k, entity in pairs(monitored_entities) do
    if entity.valid then
      circuit.sync_filters(entity)
      circuit.sync_behavior(entity)
    else
      monitored_entities[k] = nil
    end
  end
end

local function on_gui_opened(ev)
  local entity = ev.entity
  if entity and should_monitor_entity(entity) then
    if string.find(entity.name, 'advanced%-filter') then
      create_advanced_gui(entity, ev.player_index)
    else
      monitored_entities[entity.unit_number] = entity
      ontick.register(monitor_open_guis, POLL_INTERVAL)
    end
  end
end

local function on_gui_closed(ev)
  local entity = ev.entity
  if entity and should_monitor_entity(entity) then
    circuit.sync_behavior(entity)
    circuit.sync_filters(entity)
    monitored_entities[entity.unit_number] = nil
  end
end

function create_advanced_gui(entity, player_index)
  local player = game.players[player_index]
  local screen = player.gui.screen

  if not screen.advanced_ml_window then
    local window = screen.add{type='frame', name='advanced_ml_window', style='dialog_frame', direction='vertical'}
    titlebar.create(window, 'advanced_ml_titlebar', {
      label = entity.localised_name,
      draggable = true,
      buttons = {
        {
          name = 'close',
          sprite = 'utility/close_white',
          hovered_sprite = 'utility/close_black',
          clicked_sprite = 'utility/close_black'
        }
      }
    })
    local content_flow = window.add{type='flow', name='advanced_ml_content_flow', direction='horizontal'}
    content_flow.style.horizontal_spacing = 10
    local camera = entity_camera.create(content_flow, 'advanced_ml_camera', 110, {player=player, entity=entity, camera_zoom=1})
    local page_frame = content_flow.add{type='frame', name='advamced_ml_page_frame', style='window_content_frame', direction='vertical'}
    page_frame.style.horizontally_stretchable = true
    page_frame.style.vertically_stretchable = true
    window.force_auto_center()
    player.opened = window
  end
end

event.register(defines.events.on_gui_opened, on_gui_opened)
event.register(defines.events.on_gui_closed, on_gui_closed)
