-- Media Player Pro - glass_zoom_pan.lua
-- Implements cursor-centered zoom via Ctrl+MouseWheel and video dragging/panning via Ctrl+MBTN_LEFT.

local mp = require 'mp'

local state = {
    dragging = false,
    drag_start_x = 0,
    drag_start_y = 0,
    drag_start_pan_x = 0,
    drag_start_pan_y = 0,
}

local function get_viewport()
    local dims = mp.get_property_native("osd-dimensions")
    if not dims or not dims.w or dims.w <= 0 or not dims.h or dims.h <= 0 then
        return nil
    end
    return dims
end

-- Zoom in/out centered at cursor location
local function zoom_at_cursor(zoom_delta)
    local dims = get_viewport()
    if not dims then return end

    local m = mp.get_property_native("mouse-pos")
    local mouse_x = m and m.x or -1
    local mouse_y = m and m.y or -1
    if mouse_x < 0 or mouse_y < 0 then
        local cur_zoom = mp.get_property_number("video-zoom", 0)
        mp.set_property_number("video-zoom", math.max(-2, math.min(5, cur_zoom + zoom_delta)))
        return
    end

    local cur_zoom = mp.get_property_number("video-zoom", 0)
    local new_zoom = math.max(-2, math.min(5, cur_zoom + zoom_delta))
    if new_zoom == cur_zoom then return end

    local cur_scale = 2 ^ cur_zoom
    local new_scale = 2 ^ new_zoom

    local cur_pan_x = mp.get_property_number("video-pan-x", 0)
    local cur_pan_y = mp.get_property_number("video-pan-y", 0)

    -- Normalized mouse coordinates relative to viewport center
    local nx = (mouse_x - (dims.w / 2)) / dims.w
    local ny = (mouse_y - (dims.h / 2)) / dims.h

    -- Update pan so the point under the cursor stays stationary
    local scale_ratio = new_scale / cur_scale
    local new_pan_x = nx - (nx - cur_pan_x) * scale_ratio
    local new_pan_y = ny - (ny - cur_pan_y) * scale_ratio

    if new_zoom <= 0 then
        local t = math.max(0, 1 + new_zoom)
        new_pan_x = new_pan_x * t
        new_pan_y = new_pan_y * t
    end

    mp.set_property_number("video-zoom", new_zoom)
    mp.set_property_number("video-pan-x", new_pan_x)
    mp.set_property_number("video-pan-y", new_pan_y)

    local percent = math.floor((2 ^ new_zoom) * 100 + 0.5)
    mp.osd_message(string.format("Zoom: %d%%", percent), 1.0)
end

-- Reset zoom and pan
local function reset_zoom_pan()
    mp.set_property_number("video-zoom", 0)
    mp.set_property_number("video-pan-x", 0)
    mp.set_property_number("video-pan-y", 0)
    mp.osd_message("Zoom: 100% (Reset)", 1.0)
end

-- Ctrl + Left Mouse Button Drag to pan
local function handle_mouse_drag(table)
    local event = table.event
    if event == "down" or event == "press" then
        local dims = get_viewport()
        if not dims then return end
        state.dragging = true
        local m = mp.get_property_native("mouse-pos")
        state.drag_start_x = m and m.x or 0
        state.drag_start_y = m and m.y or 0
        state.drag_start_pan_x = mp.get_property_number("video-pan-x", 0)
        state.drag_start_pan_y = mp.get_property_number("video-pan-y", 0)
    elseif event == "up" then
        state.dragging = false
    end
end

local function on_mouse_move(_, val)
    if not state.dragging then return end
    local dims = get_viewport()
    if not dims or dims.w <= 0 or dims.h <= 0 then return end

    local cur_x = val and val.x or state.drag_start_x
    local cur_y = val and val.y or state.drag_start_y

    local dx = cur_x - state.drag_start_x
    local dy = cur_y - state.drag_start_y

    local new_pan_x = state.drag_start_pan_x + (dx / dims.w)
    local new_pan_y = state.drag_start_pan_y + (dy / dims.h)

    mp.set_property_number("video-pan-x", new_pan_x)
    mp.set_property_number("video-pan-y", new_pan_y)
end

mp.add_forced_key_binding("ctrl+WHEEL_UP", "glass_zoom_in", function() zoom_at_cursor(0.15) end)
mp.add_forced_key_binding("ctrl+WHEEL_DOWN", "glass_zoom_out", function() zoom_at_cursor(-0.15) end)
mp.add_forced_key_binding("ctrl+0", "glass_zoom_reset", reset_zoom_pan)
mp.add_forced_key_binding("ctrl+MBTN_MID", "glass_zoom_reset_mid", reset_zoom_pan)

mp.add_forced_key_binding("ctrl+MBTN_LEFT", "glass_pan_drag", handle_mouse_drag, {complex = true})
mp.observe_property("mouse-pos", "native", on_mouse_move)

_G.glass_zoom_at_cursor = zoom_at_cursor
_G.glass_reset_zoom_pan = reset_zoom_pan
