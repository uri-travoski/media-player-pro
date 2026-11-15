-- Media Player Pro - glass_enhancements.lua
-- Real-time, GPU-accelerated TrueTheater-style Video Enhancement Engine
-- Features:
--  - Upscaling & Anti-Ringing (ewa_lanczossharp + anti-ringing + deband)
--  - Custom GLSL Master Shader (CAS Sharpening, Adaptive Tone Mapping, Skin-Protected Vibrance)
--  - Split-Screen A/B Diagnostic Mode (50% Original / 50% Enhanced)
--  - Persistent state in user configuration (~/.config/media-player-pro/config.json)

local mp = require 'mp'
local utils = require 'mp.utils'

local CONFIG_DIR = os.getenv("HOME") .. "/.config/media-player-pro"
local CONFIG_FILE = CONFIG_DIR .. "/config.json"

local state = {
    enabled = true,        -- Enabled by default as required
    ab_test = false,       -- Split-screen comparison mode
    shader_path = nil,
    ab_shader_path = nil,
}

-- Locate shader file across installation and relative directories
local function find_shader(filename)
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

-- Load persistent user configuration
local function load_config()
    local f = io.open(CONFIG_FILE, "r")
    if not f then return end
    local content = f:read("*all")
    f:close()
    if not content or #content == 0 then return end
    local ok, data = pcall(utils.parse_json, content)
    if ok and data and type(data) == "table" then
        if data.video_enhancement ~= nil then
            state.enabled = (data.video_enhancement == true)
        end
    end
end

-- Save persistent user configuration
local function save_config()
    os.execute("mkdir -p '" .. CONFIG_DIR .. "' 2>/dev/null")
    local current_data = {}
    local f = io.open(CONFIG_FILE, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and #content > 0 then
            local ok, parsed = pcall(utils.parse_json, content)
            if ok and parsed and type(parsed) == "table" then
                current_data = parsed
            end
        end
    end

    current_data.video_enhancement = state.enabled
    local f_out = io.open(CONFIG_FILE, "w")
    if f_out then
        local ok, str = pcall(utils.format_json, current_data)
        if ok and str then
            f_out:write(str)
        end
        f_out:close()
    end
end

-- Apply video enhancement pipeline dynamically to GPU renderer
local function apply_pipeline()
    if not state.shader_path then
        state.shader_path = find_shader("truetheater_enhance.glsl")
    end
    if not state.ab_shader_path then
        state.ab_shader_path = find_shader("truetheater_ab_test.glsl")
    end

    -- First remove both shaders from active list
    pcall(function()
        mp.commandv("change-list", "glsl-shaders", "remove", state.shader_path)
        mp.commandv("change-list", "glsl-shaders", "remove", state.ab_shader_path)
    end)

    if state.enabled then
        local active_shader = state.ab_test and state.ab_shader_path or state.shader_path
        pcall(function()
            mp.commandv("change-list", "glsl-shaders", "append", active_shader)
        end)

        -- High quality upscaling, anti-ringing & deband filters
        pcall(function()
            mp.set_property("deband", "yes")
            mp.set_property("deband-iterations", "2")
            mp.set_property("deband-threshold", "35")
            mp.set_property("deband-range", "16")
            mp.set_property("deband-grain", "4")

            mp.set_property("scale", "ewa_lanczossharp")
            mp.set_property("cscale", "ewa_lanczossharp")
            mp.set_property("dscale", "mitchell")
            mp.set_property("scale-antiring", "0.7")
            mp.set_property("cscale-antiring", "0.7")
        end)
    else
        -- Revert to lightweight defaults
        pcall(function()
            mp.set_property("deband", "no")
            mp.set_property("scale", "bilinear")
            mp.set_property("cscale", "bilinear")
            mp.set_property("scale-antiring", "0.0")
            mp.set_property("cscale-antiring", "0.0")
        end)
    end

    mp.set_property_native("user-data/mpp-enhancement-enabled", state.enabled)
    mp.set_property_native("user-data/mpp-enhancement-ab", state.ab_test)
end

local function set_enhancement(enable, silent)
    state.enabled = enable
    if not enable then
        state.ab_test = false
    end
    save_config()
    apply_pipeline()

    if not silent then
        local msg = state.enabled and "✦ Video Enhancement (TrueTheater): ON" or "Video Enhancement: OFF"
        mp.osd_message(msg, 2.0)
    end
end

local function toggle_enhancement()
    set_enhancement(not state.enabled, false)
end

local function toggle_ab_test()
    if not state.enabled then
        state.enabled = true
        state.ab_test = true
    else
        state.ab_test = not state.ab_test
    end
    save_config()
    apply_pipeline()

    local msg = state.ab_test and "✦ TrueTheater A/B Split Screen: ON (Left: Original | Right: Enhanced)" or "TrueTheater A/B Split Screen: OFF"
    mp.osd_message(msg, 2.5)
end

-- Key Bindings
-- Ctrl+E: Toggle Video Enhancement ON/OFF
mp.add_forced_key_binding("ctrl+e", "glass_toggle_enhancement", toggle_enhancement)
mp.add_forced_key_binding("ctrl+E", "glass_toggle_enhancement_upper", toggle_enhancement)

-- Ctrl+Shift+E: Toggle A/B Comparison Mode
mp.add_forced_key_binding("ctrl+shift+e", "glass_toggle_ab_test", toggle_ab_test)
mp.add_forced_key_binding("ctrl+shift+E", "glass_toggle_ab_test_upper", toggle_ab_test)

-- Script Messages for UI and Inter-script Control
mp.register_script_message("toggle_enhancement", toggle_enhancement)
mp.register_script_message("mpp_toggle_enhancement", toggle_enhancement)
mp.register_script_message("glass_toggle_enhancement", toggle_enhancement)
mp.register_script_message("set_enhancement", function(val)
    set_enhancement(val == "yes" or val == "true" or val == "1" or val == "on", false)
end)
mp.register_script_message("toggle_ab_test", toggle_ab_test)

-- Re-apply pipeline when file loads
mp.register_event("file-loaded", function()
    apply_pipeline()
end)

-- Initialize on startup
load_config()
apply_pipeline()

-- Export functions for UI integration
_G.mpp_is_enhancement_enabled = function() return state.enabled end
_G.mpp_set_enhancement = set_enhancement
_G.mpp_toggle_enhancement = toggle_enhancement
_G.mpp_is_ab_test_active = function() return state.ab_test end
_G.mpp_toggle_ab_test = toggle_ab_test
