-- Media Player Pro - glass_zoom_pan.lua
-- Implements:
--  - Cursor-centered zoom via Ctrl+MouseWheel and video dragging/panning via Ctrl+MBTN_LEFT
--  - Reset Zoom & Pan via Ctrl+0 / Ctrl+MBTN_MID
--  - Horizontal Video Flip (Mirror) via Ctrl+1 (GPU-accelerated GLSL shader)
--  - 90-Degree Video Rotation via Ctrl+2 (Cycles 0° -> 90° -> 180° -> 270°)

local mp = require 'mp'

local state = {
    dragging = false,
    drag_start_x = 0,
    drag_start_y = 0,
    drag_start_pan_x = 0,
    drag_start_pan_y = 0,
    flipped = false,
    flip_shader_path = nil,
}

local function get_viewport()
    local dims = mp.get_property_native("osd-dimensions")
    if not dims or not dims.w or dims.w <= 0 or not dims.h or dims.h <= 0 then
        return nil
    end
    return dims
end

-- Locate shader file across installation and relative directories
local function find_shader(filename)
    local utils = require 'mp.utils'
    local cwd = utils.getcwd() or mp.get_property("working-directory") or os.getenv("PWD") or "."

    -- Derive script directory from debug info
    local info = debug.getinfo(1, "S")
    local script_path = info and info.source and info.source:gsub("^@", "")
    local script_dir = script_path and script_path:match("(.*/)")

    local candidates = {
        script_dir and utils.join_path(script_dir, "../shaders/" .. filename),
        script_dir and utils.join_path(script_dir, "../../shaders/" .. filename),
        utils.join_path(cwd, "shaders/" .. filename),
        "/usr/share/media-player-pro/shaders/" .. filename,
        "/usr/local/share/media-player-pro/shaders/" .. filename,
        "/app/share/media-player-pro/shaders/" .. filename,
        "./shaders/" .. filename,
        "shaders/" .. filename,
        filename
    }

    for _, path in ipairs(candidates) do
        if path then
            local f = io.open(path, "r")
            if f then
                f:close()
                if not path:match("^/") then
                    path = utils.join_path(cwd, path)
                end
                return path
            end
        end
    end
    return filename
end

-- Apply or remove horizontal flip shader dynamically
local function apply_flip_shader()
    if not state.flip_shader_path then
        state.flip_shader_path = find_shader("flip_horizontal.glsl")
    end

    pcall(function()
        mp.commandv("change-list", "glsl-shaders", "remove", state.flip_shader_path)
    end)

    if state.flipped then
        pcall(function()
            mp.commandv("change-list", "glsl-shaders", "append", state.flip_shader_path)
        end)
    end

    mp.set_property_native("user-data/mpp-flip-horizontal", state.flipped)
end

-- Toggle Horizontal Flip (Ctrl+1)
local function toggle_flip_horizontal()
    state.flipped = not state.flipped
    apply_flip_shader()

    local msg = state.flipped and "✦ Flip Horizontal: ON" or "Flip Horizontal: OFF"
    mp.osd_message(msg, 1.5)
end

-- Rotate Video by 90 Degrees Clockwise (Ctrl+2)
local function rotate_video_90()
    local cur_rot = mp.get_property_number("video-rotate", 0)
    local new_rot = (cur_rot + 90) % 360
    mp.set_property_number("video-rotate", new_rot)

    local msg = (new_rot == 0) and "↻ Video Rotation: 0° (Normal)" or string.format("↻ Video Rotation: %d°", new_rot)
    mp.osd_message(msg, 1.5)
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

-- Key Bindings
-- Ctrl+WHEEL: Cursor-Targeted Zoom
mp.add_forced_key_binding("ctrl+WHEEL_UP", "glass_zoom_in", function() zoom_at_cursor(0.15) end)
mp.add_forced_key_binding("ctrl+WHEEL_DOWN", "glass_zoom_out", function() zoom_at_cursor(-0.15) end)

-- Ctrl+0: Reset Zoom & Pan
mp.add_forced_key_binding("ctrl+0", "glass_zoom_reset", reset_zoom_pan)
mp.add_forced_key_binding("ctrl+MBTN_MID", "glass_zoom_reset_mid", reset_zoom_pan)

-- Ctrl+1: Flip Video Horizontally (Mirror)
mp.add_forced_key_binding("ctrl+1", "glass_flip_horizontal", toggle_flip_horizontal)
mp.add_forced_key_binding("ctrl+KP1", "glass_flip_horizontal_kp", toggle_flip_horizontal)

-- Ctrl+2: Rotate Video by 90 Degrees Clockwise
mp.add_forced_key_binding("ctrl+2", "glass_rotate_90", rotate_video_90)
mp.add_forced_key_binding("ctrl+KP2", "glass_rotate_90_kp", rotate_video_90)

-- Ctrl+MBTN_LEFT: Viewport Drag / Panning
mp.add_forced_key_binding("ctrl+MBTN_LEFT", "glass_pan_drag", handle_mouse_drag, {complex = true})
mp.observe_property("mouse-pos", "native", on_mouse_move)

-- Re-apply flip shader if active when a new file loads
mp.register_event("file-loaded", function()
    if state.flipped then
        apply_flip_shader()
    end
end)

-- Script Messages for UI and Inter-script Control
mp.register_script_message("toggle_flip_horizontal", toggle_flip_horizontal)
mp.register_script_message("rotate_video_90", rotate_video_90)

-- Global Exports for UI Integration
_G.glass_zoom_at_cursor = zoom_at_cursor
_G.glass_reset_zoom_pan = reset_zoom_pan
_G.mpp_toggle_flip_horizontal = toggle_flip_horizontal
_G.mpp_is_flipped = function() return state.flipped end
_G.mpp_rotate_90 = rotate_video_90
