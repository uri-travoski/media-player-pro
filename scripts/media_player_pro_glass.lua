-- Media Player Pro - media_player_pro_glass.lua
-- Complete Frosted Glass OSC Skin for Media Player Pro (v1.2)
-- Features:
--  - Ultra-transparent non-obstructive bottom controls (buttons/controls floating directly over video)
--  - Vibrant Red theme with red glow progress line & scrubber thumb
--  - Remembers last 20 unfinished videos & interactive Resume/Restart prompt
--  - Media backward (◄◄) & forward (►►) skip buttons (7s) without "7s" text
--  - Speed Play Dropup (0.25x to 3.0x) with red highlights
--  - Volume Slider with red glowing indicator & Mute toggle
--  - Minimise & Maximise buttons
--  - Settings Popover Menu with 3 levels of genuine video enhancements
--  - 3-second non-touch autohide for controls and mouse cursor during playback

local mp = require 'mp'
local utils = require 'mp.utils'

local overlay = mp.create_osd_overlay("ass-events")

-- Color Constants (ASS format: &HBBGGRR&)
-- Vibrant Red: RGB #FF2438 -> B:0x38, G:0x24, R:0xFF -> &H3824FF&
-- Glowing Red:  RGB #FF1028 -> B:0x28, G:0x10, R:0xFF -> &H2810FF&
local C_ACCENT        = "&H3824FF&"
local C_ACCENT_GLOW   = "&H2810FF&"
local C_WHITE         = "&HFFFFFF&"
local C_TEXT_MUTED    = "&HA0A0A0&"
local C_GLASS_BG      = "&H0D0A0B&" -- Translucent deep glass
local C_GLASS_BORDER  = "&H382226&" -- Subtle glass border with hint of red
local C_TRACK_BG      = "&H3A3A3A&" -- Translucent unplayed track
local C_HOVER_BG      = "&H281216&" -- Red-tinted glass hover
local C_POPUP_BG      = "&H0E0A0C&" -- Deep translucent popover background

local CURRENT_VERSION = "1.7"
local GITHUB_REPO     = "uri-travoski/media-player-pro"
local DEFAULT_RELEASE_URL = "https://github.com/uri-travoski/media-player-pro/releases/latest"

local HISTORY_DIR = os.getenv("HOME") .. "/.config/media-player-pro"
local HISTORY_FILE = HISTORY_DIR .. "/watch_history.json"

local aspect_ratios = {
    { id = "-1",    short = "Auto",     name = "Auto / Original" },
    { id = "16:9",  short = "16:9",     name = "16:9 (Widescreen)" },
    { id = "4:3",   short = "4:3",      name = "4:3 (Standard)" },
    { id = "21:9",  short = "21:9",     name = "21:9 (Ultrawide)" },
    { id = "16:10", short = "16:10",    name = "16:10 (Display)" },
    { id = "1:1",   short = "1:1",      name = "1:1 (Square)" },
}

local state = {
    visible = true,
    last_mouse_activity = mp.get_time(),
    autohide_delay = 3.0, -- 3 seconds of non-touch
    
    mouse_x = -1,
    mouse_y = -1,
    mouse_down = false,
    
    active_drag = nil, -- 'seek' or 'volume'
    
    speed_menu_open = false,
    settings_menu_open = false,
    settings_sub_menu = nil, -- nil or 'aspect'
    
    duration = 0,
    time_pos = 0,
    pause = false,
    volume = 100,
    mute = false,
    speed = 1.0,
    enhancement_enabled = true,
    ab_test_active = false,
    aspect_ratio = "-1",
    flipped = false,
    rotation = 0,
    fullscreen = false,
    
    update_available = false,
    latest_version = CURRENT_VERSION,
    release_url = DEFAULT_RELEASE_URL,
    checking_update = false,
    idle_active = false,
    
    -- Remember last 20 unfinished videos & prompt state
    resume_prompt = {
        show = false,
        path = nil,
        pos = 0,
        duration = 0,
        title = "",
        time_opened = 0
    },

    window_w = 1280,
    window_h = 720,
}

local function get_aspect_display()
    local cur = state.aspect_ratio or "-1"
    for _, opt in ipairs(aspect_ratios) do
        if opt.id == cur then
            return opt.short
        end
    end
    return cur == "-1" and "Auto" or cur
end

local speeds = { 0.25, 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }

local render -- Forward declaration

-- --------------------------------------------------------------------------
-- History Storage Engine (Last 20 Unfinished Videos)
-- --------------------------------------------------------------------------
local function ensure_config_dir()
    os.execute("mkdir -p '" .. HISTORY_DIR .. "' 2>/dev/null")
end

local function load_history()
    local f = io.open(HISTORY_FILE, "r")
    if not f then return {} end
    local content = f:read("*all")
    f:close()
    if not content or #content == 0 then return {} end
    local ok, data = pcall(utils.parse_json, content)
    if ok and data and data.history and type(data.history) == "table" then
        return data.history
    end
    return {}
end

local function save_history(history)
    ensure_config_dir()
    local f = io.open(HISTORY_FILE, "w")
    if not f then return end
    local ok, json_str = pcall(utils.format_json, { history = history })
    if ok and json_str then
        f:write(json_str)
    end
    f:close()
end

local function update_playback_position()
    local path = mp.get_property("path")
    if not path or path == "" then return end
    local pos = state.time_pos or 0
    local dur = state.duration or 0
    if dur < 30 or pos < 10 then return end

    local history = load_history()

    -- If finished (within 15s of end or >96% watched), remove from history
    if (dur - pos <= 15) or (pos / dur >= 0.96) then
        local new_hist = {}
        for _, item in ipairs(history) do
            if item.path ~= path then
                table.insert(new_hist, item)
            end
        end
        save_history(new_hist)
        return
    end

    -- Otherwise, it is UNFINISHED: update or insert at front
    local new_hist = {
        {
            path = path,
            filename = mp.get_property("filename") or "",
            title = mp.get_property("media-title") or "",
            pos = math.floor(pos),
            duration = math.floor(dur),
            updated = os.time()
        }
    }
    for _, item in ipairs(history) do
        if item.path ~= path and #new_hist < 20 then
            table.insert(new_hist, item)
        end
    end
    save_history(new_hist)
end

-- --------------------------------------------------------------------------
-- File Dialog & Updates
-- --------------------------------------------------------------------------
local function open_file_dialog()
    mp.osd_message("Opening file chooser...", 2.0)
    local py_code = "import tkinter.filedialog as fd, sys; path = fd.askopenfilename(title='Media Player Pro - Choose Media'); sys.stdout.write(path)"
    mp.command_native_async({
        name = "subprocess",
        args = { "python3", "-c", py_code },
        capture_stdout = true
    }, function(success, res)
        if success and res and res.status == 0 and res.stdout and #res.stdout > 0 then
            local p = res.stdout:gsub("^%s+", ""):gsub("%s+$", "")
            if #p > 0 then
                mp.commandv("loadfile", p)
            end
        else
            mp.command_native_async({
                name = "subprocess",
                args = { "zenity", "--file-selection", "--title=Media Player Pro - Choose Media" },
                capture_stdout = true
            }, function(s2, r2)
                if s2 and r2 and r2.status == 0 and r2.stdout and #r2.stdout > 0 then
                    local p2 = r2.stdout:gsub("^%s+", ""):gsub("%s+$", "")
                    if #p2 > 0 then mp.commandv("loadfile", p2) end
                end
            end)
        end
    end)
end

local function open_in_browser(url)
    url = url or state.release_url or DEFAULT_RELEASE_URL
    mp.osd_message("Opening latest release on GitHub to download...", 3.0)
    mp.command_native_async({
        name = "subprocess",
        args = { "xdg-open", url },
        detach = true
    }, function(success, res)
        if not success or (res and res.status ~= 0) then
            mp.command_native_async({
                name = "subprocess",
                args = { "gio", "open", url },
                detach = true
            }, function() end)
        end
    end)
end

local function parse_version(v)
    v = (v or ""):gsub("^v", "")
    local parts = {}
    for num in v:gmatch("(%d+)") do
        table.insert(parts, tonumber(num) or 0)
    end
    return parts
end

local function is_newer_version(latest, current)
    local l = parse_version(latest)
    local c = parse_version(current)
    local n = math.max(#l, #c)
    for i = 1, n do
        local l_val = l[i] or 0
        local c_val = c[i] or 0
        if l_val > c_val then return true end
        if l_val < c_val then return false end
    end
    return false
end

local function check_for_updates(manual)
    if state.checking_update then return end
    state.checking_update = true
    if manual then
        mp.osd_message("Checking for updates...", 2.0)
    end

    mp.command_native_async({
        name = "subprocess",
        args = {
            "curl", "-s", "-m", "5",
            "-H", "User-Agent: MediaPlayerPro",
            "https://api.github.com/repos/" .. GITHUB_REPO .. "/releases/latest"
        },
        capture_stdout = true
    }, function(success, res)
        state.checking_update = false
        if success and res and res.status == 0 and res.stdout and #res.stdout > 0 then
            local tag = res.stdout:match('"tag_name"%s*:%s*"([^"]+)"')
            local html_url = res.stdout:match('"html_url"%s*:%s*"([^"]+)"')
            if tag then
                state.latest_version = tag
                if html_url then state.release_url = html_url end
                if is_newer_version(tag, CURRENT_VERSION) then
                    state.update_available = true
                    mp.osd_message(string.format("▲ Update Available: Media Player Pro %s\nClick 'Update' in menu to download", tag), 4.0)
                else
                    state.update_available = false
                    if manual then
                        mp.osd_message(string.format("✓ Media Player Pro v%s is up to date", CURRENT_VERSION), 2.5)
                    end
                end
                if render then render() end
                return
            end
        end

        if manual then
            mp.osd_message("Opening releases page in browser...", 2.0)
            open_in_browser(DEFAULT_RELEASE_URL)
        end
    end)
end

local function format_time(seconds)
    if not seconds or seconds < 0 then return "00:00" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

-- --------------------------------------------------------------------------
-- Exact ASS Drawing Helpers
-- --------------------------------------------------------------------------
local function ass_rect(x, y, w, h, r)
    r = r or 0
    if r <= 0 then
        return string.format("m %d %d l %d %d l %d %d l %d %d", x, y, x + w, y, x + w, y + h, x, y + h)
    end
    r = math.min(r, math.floor(w / 2), math.floor(h / 2))
    return string.format(
        "m %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d",
        x + r, y,
        x + w - r, y,
        x + w, y, x + w, y, x + w, y + r,
        x + w, y + h - r,
        x + w, y + h, x + w, y + h, x + w - r, y + h,
        x + r, y + h,
        x, y + h, x, y + h, x, y + h - r,
        x, y + r,
        x, y, x, y, x + r, y
    )
end

local function ass_circle(cx, cy, r)
    local k = math.floor(r * 0.55228 + 0.5)
    return string.format(
        "m %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d",
        cx, cy - r,
        cx + k, cy - r, cx + r, cy - k, cx + r, cy,
        cx + r, cy + k, cx + k, cy + r, cx, cy + r,
        cx - k, cy + r, cx - r, cy + k, cx - r, cy,
        cx - r, cy - k, cx - k, cy - r, cx, cy - r
    )
end

-- Media Skip Backward Icon (Two left-pointing triangles)
local function ass_skip_backward(cx, cy, w, h)
    local s = math.floor(w / 2)
    local t1 = string.format("m %d %d l %d %d l %d %d", cx - s, cy, cx - 1, cy - h, cx - 1, cy + h)
    local t2 = string.format("m %d %d l %d %d l %d %d", cx, cy, cx + s, cy - h, cx + s, cy + h)
    return t1 .. " " .. t2
end

-- Media Skip Forward Icon (Two right-pointing triangles)
local function ass_skip_forward(cx, cy, w, h)
    local s = math.floor(w / 2)
    local t1 = string.format("m %d %d l %d %d l %d %d", cx - s, cy - h, cx, cy, cx - s, cy + h)
    local t2 = string.format("m %d %d l %d %d l %d %d", cx + 1, cy - h, cx + s + 1, cy, cx + 1, cy + h)
    return t1 .. " " .. t2
end

-- Layout Calculation
local function get_layout()
    if not state.override_dims then
        local ow = mp.get_property_number("osd-width", 0)
        local oh = mp.get_property_number("osd-height", 0)
        if not ow or ow <= 0 then
            ow = mp.get_property_number("dwidth", 0)
        end
        if not oh or oh <= 0 then
            oh = mp.get_property_number("dheight", 0)
        end
        if ow and ow > 0 then state.window_w = ow end
        if oh and oh > 0 then state.window_h = oh end
    end

    local w = state.window_w
    local h = state.window_h
    
    local dock_w = math.min(960, w - 48)
    local dock_h = 76
    local dock_x = math.floor((w - dock_w) / 2)
    local dock_y = h - dock_h - 24
    
    local seek_x = dock_x + 24
    local seek_w = dock_w - 48
    local seek_y = dock_y - 28
    local seek_h = 16
    
    return {
        dock_x = dock_x,
        dock_y = dock_y,
        dock_w = dock_w,
        dock_h = dock_h,
        seek_x = seek_x,
        seek_y = seek_y,
        seek_w = seek_w,
        seek_h = seek_h
    }
end

-- Point-in-rectangle check
local function inside(px, py, rx, ry, rw, rh)
    return px >= rx and px <= (rx + rw) and py >= ry and py <= (ry + rh)
end

-- --------------------------------------------------------------------------
-- Main Render Function
-- --------------------------------------------------------------------------
render = function()
    if not state.visible then
        overlay.data = ""
        overlay:update()
        return
    end

    overlay.res_x = state.window_w
    overlay.res_y = state.window_h

    local L = get_layout()
    local ass = {}
    local function add(s) ass[#ass + 1] = s end
    local tooltip = nil

    -- Base styling
    add("{\\rDefault\\an7\\pos(0,0)}")

    -- 0. Interactive Resume Playback Dialog (When Opening Unfinished Video)
    if state.resume_prompt.show then
        local rw = 480
        local rh = 124
        local rx = math.floor((state.window_w - rw) / 2)
        local ry = math.min(100, math.floor(state.window_h * 0.16))
        local rcx = rx + math.floor(rw / 2)

        -- Outer soft blur shadow & frosted glass card
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&HA0&\\blur18}{\\p1}%s{\\p0}",
            C_GLASS_BG, ass_rect(rx, ry, rw, rh, 14)))
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H40&\\1c%s\\1a&H18&\\blur2}{\\p1}%s{\\p0}",
            C_ACCENT, C_POPUP_BG, ass_rect(rx, ry, rw, rh, 14)))

        -- Title: Resume playback from MM:SS?
        local pos_str = format_time(state.resume_prompt.pos)
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs16\\1c%s\\bord1\\3c&H000000&\\3a&H80&}%s",
            rcx, ry + 24, C_WHITE, "Resume playback from " .. pos_str .. "?"))

        -- Subtitle: filename / title
        local title_display = state.resume_prompt.title
        if not title_display or title_display == "" then title_display = "Video" end
        if #title_display > 42 then title_display = title_display:sub(1, 40) .. "…" end
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs12\\1c%s\\1a&H30&}%s",
            rcx, ry + 46, C_TEXT_MUTED, title_display))

        -- Button A: [ ▶ Resume (MM:SS) ]
        local b_res_w = 196
        local b_res_h = 36
        local b_res_x = rcx - b_res_w - 10
        local b_res_y = ry + 68
        local is_res_hover = inside(state.mouse_x, state.mouse_y, b_res_x, b_res_y, b_res_w, b_res_h)

        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H30&\\1c%s\\1a%s\\blur2}{\\p1}%s{\\p0}",
            C_ACCENT, C_ACCENT, is_res_hover and "&H00&" or "&H30&", ass_rect(b_res_x, b_res_y, b_res_w, b_res_h, 8)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s}%s",
            b_res_x + math.floor(b_res_w / 2), b_res_y + 17, C_WHITE, "▶ Resume (" .. pos_str .. ")"))

        -- Button B: [ ↺ Start from Beginning ]
        local b_beg_w = 196
        local b_beg_h = 36
        local b_beg_x = rcx + 10
        local b_beg_y = ry + 68
        local is_beg_hover = inside(state.mouse_x, state.mouse_y, b_beg_x, b_beg_y, b_beg_w, b_beg_h)

        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H60&\\1c%s\\1a%s\\blur2}{\\p1}%s{\\p0}",
            is_beg_hover and C_ACCENT or C_GLASS_BORDER, is_beg_hover and C_HOVER_BG or C_GLASS_BG, is_beg_hover and "&H20&" or "&H70&",
            ass_rect(b_beg_x, b_beg_y, b_beg_w, b_beg_h, 8)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s}%s",
            b_beg_x + math.floor(b_beg_w / 2), b_beg_y + 17, is_beg_hover and C_ACCENT or C_WHITE, "↺ Start from Beginning"))

        -- Button C: [ ✕ ] Dismiss
        local b_cls_x = rx + rw - 22
        local b_cls_y = ry + 16
        local is_cls_hover = inside(state.mouse_x, state.mouse_y, b_cls_x - 12, b_cls_y - 12, 24, 24)
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s}%s",
            b_cls_x, b_cls_y, is_cls_hover and C_ACCENT or C_TEXT_MUTED, "✕"))
    end

    -- Center Splash Card in Idle Mode
    local is_idle = state.idle_active or (state.duration <= 0 and not mp.get_property("path"))
    if is_idle then
        local card_w = 480
        local card_h = 240
        local card_x = math.floor((state.window_w - card_w) / 2)
        local card_y = math.floor((state.window_h - card_h) / 2) - 20
        local cx = card_x + math.floor(card_w / 2)
        local cy = card_y + math.floor(card_h / 2)

        -- Ambient glow
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&HB0&\\blur24}{\\p1}%s{\\p0}",
            C_GLASS_BG, ass_rect(card_x, card_y, card_w, card_h, 16)))
        -- Frosted card with red rim
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a&H20&\\blur2}{\\p1}%s{\\p0}",
            C_ACCENT, C_GLASS_BG, ass_rect(card_x, card_y, card_w, card_h, 16)))

        -- Glowing red play circle
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H30&\\1c%s\\1a&H10&\\blur3}{\\p1}%s{\\p0}",
            C_ACCENT, C_HOVER_BG, ass_circle(cx, cy - 45, 30)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs26\\1c%s}%s",
            cx + 2, cy - 46, C_ACCENT, "▶"))

        -- Title
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs20\\1c%s}%s",
            cx, cy + 5, C_WHITE, "MEDIA PLAYER PRO"))
        -- Subtitle
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs13\\1c%s\\1a&H30&}%s",
            cx, cy + 30, C_TEXT_MUTED, "Drop video file here to play or open media"))

        -- Open File Button
        local btn_w = 210
        local btn_h = 36
        local btn_x = cx - math.floor(btn_w / 2)
        local btn_y = cy + 52
        local is_btn_hover = inside(state.mouse_x, state.mouse_y, btn_x, btn_y, btn_w, btn_h)
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H40&\\1c%s\\1a%s\\blur2}{\\p1}%s{\\p0}",
            C_ACCENT, is_btn_hover and C_ACCENT or C_HOVER_BG, is_btn_hover and "&H20&" or "&H60&",
            ass_rect(btn_x, btn_y, btn_w, btn_h, 8)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s}%s",
            cx, btn_y + 17, is_btn_hover and C_WHITE or C_ACCENT, "📂 Open Media File"))
    end

    -- 1. Bottom Bar is 100% Transparent
    -- Note: Dock pill background and ambient backdrops are completely omitted
    -- so video is totally visible with zero obstruction beneath controls.

    -- 2. Transparent Floating Seekbar
    local dur = state.duration > 0 and state.duration or 1
    local progress = math.max(0, math.min(1, state.time_pos / dur))
    local played_w = math.floor(L.seek_w * progress)

    -- Elapsed Time (Left) with drop shadow for legibility over any video
    local cur_time_str = format_time(state.time_pos)
    add(string.format("{\\an7\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s\\1a&H00&\\bord1.5\\3c&H000000&\\3a&H50&}%s",
        L.seek_x, L.seek_y - 18, C_WHITE, cur_time_str))

    -- Remaining Time (Right) with drop shadow - matches played time text color and styling
    local rem_time_str = "Remaining " .. format_time(dur - state.time_pos)
    add(string.format("{\\an9\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s\\1a&H00&\\bord1.5\\3c&H000000&\\3a&H50&}%s",
        L.seek_x + L.seek_w, L.seek_y - 18, C_WHITE, rem_time_str))

    -- Unplayed Track (Thin Translucent Glass Line)
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H90&}{\\p1}%s{\\p0}",
        C_TRACK_BG, ass_rect(L.seek_x, L.seek_y + 4, L.seek_w, 4, 2)))

    -- Played Track (Vibrant Red with Red Glow)
    if played_w > 0 then
        -- Red Glow
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H60&\\blur5}{\\p1}%s{\\p0}",
            C_ACCENT_GLOW, ass_rect(L.seek_x, L.seek_y + 4, played_w, 4, 2)))
        -- Crisp Red Line
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(L.seek_x, L.seek_y + 4, played_w, 4, 2)))
    end

    -- Scrubber Thumb (Red Glowing Dot)
    local thumb_x = L.seek_x + played_w
    local thumb_y = L.seek_y + 6
    -- Outer glow ring
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H40&\\blur6}{\\p1}%s{\\p0}",
        C_ACCENT_GLOW, ass_circle(thumb_x, thumb_y, 9)))
    -- Core dot
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H10&\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        C_WHITE, C_ACCENT, ass_circle(thumb_x, thumb_y, 6)))

    -- Seekbar Hover Timestamp Tooltip
    if inside(state.mouse_x, state.mouse_y, L.seek_x - 5, L.seek_y - 10, L.seek_w + 10, L.seek_h + 15) and not state.active_drag then
        local hover_ratio = math.max(0, math.min(1, (state.mouse_x - L.seek_x) / L.seek_w))
        local hover_time = hover_ratio * dur
        local hover_str = format_time(hover_time)
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a&H18&\\blur3}{\\p1}%s{\\p0}",
            C_ACCENT, C_POPUP_BG, ass_rect(state.mouse_x - 28, L.seek_y - 38, 56, 22, 6)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs12\\1c%s}%s",
            state.mouse_x, L.seek_y - 27, C_ACCENT, hover_str))
    end

    -- 3. Floating Bottom Controls (Only buttons and controls have background/color)
    local cy = L.dock_y + 38

    -- Button 1: Backward Skip Button (◄◄) - 5s skip without text
    local btn_back_x = L.dock_x + 42
    local is_back_hover = inside(state.mouse_x, state.mouse_y, btn_back_x - 22, cy - 22, 44, 44)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        is_back_hover and C_ACCENT or C_GLASS_BORDER, is_back_hover and C_HOVER_BG or C_GLASS_BG, is_back_hover and "&H20&" or "&H80&",
        ass_circle(btn_back_x, cy, 20)))
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        is_back_hover and C_ACCENT or C_WHITE, ass_skip_backward(btn_back_x, cy, 14, 7)))
    if is_back_hover then
        tooltip = { text = "Seek -5s (Left Arrow)", x = btn_back_x, y = cy - 34 }
    end

    -- Button 2: Play / Pause Center Button
    local btn_play_x = L.dock_x + 104
    local is_play_hover = inside(state.mouse_x, state.mouse_y, btn_play_x - 26, cy - 26, 52, 52)
    add(string.format("{\\pos(0,0)\\bord1.5\\3c%s\\3a&H20&\\1c%s\\1a%s\\blur2}{\\p1}%s{\\p0}",
        is_play_hover and C_WHITE or C_ACCENT, is_play_hover and C_HOVER_BG or C_GLASS_BG, is_play_hover and "&H10&" or "&H50&",
        ass_circle(btn_play_x, cy, 24)))
    if state.pause then
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs22\\1c%s}%s",
            btn_play_x + 2, cy - 1, C_WHITE, "▶"))
    else
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs20\\1c%s}%s",
            btn_play_x, cy - 1, C_WHITE, "❚❚"))
    end
    if is_play_hover then
        tooltip = { text = state.pause and "Play (Space)" or "Pause (Space)", x = btn_play_x, y = cy - 38 }
    end

    -- Button 3: Forward Skip Button (►►) - 5s skip without text
    local btn_fwd_x = L.dock_x + 166
    local is_fwd_hover = inside(state.mouse_x, state.mouse_y, btn_fwd_x - 22, cy - 22, 44, 44)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        is_fwd_hover and C_ACCENT or C_GLASS_BORDER, is_fwd_hover and C_HOVER_BG or C_GLASS_BG, is_fwd_hover and "&H20&" or "&H80&",
        ass_circle(btn_fwd_x, cy, 20)))
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        is_fwd_hover and C_ACCENT or C_WHITE, ass_skip_forward(btn_fwd_x, cy, 14, 7)))
    if is_fwd_hover then
        tooltip = { text = "Seek +5s (Right Arrow)", x = btn_fwd_x, y = cy - 34 }
    end

    -- Button 4: Speed Play Dropup Button
    local btn_spd_x = L.dock_x + 242
    local is_spd_hover = inside(state.mouse_x, state.mouse_y, btn_spd_x - 32, cy - 18, 64, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        state.speed_menu_open and C_ACCENT or C_GLASS_BORDER,
        is_spd_hover and C_HOVER_BG or C_GLASS_BG,
        (is_spd_hover or state.speed_menu_open) and "&H20&" or "&H70&",
        ass_rect(btn_spd_x - 30, cy - 16, 60, 32, 8)))
    local spd_text = string.format("%.2fx", state.speed):gsub("%.00", ""):gsub("(%..-)0+$", "%1")
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s}%s",
        btn_spd_x, cy - 1, (is_spd_hover or state.speed_menu_open) and C_ACCENT or C_WHITE, spd_text .. " ▴"))
    if is_spd_hover and not state.speed_menu_open then
        tooltip = { text = "Playback Speed", x = btn_spd_x, y = cy - 34 }
    end

    -- Button 5: Volume Slider Section (Streamlined layout)
    local vol_x = L.dock_x + L.dock_w - 200
    local is_vol_icon_hover = inside(state.mouse_x, state.mouse_y, vol_x - 18, cy - 18, 36, 36)
    local vol_icon = state.mute and "🔇" or (state.volume > 50 and "🔊" or (state.volume > 0 and "🔉" or "🔈"))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs18\\1c%s}%s",
        vol_x, cy - 1, is_vol_icon_hover and C_ACCENT or C_WHITE, vol_icon))
    if is_vol_icon_hover then
        tooltip = { text = state.mute and "Unmute (m)" or "Mute (m)", x = vol_x, y = cy - 34 }
    end

    -- Volume Track & Handle
    local vol_track_x = vol_x + 22
    local vol_track_w = 88
    local vol_val = state.mute and 0 or math.max(0, math.min(130, state.volume))
    local vol_ratio = math.min(1.0, vol_val / 100.0)
    local vol_fill_w = math.floor(vol_track_w * vol_ratio)

    -- Background Track
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H70&}{\\p1}%s{\\p0}",
        C_TRACK_BG, ass_rect(vol_track_x, cy - 2, vol_track_w, 4, 2)))
    -- Active / Filled Track (Red)
    if vol_fill_w > 0 then
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(vol_track_x, cy - 2, vol_fill_w, 4, 2)))
    end
    -- Volume Slider Handle (Red glowing)
    local vol_thumb_x = vol_track_x + vol_fill_w
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H40&\\blur4}{\\p1}%s{\\p0}",
        C_ACCENT_GLOW, ass_circle(vol_thumb_x, cy, 6)))
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H20&\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        C_WHITE, C_ACCENT, ass_circle(vol_thumb_x, cy, 4)))

    -- Volume percentage text
    local vol_text = string.format("%d%%", state.mute and 0 or math.floor(state.volume + 0.5))
    add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\fs12\\1c%s\\1a&H20&\\bord1\\3c&H000000&\\3a&H60&}%s",
        vol_track_x + vol_track_w + 8, cy - 1, C_TEXT_MUTED, vol_text))

    if inside(state.mouse_x, state.mouse_y, vol_track_x - 6, cy - 14, vol_track_w + 12, 28) and not is_vol_icon_hover then
        tooltip = { text = string.format("Volume: %s", vol_text), x = vol_track_x + math.floor(vol_track_w / 2), y = cy - 30 }
    end

    -- Button 6: Settings / Menu Button (Far Right)
    local btn_menu_x = L.dock_x + L.dock_w - 24
    local is_menu_hover = inside(state.mouse_x, state.mouse_y, btn_menu_x - 18, cy - 18, 36, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        state.settings_menu_open and C_ACCENT or C_GLASS_BORDER,
        is_menu_hover and C_HOVER_BG or C_GLASS_BG,
        (is_menu_hover or state.settings_menu_open) and "&H10&" or "&H80&",
        ass_rect(btn_menu_x - 16, cy - 16, 32, 32, 6)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs18\\1c%s}%s",
        btn_menu_x, cy - 1, (is_menu_hover or state.settings_menu_open) and C_ACCENT or C_WHITE, "⚙"))
    if is_menu_hover and not state.settings_menu_open then
        tooltip = { text = "Settings", x = btn_menu_x, y = cy - 34 }
    end

    -- 4. Speed Play Dropup Popover Menu
    if state.speed_menu_open then
        local spd_pop_w = 140
        local spd_pop_h = #speeds * 32 + 16
        local spd_pop_x = btn_spd_x - math.floor(spd_pop_w / 2)
        local spd_pop_y = L.dock_y - spd_pop_h - 12

        -- Popover Background: Solid black backplate + frosted border
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H080709&\\1a&H00&}{\\p1}%s{\\p0}",
            ass_rect(spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h, 8)))
        add(string.format("{\\pos(0,0)\\bord1.5\\3c%s\\3a&H30&\\1c&H141014&\\1a&H20&\\blur4}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h, 8)))

        for idx, spd in ipairs(speeds) do
            local item_y = spd_pop_y + 8 + (idx - 1) * 32
            local is_hover = inside(state.mouse_x, state.mouse_y, spd_pop_x, item_y, spd_pop_w, 32)
            local is_selected = math.abs(state.speed - spd) < 0.05
            
            if is_selected then
                add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
                    C_ACCENT, ass_rect(spd_pop_x + 6, item_y + 2, spd_pop_w - 12, 28, 5)))
            elseif is_hover then
                add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H40&\\1c&H301820&\\1a&H00&}{\\p1}%s{\\p0}",
                    C_ACCENT, ass_rect(spd_pop_x + 6, item_y + 2, spd_pop_w - 12, 28, 5)))
            end

            local label = string.format("%.2fx", spd):gsub("%.00", ""):gsub("(%..-)0+$", "%1")
            if spd == 1.0 then label = label .. " (Normal)" end
            add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b%d\\fs14\\1c%s\\1a&H00&}%s",
                spd_pop_x + math.floor(spd_pop_w / 2), item_y + 16, is_selected and 1 or 0,
                is_selected and C_WHITE or (is_hover and C_WHITE or "&HE8E8E8&"), label))
        end
    end

    -- 5. Settings Popover Menu (Content-focused, High-contrast, Legible)
    if state.settings_menu_open then
        local pop_w = 340
        local pop_h = (state.settings_sub_menu == "aspect") and 340 or 440
        local pop_x = math.max(16, math.min(state.window_w - pop_w - 16, L.dock_x + L.dock_w - pop_w))
        local pop_y = math.max(16, L.dock_y - pop_h - 12)

        -- 1. Solid Deep Obsidian Backing (100% opaque to guarantee zero video bleed-through)
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H080709&\\1a&H00&}{\\p1}%s{\\p0}",
            ass_rect(pop_x, pop_y, pop_w, pop_h, 12)))

        -- 2. Frosted Red Border & Subtle Glass Glow
        add(string.format("{\\pos(0,0)\\bord1.5\\3c%s\\3a&H30&\\1c&H141014&\\1a&H20&\\blur4}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(pop_x, pop_y, pop_w, pop_h, 12)))

        if state.settings_sub_menu == "aspect" then
            -- --- Aspect Ratio Selection Submenu ---
            local is_back_hover = inside(state.mouse_x, state.mouse_y, pop_x + 10, pop_y + 10, pop_w - 20, 36)
            add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
                is_back_hover and C_ACCENT or "&H302025&",
                is_back_hover and "&H301820&" or "&H1C1417&",
                ass_rect(pop_x + 10, pop_y + 10, pop_w - 20, 36, 7)))
            add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs15\\1c%s\\1a&H00&}%s",
                pop_x + 22, pop_y + 28, C_ACCENT, "◀ Back to Settings"))

            add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs12\\1c&HFFFFFF&\\1a&H00&}%s",
                pop_x + 18, pop_y + 60, "SELECT DISPLAY ASPECT RATIO"))

            for idx, opt in ipairs(aspect_ratios) do
                local item_y = pop_y + 76 + (idx - 1) * 40
                local item_w = pop_w - 20
                local item_h = 35
                local is_hover = inside(state.mouse_x, state.mouse_y, pop_x + 10, item_y, item_w, item_h)
                local is_active = (state.aspect_ratio == opt.id)

                if is_active then
                    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
                        C_ACCENT, ass_rect(pop_x + 10, item_y, item_w, item_h, 6)))
                    add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs15\\1c%s\\1a&H00&}%s",
                        pop_x + 24, item_y + 18, C_WHITE, "●  " .. opt.name))
                else
                    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a%s\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
                        is_hover and C_ACCENT or "&H30282C&", is_hover and "&H30&" or "&H90&",
                        is_hover and "&H301820&" or "&H181316&", ass_rect(pop_x + 10, item_y, item_w, item_h, 6)))
                    add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs15\\1c%s\\1a&H00&}%s",
                        pop_x + 24, item_y + 18, is_hover and C_WHITE or "&HE8E8E8&", "○  " .. opt.name))
                end
            end
        else
            -- --- Main Content-Focused Settings Menu ---
            add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs15\\1c%s\\1a&H00&}%s",
                pop_x + 18, pop_y + 22, C_WHITE, "✦ QUICK SETTINGS"))

            local is_enh_on = (state.enhancement_enabled ~= false)
            local is_flip_on = (state.flipped == true)
            local rot_val = state.rotation or 0

            local items = {
                { key = "enhance", label = "✦ Video Enhancement", badge = is_enh_on and "ON" or "OFF", is_active = is_enh_on },
                { key = "aspect",  label = "📐 Aspect Ratio",      badge = get_aspect_display() .. " ▸", is_active = (state.aspect_ratio ~= "-1") },
                { key = "flip",    label = "🪞 Flip Horizontal",   badge = is_flip_on and "ON" or "OFF", is_active = is_flip_on },
                { key = "rotate",  label = "↻ Rotate 90°",         badge = string.format("%d°", rot_val), is_active = (rot_val > 0) },
                { key = "audio",   label = "🎵 Audio Track",       badge = "Cycle ▸", is_active = false },
                { key = "sub",     label = "💬 Subtitles",         badge = "Toggle ▸", is_active = false },
                { key = "stats",   label = "ℹ Video Statistics",  badge = "Display", is_active = false },
                { key = "open",    label = "📂 Open Media File",   badge = "Open ▸", is_active = false },
                { key = "update",  label = state.update_available and ("▲ Update to " .. state.latest_version) or "⤓ Download Latest Update", badge = state.update_available and "Download ▸" or "GitHub ▸", is_active = state.update_available },
            }

            for idx, it in ipairs(items) do
                local item_y = pop_y + 44 + (idx - 1) * 42
                local item_w = pop_w - 20
                local item_h = 38
                local is_hover = inside(state.mouse_x, state.mouse_y, pop_x + 10, item_y, item_w, item_h)

                -- High-contrast Card Row Background (Solid, zero dark-on-dark bleed)
                if is_hover then
                    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H30&\\1c&H301820&\\1a&H00&}{\\p1}%s{\\p0}",
                        C_ACCENT, ass_rect(pop_x + 10, item_y, item_w, item_h, 7)))
                else
                    add(string.format("{\\pos(0,0)\\bord1\\3c&H2C2226&\\3a&H80&\\1c&H181316&\\1a&H00&}{\\p1}%s{\\p0}",
                        ass_rect(pop_x + 10, item_y, item_w, item_h, 7)))
                end

                -- Label: 100% Solid Pure White Text (Never dark-on-dark)
                local label_color = (it.key == "update" and state.update_available) and C_ACCENT or (is_hover and C_WHITE or "&HF4F4F4&")
                add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs15\\1c%s\\1a&H00&}%s",
                    pop_x + 22, item_y + 19, label_color, it.label))

                -- Right Status Badge Pill (High-contrast, easy to read)
                local badge_w = math.max(68, math.floor(#it.badge * 9.5) + 16)
                local badge_h = 24
                local badge_x = pop_x + pop_w - badge_w - 18
                local badge_y = item_y + 7

                if it.is_active then
                    -- Active Glowing Red Badge Pill
                    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
                        C_ACCENT, ass_rect(badge_x, badge_y, badge_w, badge_h, 5)))
                    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s\\1a&H00&}%s",
                        badge_x + math.floor(badge_w / 2), badge_y + math.floor(badge_h / 2), C_WHITE, it.badge))
                else
                    -- Inactive Crisp Charcoal & Light Silver Badge Pill
                    add(string.format("{\\pos(0,0)\\bord1\\3c&H443C40&\\3a&H00&\\1c&H262024&\\1a&H00&}{\\p1}%s{\\p0}",
                        ass_rect(badge_x, badge_y, badge_w, badge_h, 5)))
                    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c&HE8E8E8&\\1a&H00&}%s",
                        badge_x + math.floor(badge_w / 2), badge_y + math.floor(badge_h / 2), it.badge))
                end
            end
        end
    end

    -- Floating Tooltip Display (Above hovered buttons)
    if tooltip and not state.settings_menu_open and not state.speed_menu_open and not state.active_drag and not state.resume_prompt.show then
        local tw = math.floor(#tooltip.text * 7.2) + 20
        local th = 22
        local tx = tooltip.x
        local ty = tooltip.y
        if tx - math.floor(tw / 2) < 12 then tx = 12 + math.floor(tw / 2) end
        if tx + math.floor(tw / 2) > state.window_w - 12 then tx = state.window_w - 12 - math.floor(tw / 2) end

        -- Tooltip Pill Box
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H40&\\1c%s\\1a&H14&\\blur2}{\\p1}%s{\\p0}",
            C_ACCENT, C_POPUP_BG, ass_rect(tx - math.floor(tw / 2), ty - math.floor(th / 2), tw, th, 5)))
        -- Tooltip Text
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs11\\1c%s\\bord0}%s",
            tx, ty, C_WHITE, tooltip.text))
    end

    overlay.data = table.concat(ass, "\n")
    overlay:update()
end

-- --------------------------------------------------------------------------
-- Mouse & Interaction Handling
-- --------------------------------------------------------------------------
local function check_autohide()
    if state.pause then return end -- Keep visible while paused
    if state.mouse_down or state.active_drag then return end
    if state.resume_prompt.show then return end -- Keep prompt visible
    
    local now = mp.get_time()
    if (now - state.last_mouse_activity) >= state.autohide_delay then
        if state.visible then
            state.visible = false
            state.speed_menu_open = false
            state.settings_menu_open = false
            render()
        end
    end
end

local function wake_up()
    state.last_mouse_activity = mp.get_time()
    if not state.visible then
        state.visible = true
        render()
    end
end

local function get_mouse_pos()
    local m = mp.get_property_native("mouse-pos")
    if m and m.x and m.y and m.hover ~= false then
        return m.x, m.y
    end
    return state.mouse_x, state.mouse_y
end

mp.register_script_message("mpp_test_set_mouse", function(x, y)
    state.mouse_x = tonumber(x) or 0
    state.mouse_y = tonumber(y) or 0
end)

mp.register_script_message("mpp_test_set_dimensions", function(w, h)
    state.window_w = tonumber(w) or state.window_w
    state.window_h = tonumber(h) or state.window_h
    state.override_dims = true
end)

local function on_mouse_move(_, val)
    local x, y
    if val and val.x and val.y then
        x, y = val.x, val.y
    else
        x, y = get_mouse_pos()
    end
    if x ~= state.mouse_x or y ~= state.mouse_y then
        state.mouse_x = x
        state.mouse_y = y
        wake_up()

        local L = get_layout()

        -- Handle ongoing drags
        if state.active_drag == 'seek' then
            local ratio = math.max(0, math.min(1, (x - L.seek_x) / L.seek_w))
            local target_sec = ratio * state.duration
            mp.commandv("seek", target_sec, "absolute")
        elseif state.active_drag == 'volume' then
            local vol_track_x = L.dock_x + L.dock_w - 200 + 22
            local vol_track_w = 88
            local ratio = math.max(0, math.min(1.3, (x - vol_track_x) / vol_track_w))
            local new_vol = math.floor(ratio * 100)
            mp.set_property_number("volume", new_vol)
            if state.mute then mp.set_property_bool("mute", false) end
        end

        render()
    end
end

local function on_mouse_button(table)
    local event = table.event
    wake_up()

    state.mouse_x, state.mouse_y = get_mouse_pos()

    local L = get_layout()
    local x = state.mouse_x
    local y = state.mouse_y
    local cy = L.dock_y + 38

    if event == "down" or event == "press" then
        state.mouse_down = true

        -- Check Resume Prompt interactions
        if state.resume_prompt.show then
            local rw = 480
            local rh = 124
            local rx = math.floor((state.window_w - rw) / 2)
            local ry = math.min(100, math.floor(state.window_h * 0.16))
            local rcx = rx + math.floor(rw / 2)

            -- Check [ ▶ Resume ] button
            local b_res_w = 196
            local b_res_h = 36
            local b_res_x = rcx - b_res_w - 10
            local b_res_y = ry + 68
            if inside(x, y, b_res_x, b_res_y, b_res_w, b_res_h) then
                mp.commandv("seek", state.resume_prompt.pos, "absolute")
                mp.set_property_bool("pause", false)
                state.resume_prompt.show = false
                render()
                return
            end

            -- Check [ ↺ Start from Beginning ] button
            local b_beg_w = 196
            local b_beg_h = 36
            local b_beg_x = rcx + 10
            local b_beg_y = ry + 68
            if inside(x, y, b_beg_x, b_beg_y, b_beg_w, b_beg_h) then
                mp.commandv("seek", 0, "absolute")
                mp.set_property_bool("pause", false)
                state.resume_prompt.show = false
                render()
                return
            end

            -- Check [ ✕ ] Dismiss button
            local b_cls_x = rx + rw - 22
            local b_cls_y = ry + 16
            if inside(x, y, b_cls_x - 14, b_cls_y - 14, 28, 28) then
                state.resume_prompt.show = false
                render()
                return
            end

            -- If clicking within prompt card, do nothing
            if inside(x, y, rx, ry, rw, rh) then
                return
            end

            -- If clicking elsewhere, dismiss prompt and continue
            state.resume_prompt.show = false
        end

        -- Check Speed Popover clicks
        if state.speed_menu_open then
            local spd_pop_w = 140
            local spd_pop_h = #speeds * 32 + 16
            local spd_pop_x = (L.dock_x + 242) - math.floor(spd_pop_w / 2)
            local spd_pop_y = L.dock_y - spd_pop_h - 12

            if inside(x, y, spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h) then
                for idx, spd in ipairs(speeds) do
                    local item_y = spd_pop_y + 8 + (idx - 1) * 32
                    if inside(x, y, spd_pop_x, item_y, spd_pop_w, 32) then
                        mp.set_property_number("speed", spd)
                        state.speed_menu_open = false
                        render()
                        return
                    end
                end
            else
                state.speed_menu_open = false
                render()
                return
            end
        end

        -- Check Settings Popover clicks
        if state.settings_menu_open then
            local pop_w = 340
            local pop_h = (state.settings_sub_menu == "aspect") and 340 or 440
            local pop_x = math.max(16, math.min(state.window_w - pop_w - 16, L.dock_x + L.dock_w - pop_w))
            local pop_y = math.max(16, L.dock_y - pop_h - 12)

            if inside(x, y, pop_x, pop_y, pop_w, pop_h) then
                if state.settings_sub_menu == "aspect" then
                    -- Click Back to Settings
                    if inside(x, y, pop_x + 8, pop_y + 8, pop_w - 16, 40) then
                        state.settings_sub_menu = nil
                        render()
                        return
                    end
                    -- Aspect ratio choices
                    for idx, opt in ipairs(aspect_ratios) do
                        local item_y = pop_y + 76 + (idx - 1) * 40
                        if inside(x, y, pop_x + 8, item_y - 2, pop_w - 16, 39) then
                            mp.set_property("video-aspect-override", opt.id)
                            state.aspect_ratio = opt.id
                            mp.osd_message(string.format("Aspect Ratio: %s", opt.name), 2.0)
                            state.settings_sub_menu = nil
                            render()
                            return
                        end
                    end
                else
                    -- Main Content-Focused Settings Items
                    local items = { "enhance", "aspect", "flip", "rotate", "audio", "sub", "stats", "open", "update" }
                    for idx, key in ipairs(items) do
                        local item_y = pop_y + 44 + (idx - 1) * 42
                        if inside(x, y, pop_x + 8, item_y - 2, pop_w - 16, 42) then
                            if key == "enhance" then
                                mp.commandv("script-message", "toggle_enhancement")
                                state.enhancement_enabled = not state.enhancement_enabled
                            elseif key == "aspect" then
                                state.settings_sub_menu = "aspect"
                            elseif key == "flip" then
                                mp.commandv("script-message", "toggle_flip_horizontal")
                                state.flipped = not state.flipped
                            elseif key == "rotate" then
                                mp.commandv("script-message", "rotate_video_90")
                                state.rotation = ((state.rotation or 0) + 90) % 360
                            elseif key == "audio" then
                                mp.commandv("cycle", "audio")
                            elseif key == "sub" then
                                mp.commandv("cycle", "sub")
                            elseif key == "stats" then
                                mp.commandv("script-binding", "stats/display-stats-toggle")
                            elseif key == "open" then
                                open_file_dialog()
                                state.settings_menu_open = false
                            elseif key == "update" then
                                open_in_browser(state.release_url or DEFAULT_RELEASE_URL)
                                check_for_updates(false)
                                state.settings_menu_open = false
                            end
                            render()
                            return
                        end
                    end
                end
                return
            else
                state.settings_menu_open = false
                state.settings_sub_menu = nil
                render()
                return
            end
        end

        -- Check Idle Splash Open Media button
        local is_idle = state.idle_active or (state.duration <= 0 and not mp.get_property("path"))
        if is_idle then
            local card_w = 480
            local card_h = 240
            local card_x = math.floor((state.window_w - card_w) / 2)
            local card_y = math.floor((state.window_h - card_h) / 2) - 20
            local cx = card_x + math.floor(card_w / 2)
            local cy = card_y + math.floor(card_h / 2)
            if inside(x, y, cx - 110, cy + 48, 220, 44) or inside(x, y, cx - 40, cy - 80, 80, 80) then
                open_file_dialog()
                return
            end
        end

        -- Check Seek Bar click/drag
        if inside(x, y, L.seek_x - 10, L.seek_y - 12, L.seek_w + 20, L.seek_h + 20) then
            state.active_drag = 'seek'
            local ratio = math.max(0, math.min(1, (x - L.seek_x) / L.seek_w))
            mp.commandv("seek", ratio * state.duration, "absolute")
            render()
            return
        end

        -- Check Backward Skip Button (◄◄) - 5s skip
        local btn_back_x = L.dock_x + 42
        if inside(x, y, btn_back_x - 22, cy - 22, 44, 44) then
            mp.commandv("seek", -5, "relative")
            render()
            return
        end

        -- Check Play / Pause Center Button
        local btn_play_x = L.dock_x + 104
        if inside(x, y, btn_play_x - 26, cy - 26, 52, 52) then
            if state.idle_active or (state.duration <= 0 and not mp.get_property("path")) then
                open_file_dialog()
            else
                mp.commandv("cycle", "pause")
            end
            render()
            return
        end

        -- Check Forward Skip Button (►►) - 5s skip
        local btn_fwd_x = L.dock_x + 166
        if inside(x, y, btn_fwd_x - 22, cy - 22, 44, 44) then
            mp.commandv("seek", 5, "relative")
            render()
            return
        end

        -- Check Speed Dropup Button
        local btn_spd_x = L.dock_x + 242
        if inside(x, y, btn_spd_x - 32, cy - 18, 64, 36) then
            state.speed_menu_open = not state.speed_menu_open
            state.settings_menu_open = false
            render()
            return
        end

        -- Check Volume Mute Icon
        local vol_x = L.dock_x + L.dock_w - 200
        if inside(x, y, vol_x - 18, cy - 18, 36, 36) then
            mp.commandv("cycle", "mute")
            render()
            return
        end

        -- Check Volume Slider click/drag
        local vol_track_x = vol_x + 22
        local vol_track_w = 88
        if inside(x, y, vol_track_x - 6, cy - 14, vol_track_w + 12, 28) then
            state.active_drag = 'volume'
            local ratio = math.max(0, math.min(1.3, (x - vol_track_x) / vol_track_w))
            mp.set_property_number("volume", math.floor(ratio * 100))
            if state.mute then mp.set_property_bool("mute", false) end
            render()
            return
        end

        -- Check Settings Button
        local btn_menu_x = L.dock_x + L.dock_w - 24
        if inside(x, y, btn_menu_x - 18, cy - 18, 36, 36) then
            state.settings_menu_open = not state.settings_menu_open
            state.settings_sub_menu = nil
            state.speed_menu_open = false
            render()
            return
        end

    elseif event == "up" then
        state.mouse_down = false
        state.active_drag = nil
        render()
    end
end

-- Double Click to Fullscreen (Only in area above seekbar; disabled on seekbar and below)
local function on_mouse_dbl_click()
    wake_up()
    local x, y = get_mouse_pos()
    local L = get_layout()

    -- 1. Disallow double-click fullscreen on seekbar and anywhere below it
    if y >= (L.seek_y - 18) then
        return
    end

    -- 2. Disallow if inside Settings Popover Menu
    if state.settings_menu_open then
        local pop_w = 340
        local pop_h = (state.settings_sub_menu == "aspect") and 340 or 440
        local pop_x = math.max(16, math.min(state.window_w - pop_w - 16, L.dock_x + L.dock_w - pop_w))
        local pop_y = math.max(16, L.dock_y - pop_h - 12)
        if inside(x, y, pop_x, pop_y, pop_w, pop_h) then
            return
        end
    end

    -- 3. Disallow if inside Speed Popover Menu
    if state.speed_menu_open then
        local spd_pop_w = 140
        local spd_pop_h = #speeds * 32 + 16
        local spd_pop_x = (L.dock_x + 242) - math.floor(spd_pop_w / 2)
        local spd_pop_y = L.dock_y - spd_pop_h - 12
        if inside(x, y, spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h) then
            return
        end
    end

    -- 4. Disallow if inside Resume Prompt Card
    if state.resume_prompt.show then
        local rw = 480
        local rh = 124
        local rx = math.floor((state.window_w - rw) / 2)
        local ry = math.min(100, math.floor(state.window_h * 0.16))
        if inside(x, y, rx, ry, rw, rh) then
            return
        end
    end

    -- 5. Disallow if inside Idle Splash button
    local is_idle = state.idle_active or (state.duration <= 0 and not mp.get_property("path"))
    if is_idle then
        local card_w = 480
        local card_h = 240
        local card_x = math.floor((state.window_w - card_w) / 2)
        local card_y = math.floor((state.window_h - card_h) / 2) - 20
        local cx = card_x + math.floor(card_w / 2)
        local cy = card_y + math.floor(card_h / 2)
        if inside(x, y, cx - 110, cy + 48, 220, 44) or inside(x, y, cx - 40, cy - 80, 80, 80) then
            return
        end
    end

    -- In video area strictly above seekbar: toggle fullscreen!
    mp.commandv("cycle", "fullscreen")
end

-- Mouse Wheel Volume Controls
local function on_wheel_up()
    wake_up()
    local cur_vol = mp.get_property_number("volume", 100)
    mp.set_property_number("volume", math.min(130, cur_vol + 2))
    if state.mute then mp.set_property_bool("mute", false) end
    render()
end

local function on_wheel_down()
    wake_up()
    local cur_vol = mp.get_property_number("volume", 100)
    mp.set_property_number("volume", math.max(0, cur_vol - 2))
    render()
end

-- Resume prompt keyboard shortcuts
local function handle_resume_key()
    if state.resume_prompt.show then
        mp.commandv("seek", state.resume_prompt.pos, "absolute")
        mp.set_property_bool("pause", false)
        state.resume_prompt.show = false
        render()
    end
end

local function handle_restart_key()
    if state.resume_prompt.show then
        mp.commandv("seek", 0, "absolute")
        mp.set_property_bool("pause", false)
        state.resume_prompt.show = false
        render()
    end
end

local function handle_dismiss_key()
    if state.resume_prompt.show then
        state.resume_prompt.show = false
        render()
    end
end

-- --------------------------------------------------------------------------
-- Property Observers & Events
-- --------------------------------------------------------------------------
mp.observe_property("time-pos", "number", function(_, val)
    state.time_pos = val or 0
    render()
end)

mp.observe_property("duration", "number", function(_, val)
    state.duration = val or 0
    render()
end)

mp.observe_property("pause", "bool", function(_, val)
    state.pause = val or false
    wake_up()
    render()
end)

mp.observe_property("volume", "number", function(_, val)
    state.volume = val or 100
    render()
end)

mp.observe_property("mute", "bool", function(_, val)
    state.mute = val or false
    render()
end)

mp.observe_property("speed", "number", function(_, val)
    state.speed = val or 1.0
    render()
end)

mp.observe_property("user-data/mpp-enhancement-enabled", "bool", function(_, val)
    state.enhancement_enabled = (val ~= false)
    render()
end)

mp.observe_property("user-data/mpp-enhancement-ab", "bool", function(_, val)
    state.ab_test_active = val or false
    render()
end)

mp.observe_property("video-aspect-override", "string", function(_, val)
    state.aspect_ratio = val or "-1"
    render()
end)

mp.observe_property("user-data/mpp-flip-horizontal", "bool", function(_, val)
    state.flipped = (val == true)
    render()
end)

mp.observe_property("video-rotate", "number", function(_, val)
    state.rotation = val or 0
    render()
end)

mp.observe_property("idle-active", "bool", function(_, val)
    state.idle_active = val or false
    render()
end)

mp.observe_property("osd-width", "number", function(_, val)
    if val and val > 0 then
        state.window_w = val
    elseif not state.window_w or state.window_w <= 0 then
        state.window_w = 1280
    end
    render()
end)

mp.observe_property("osd-height", "number", function(_, val)
    if val and val > 0 then
        state.window_h = val
    elseif not state.window_h or state.window_h <= 0 then
        state.window_h = 720
    end
    render()
end)

mp.observe_property("fullscreen", "bool", function(_, val)
    state.fullscreen = (val == true)
    render()
end)

mp.observe_property("mouse-pos", "native", on_mouse_move)

-- Key & Mouse Bindings (MBTN_LEFT_DBL triggers fullscreen only above seekbar)
mp.add_forced_key_binding("MBTN_LEFT", "glass_mouse_click", on_mouse_button, {complex = true})
mp.add_forced_key_binding("MBTN_LEFT_DBL", "glass_mouse_dbl_click", on_mouse_dbl_click)
mp.add_forced_key_binding("WHEEL_UP", "glass_wheel_up", on_wheel_up)
mp.add_forced_key_binding("WHEEL_DOWN", "glass_wheel_down", on_wheel_down)
mp.add_forced_key_binding("ctrl+o", "glass_open_file", open_file_dialog)
mp.add_forced_key_binding("ctrl+O", "glass_open_file_shift", open_file_dialog)
mp.add_key_binding("ENTER", "glass_resume_enter", handle_resume_key)
mp.add_key_binding("HOME", "glass_resume_restart", handle_restart_key)
mp.add_key_binding("ESC", "glass_resume_esc", handle_dismiss_key)

-- File Loaded: Check watch history for unfinished position
mp.register_event("file-loaded", function()
    local path = mp.get_property("path")
    if not path or path == "" then return end
    local history = load_history()
    for _, item in ipairs(history) do
        if item.path == path and item.pos and item.pos >= 10 then
            local dur = mp.get_property_number("duration", item.duration or 0)
            if dur <= 0 or (dur - item.pos > 15 and item.pos / dur < 0.96) then
                state.resume_prompt = {
                    show = true,
                    path = path,
                    pos = item.pos,
                    duration = dur,
                    title = item.title or item.filename or mp.get_property("filename") or "Video",
                    time_opened = mp.get_time()
                }
                mp.set_property_bool("pause", true)
                wake_up()
                render()
                return
            end
        end
    end
    state.resume_prompt = { show = false }
end)

-- Shutdown & Periodic Position Recording
mp.register_event("shutdown", function()
    update_playback_position()
end)

mp.add_periodic_timer(5.0, update_playback_position)
mp.add_periodic_timer(0.25, check_autohide)

-- Initial Render & Auto Update Check
wake_up()
render()

mp.add_timeout(2.0, function()
    check_for_updates(false)
end)

