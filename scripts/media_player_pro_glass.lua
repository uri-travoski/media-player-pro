-- Media Player Pro - media_player_pro_glass.lua
-- Complete Frosted Glass OSC Skin for Media Player Pro
-- Features:
--  - Floating frosted glass bottom dock
--  - Transparent seek bar with vibrant amber played line and glowing scrubber
--  - Elapsed & Remaining time indicators
--  - 7s Backward & 7s Forward buttons around Play/Pause
--  - Speed Play Dropup (0.25x, 0.5x, 1.0x, 1.25x, 1.5x, 2.0x, 2.5x, 3.0x)
--  - Volume Slider with glowing handle & Mute toggle
--  - Minimise & Maximise buttons
--  - Settings Popover Menu with 3 levels of genuine video enhancements
--  - 3-second non-touch autohide for controls and mouse cursor during playback

local mp = require 'mp'
local utils = require 'mp.utils'

local overlay = mp.create_osd_overlay("ass-events")

-- Color Constants (ASS format: &HBBGGRR&)
-- Amber/Orange accent: #F59E0B -> R:0xF5, G:0x9E, B:0x0B -> &H0B9EF5&
local C_ACCENT        = "&H0B9EF5&"
local C_ACCENT_GLOW   = "&H0B9EF5&"
local C_WHITE         = "&HFFFFFF&"
local C_TEXT_MUTED    = "&HA0A0A0&"
local C_GLASS_BG      = "&H140F0D&" -- Frosted glass dark background
local C_GLASS_BORDER  = "&H403830&" -- Subtle glass border
local C_TRACK_BG      = "&H504840&" -- Translucent unplayed track
local C_HOVER_BG      = "&H2C241E&"
local C_POPUP_BG      = "&H0F0B09&"

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
    settings_sub_menu = nil, -- nil or 'enhance'
    
    duration = 0,
    time_pos = 0,
    pause = false,
    volume = 100,
    mute = false,
    speed = 1.0,
    enhancement_level = 0,
    
    window_w = 1280,
    window_h = 720,
}

local speeds = { 0.25, 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }

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

-- Exact ASS Drawing Helpers
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

-- Layout Calculation
local function get_layout()
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

-- Main Render Function
local function render()
    if not state.visible then
        overlay.data = ""
        overlay:update()
        return
    end

    local dims = mp.get_property_native("osd-dimensions")
    if dims and dims.w and dims.w > 0 and dims.h and dims.h > 0 then
        state.window_w = dims.w
        state.window_h = dims.h
    end

    overlay.res_x = state.window_w
    overlay.res_y = state.window_h

    local L = get_layout()
    local ass = {}
    local function add(s) ass[#ass + 1] = s end

    -- Base styling
    add("{\\rDefault\\an7\\pos(0,0)}")

    -- 1. Ambient Frosted Glass Dock
    -- Outer blur shadow
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&HC0&\\blur20}{\\p1}%s{\\p0}",
        C_GLASS_BG, ass_rect(L.dock_x, L.dock_y, L.dock_w, L.dock_h, 16)))
    -- Frosted glass dock background with border
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H70&\\1c%s\\1a&H30&\\blur1}{\\p1}%s{\\p0}",
        C_GLASS_BORDER, C_GLASS_BG, ass_rect(L.dock_x, L.dock_y, L.dock_w, L.dock_h, 16)))

    -- 2. Transparent Seekbar Area
    local dur = state.duration > 0 and state.duration or 1
    local progress = math.max(0, math.min(1, state.time_pos / dur))
    local played_w = math.floor(L.seek_w * progress)

    -- Ambient backdrop behind seekbar
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&HA0&\\blur10}{\\p1}%s{\\p0}",
        C_GLASS_BG, ass_rect(L.seek_x - 12, L.seek_y - 22, L.seek_w + 24, 38, 10)))

    -- Elapsed Time (Left)
    local cur_time_str = format_time(state.time_pos)
    add(string.format("{\\an7\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s\\1a&H00&\\bord1\\3c&H000000&\\3a&H80&}%s",
        L.seek_x, L.seek_y - 18, C_WHITE, cur_time_str))

    -- Remaining Time (Right)
    local rem_time_str = "Remaining " .. format_time(dur - state.time_pos)
    add(string.format("{\\an9\\pos(%d,%d)\\fnDejaVu Sans\\fs14\\1c%s\\1a&H20&\\bord1\\3c&H000000&\\3a&H80&}%s",
        L.seek_x + L.seek_w, L.seek_y - 18, C_TEXT_MUTED, rem_time_str))

    -- Unplayed Track (Glass Line)
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H60&}{\\p1}%s{\\p0}",
        C_TRACK_BG, ass_rect(L.seek_x, L.seek_y + 4, L.seek_w, 4, 2)))

    -- Played Track (Vibrant Amber / Orange)
    if played_w > 0 then
        -- Glow
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H50&\\blur4}{\\p1}%s{\\p0}",
            C_ACCENT_GLOW, ass_rect(L.seek_x, L.seek_y + 4, played_w, 4, 2)))
        -- Crisp line
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(L.seek_x, L.seek_y + 4, played_w, 4, 2)))
    end

    -- Scrubber Thumb (Amber Glowing Dot)
    local thumb_x = L.seek_x + played_w
    local thumb_y = L.seek_y + 6
    -- Outer glow ring
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H50&\\blur6}{\\p1}%s{\\p0}",
        C_ACCENT_GLOW, ass_circle(thumb_x, thumb_y, 9)))
    -- Core dot
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H10&\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        C_WHITE, C_ACCENT, ass_circle(thumb_x, thumb_y, 6)))

    -- Seekbar Hover Timestamp Tooltip
    if inside(state.mouse_x, state.mouse_y, L.seek_x - 5, L.seek_y - 10, L.seek_w + 10, L.seek_h + 15) and not state.active_drag then
        local hover_ratio = math.max(0, math.min(1, (state.mouse_x - L.seek_x) / L.seek_w))
        local hover_time = hover_ratio * dur
        local hover_str = format_time(hover_time)
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H60&\\1c%s\\1a&H18&\\blur3}{\\p1}%s{\\p0}",
            C_ACCENT, C_POPUP_BG, ass_rect(state.mouse_x - 28, L.seek_y - 38, 56, 22, 6)))
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs12\\1c%s}%s",
            state.mouse_x, L.seek_y - 27, C_ACCENT, hover_str))
    end

    -- 3. Bottom Controls Dock
    local cy = L.dock_y + 38

    -- Button 1: 7s Backward Button (-7s)
    local btn_back_x = L.dock_x + 42
    local is_back_hover = inside(state.mouse_x, state.mouse_y, btn_back_x - 22, cy - 22, 44, 44)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H60&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        C_GLASS_BORDER, is_back_hover and C_HOVER_BG or C_GLASS_BG, is_back_hover and "&H20&" or "&H80&",
        ass_circle(btn_back_x, cy, 20)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s}%s",
        btn_back_x, cy - 1, is_back_hover and C_ACCENT or C_WHITE, "↺ 7s"))

    -- Button 2: Play / Pause Center Button
    local btn_play_x = L.dock_x + 104
    local is_play_hover = inside(state.mouse_x, state.mouse_y, btn_play_x - 26, cy - 26, 52, 52)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H30&\\1c%s\\1a%s\\blur2}{\\p1}%s{\\p0}",
        is_play_hover and C_ACCENT or C_WHITE, is_play_hover and C_HOVER_BG or C_GLASS_BG, is_play_hover and "&H10&" or "&H50&",
        ass_circle(btn_play_x, cy, 24)))
    if state.pause then
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs22\\1c%s}%s",
            btn_play_x + 2, cy - 1, C_WHITE, "▶"))
    else
        add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs20\\1c%s}%s",
            btn_play_x, cy - 1, C_WHITE, "❚❚"))
    end

    -- Button 3: 7s Forward Button (+7s)
    local btn_fwd_x = L.dock_x + 166
    local is_fwd_hover = inside(state.mouse_x, state.mouse_y, btn_fwd_x - 22, cy - 22, 44, 44)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H60&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        C_GLASS_BORDER, is_fwd_hover and C_HOVER_BG or C_GLASS_BG, is_fwd_hover and "&H20&" or "&H80&",
        ass_circle(btn_fwd_x, cy, 20)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s}%s",
        btn_fwd_x, cy - 1, is_fwd_hover and C_ACCENT or C_WHITE, "7s ↻"))

    -- Button 4: Speed Play Dropup Button
    local btn_spd_x = L.dock_x + 242
    local is_spd_hover = inside(state.mouse_x, state.mouse_y, btn_spd_x - 32, cy - 18, 64, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H60&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        state.speed_menu_open and C_ACCENT or C_GLASS_BORDER,
        is_spd_hover and C_HOVER_BG or C_GLASS_BG,
        (is_spd_hover or state.speed_menu_open) and "&H20&" or "&H70&",
        ass_rect(btn_spd_x - 30, cy - 16, 60, 32, 8)))
    local spd_text = string.format("%.2fx", state.speed):gsub("%.00", ""):gsub("(%..-)0+$", "%1")
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s}%s",
        btn_spd_x, cy - 1, (is_spd_hover or state.speed_menu_open) and C_ACCENT or C_WHITE, spd_text .. " ▴"))

    -- Button 5: Volume Slider Section
    local vol_x = L.dock_x + L.dock_w - 360
    local is_vol_icon_hover = inside(state.mouse_x, state.mouse_y, vol_x - 18, cy - 18, 36, 36)
    local vol_icon = state.mute and "🔇" or (state.volume > 50 and "🔊" or (state.volume > 0 and "🔉" or "🔈"))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs18\\1c%s}%s",
        vol_x, cy - 1, is_vol_icon_hover and C_ACCENT or C_WHITE, vol_icon))

    -- Volume Track & Handle
    local vol_track_x = vol_x + 24
    local vol_track_w = 90
    local vol_val = state.mute and 0 or math.max(0, math.min(130, state.volume))
    local vol_ratio = math.min(1.0, vol_val / 100.0)
    local vol_fill_w = math.floor(vol_track_w * vol_ratio)

    -- Background Track
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H70&}{\\p1}%s{\\p0}",
        C_TRACK_BG, ass_rect(vol_track_x, cy - 2, vol_track_w, 4, 2)))
    -- Active / Filled Track
    if vol_fill_w > 0 then
        add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
            C_ACCENT, ass_rect(vol_track_x, cy - 2, vol_fill_w, 4, 2)))
    end
    -- Volume Slider Handle
    local vol_thumb_x = vol_track_x + vol_fill_w
    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H50&\\blur4}{\\p1}%s{\\p0}",
        C_ACCENT_GLOW, ass_circle(vol_thumb_x, cy, 6)))
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H20&\\1c%s\\1a&H00&}{\\p1}%s{\\p0}",
        C_WHITE, C_ACCENT, ass_circle(vol_thumb_x, cy, 4)))

    -- Volume percentage text
    local vol_text = string.format("%d%%", state.mute and 0 or math.floor(state.volume + 0.5))
    add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\fs12\\1c%s\\1a&H20&}%s",
        vol_track_x + vol_track_w + 10, cy - 1, C_TEXT_MUTED, vol_text))

    -- Button 6: Window Controls (Minimise & Maximise)
    local btn_min_x = L.dock_x + L.dock_w - 120
    local is_min_hover = inside(state.mouse_x, state.mouse_y, btn_min_x - 18, cy - 18, 36, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H70&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        C_GLASS_BORDER, is_min_hover and C_HOVER_BG or C_GLASS_BG, is_min_hover and "&H20&" or "&H80&",
        ass_rect(btn_min_x - 16, cy - 16, 32, 32, 6)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs18\\1c%s}%s",
        btn_min_x, cy - 3, is_min_hover and C_ACCENT or C_WHITE, "—"))

    local btn_max_x = L.dock_x + L.dock_w - 74
    local is_max_hover = inside(state.mouse_x, state.mouse_y, btn_max_x - 18, cy - 18, 36, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H70&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        C_GLASS_BORDER, is_max_hover and C_HOVER_BG or C_GLASS_BG, is_max_hover and "&H20&" or "&H80&",
        ass_rect(btn_max_x - 16, cy - 16, 32, 32, 6)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs16\\1c%s}%s",
        btn_max_x, cy - 1, is_max_hover and C_ACCENT or C_WHITE, "🗖"))

    -- Button 7: Settings / Menu Button (Far Right)
    local btn_menu_x = L.dock_x + L.dock_w - 28
    local is_menu_hover = inside(state.mouse_x, state.mouse_y, btn_menu_x - 18, cy - 18, 36, 36)
    add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a%s\\blur1}{\\p1}%s{\\p0}",
        state.settings_menu_open and C_ACCENT or C_GLASS_BORDER,
        is_menu_hover and C_HOVER_BG or C_GLASS_BG,
        (is_menu_hover or state.settings_menu_open) and "&H10&" or "&H80&",
        ass_rect(btn_menu_x - 16, cy - 16, 32, 32, 6)))
    add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs18\\1c%s}%s",
        btn_menu_x, cy - 1, (is_menu_hover or state.settings_menu_open) and C_ACCENT or C_WHITE, "⚙"))

    -- 4. Speed Play Dropup Popover Menu
    if state.speed_menu_open then
        local spd_pop_w = 120
        local spd_pop_h = #speeds * 28 + 16
        local spd_pop_x = btn_spd_x - math.floor(spd_pop_w / 2)
        local spd_pop_y = L.dock_y - spd_pop_h - 12

        -- Popover Background
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a&H18&\\blur4}{\\p1}%s{\\p0}",
            C_GLASS_BORDER, C_POPUP_BG, ass_rect(spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h, 8)))

        for idx, spd in ipairs(speeds) do
            local item_y = spd_pop_y + 8 + (idx - 1) * 28
            local is_hover = inside(state.mouse_x, state.mouse_y, spd_pop_x, item_y, spd_pop_w, 28)
            local is_selected = math.abs(state.speed - spd) < 0.05
            
            if is_hover or is_selected then
                add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H40&}{\\p1}%s{\\p0}",
                    is_selected and C_ACCENT or C_HOVER_BG, ass_rect(spd_pop_x + 4, item_y + 1, spd_pop_w - 8, 26, 4)))
            end

            local label = string.format("%.2fx", spd):gsub("%.00", ""):gsub("(%..-)0+$", "%1")
            if spd == 1.0 then label = label .. " (Normal)" end
            add(string.format("{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\b%d\\fs13\\1c%s}%s",
                spd_pop_x + math.floor(spd_pop_w / 2), item_y + 14, is_selected and 1 or 0,
                is_selected and C_ACCENT or (is_hover and C_WHITE or C_TEXT_MUTED), label))
        end
    end

    -- 5. Settings Popover Menu (Matching Attached Reference Popover)
    if state.settings_menu_open then
        local pop_w = 270
        local pop_h = 240
        local pop_x = L.dock_x + L.dock_w - pop_w
        local pop_y = L.dock_y - pop_h - 12

        -- Popover Frosted Background with Rounded Corners & Glow
        add(string.format("{\\pos(0,0)\\bord1\\3c%s\\3a&H50&\\1c%s\\1a&H14&\\blur6}{\\p1}%s{\\p0}",
            C_ACCENT, C_POPUP_BG, ass_rect(pop_x, pop_y, pop_w, pop_h, 10)))

        -- Header
        add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs12\\1c%s\\1a&H40&}%s",
            pop_x + 16, pop_y + 18, C_TEXT_MUTED, "MEDIA PLAYER PRO SETTINGS"))

        if state.settings_sub_menu == "enhance" then
            -- Enhance Video Submenu
            add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs14\\1c%s}%s",
                pop_x + 16, pop_y + 42, C_ACCENT, "◀ Enhance Video"))

            local enh_options = {
                { id = 0, name = "Off (Original Video)" },
                { id = 1, name = "Level 1: Balanced (Deband+CAS)" },
                { id = 2, name = "Level 2: High Clarity (CAS 0.60)" },
                { id = 3, name = "Level 3: Ultra Fidelity (CAS 0.85)" },
            }

            for idx, opt in ipairs(enh_options) do
                local item_y = pop_y + 68 + (idx - 1) * 36
                local is_hover = inside(state.mouse_x, state.mouse_y, pop_x + 8, item_y, pop_w - 16, 32)
                local is_active = (state.enhancement_level == opt.id)

                if is_hover or is_active then
                    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H40&}{\\p1}%s{\\p0}",
                        is_active and C_ACCENT or C_HOVER_BG, ass_rect(pop_x + 8, item_y, pop_w - 16, 32, 6)))
                end

                local marker = is_active and "● " or "○ "
                add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b%d\\fs12\\1c%s}%s",
                    pop_x + 16, item_y + 16, is_active and 1 or 0,
                    is_active and C_ACCENT or (is_hover and C_WHITE or C_TEXT_MUTED), marker .. opt.name))
            end
        else
            -- Main Settings Menu Items
            local items = {
                { key = "enhance", label = "✦ Enhance Video ▸", sub = string.format("Level %d", state.enhancement_level) },
                { key = "audio", label = "🎵 Audio Track ▸", sub = "Cycle" },
                { key = "sub", label = "💬 Subtitles ▸", sub = "Toggle" },
                { key = "aspect", label = "📐 Aspect Ratio ▸", sub = "Cycle" },
                { key = "stats", label = "ℹ Video Statistics", sub = "Display" },
            }

            for idx, it in ipairs(items) do
                local item_y = pop_y + 42 + (idx - 1) * 38
                local is_hover = inside(state.mouse_x, state.mouse_y, pop_x + 8, item_y, pop_w - 16, 34)

                if is_hover then
                    add(string.format("{\\pos(0,0)\\bord0\\shad0\\1c%s\\1a&H40&}{\\p1}%s{\\p0}",
                        C_HOVER_BG, ass_rect(pop_x + 8, item_y, pop_w - 16, 34, 6)))
                end

                add(string.format("{\\an4\\pos(%d,%d)\\fnDejaVu Sans\\b1\\fs13\\1c%s}%s",
                    pop_x + 16, item_y + 17, is_hover and C_ACCENT or C_WHITE, it.label))
                add(string.format("{\\an6\\pos(%d,%d)\\fnDejaVu Sans\\fs12\\1c%s\\1a&H30&}%s",
                    pop_x + pop_w - 16, item_y + 17, C_TEXT_MUTED, it.sub))
            end
        end
    end

    overlay.data = table.concat(ass, "\n")
    overlay:update()
end

-- Mouse & Interaction Handling
local function check_autohide()
    if state.pause then return end -- Keep visible while paused
    if state.mouse_down or state.active_drag then return end
    
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
    if m and m.x and m.y then
        return m.x, m.y
    end
    return state.mouse_x, state.mouse_y
end

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
            local vol_track_x = L.dock_x + L.dock_w - 360 + 24
            local vol_track_w = 90
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

        -- Check Speed Popover clicks
        if state.speed_menu_open then
            local spd_pop_w = 120
            local spd_pop_h = #speeds * 28 + 16
            local spd_pop_x = (L.dock_x + 242) - math.floor(spd_pop_w / 2)
            local spd_pop_y = L.dock_y - spd_pop_h - 12

            if inside(x, y, spd_pop_x, spd_pop_y, spd_pop_w, spd_pop_h) then
                for idx, spd in ipairs(speeds) do
                    local item_y = spd_pop_y + 8 + (idx - 1) * 28
                    if inside(x, y, spd_pop_x, item_y, spd_pop_w, 28) then
                        mp.set_property_number("speed", spd)
                        state.speed_menu_open = false
                        render()
                        return
                    end
                end
            else
                state.speed_menu_open = false
                render()
            end
        end

        -- Check Settings Popover clicks
        if state.settings_menu_open then
            local pop_w = 270
            local pop_h = 240
            local pop_x = L.dock_x + L.dock_w - pop_w
            local pop_y = L.dock_y - pop_h - 12

            if inside(x, y, pop_x, pop_y, pop_w, pop_h) then
                if state.settings_sub_menu == "enhance" then
                    -- Click Back
                    if inside(x, y, pop_x, pop_y + 36, pop_w, 28) then
                        state.settings_sub_menu = nil
                        render()
                        return
                    end
                    -- Enhance levels
                    for lvl = 0, 3 do
                        local item_y = pop_y + 68 + lvl * 36
                        if inside(x, y, pop_x, item_y, pop_w, 32) then
                            if _G.mpp_set_enhancement_level then
                                _G.mpp_set_enhancement_level(lvl)
                            end
                            state.enhancement_level = lvl
                            state.settings_menu_open = false
                            state.settings_sub_menu = nil
                            render()
                            return
                        end
                    end
                else
                    -- Main Settings Items
                    local items = { "enhance", "audio", "sub", "aspect", "stats" }
                    for idx, key in ipairs(items) do
                        local item_y = pop_y + 42 + (idx - 1) * 38
                        if inside(x, y, pop_x, item_y, pop_w, 34) then
                            if key == "enhance" then
                                state.settings_sub_menu = "enhance"
                            elseif key == "audio" then
                                mp.commandv("cycle", "audio")
                            elseif key == "sub" then
                                mp.commandv("cycle", "sub")
                            elseif key == "aspect" then
                                mp.commandv("cycle-values", "video-aspect-override", "16:9", "4:3", "2.35:1", "-1")
                            elseif key == "stats" then
                                mp.commandv("script-binding", "stats/display-stats-toggle")
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

        -- Check 7s Backward Button
        local btn_back_x = L.dock_x + 42
        if inside(x, y, btn_back_x - 22, cy - 22, 44, 44) then
            mp.commandv("seek", -7, "relative")
            render()
            return
        end

        -- Check Play / Pause Center Button
        local btn_play_x = L.dock_x + 104
        if inside(x, y, btn_play_x - 26, cy - 26, 52, 52) then
            mp.commandv("cycle", "pause")
            render()
            return
        end

        -- Check 7s Forward Button
        local btn_fwd_x = L.dock_x + 166
        if inside(x, y, btn_fwd_x - 22, cy - 22, 44, 44) then
            mp.commandv("seek", 7, "relative")
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
        local vol_x = L.dock_x + L.dock_w - 360
        if inside(x, y, vol_x - 18, cy - 18, 36, 36) then
            mp.commandv("cycle", "mute")
            render()
            return
        end

        -- Check Volume Slider click/drag
        local vol_track_x = vol_x + 24
        local vol_track_w = 90
        if inside(x, y, vol_track_x - 6, cy - 14, vol_track_w + 12, 28) then
            state.active_drag = 'volume'
            local ratio = math.max(0, math.min(1.3, (x - vol_track_x) / vol_track_w))
            mp.set_property_number("volume", math.floor(ratio * 100))
            if state.mute then mp.set_property_bool("mute", false) end
            render()
            return
        end

        -- Check Minimise Button
        local btn_min_x = L.dock_x + L.dock_w - 120
        if inside(x, y, btn_min_x - 18, cy - 18, 36, 36) then
            mp.set_property_bool("window-minimized", true)
            render()
            return
        end

        -- Check Maximise Button
        local btn_max_x = L.dock_x + L.dock_w - 74
        if inside(x, y, btn_max_x - 18, cy - 18, 36, 36) then
            local is_max = mp.get_property_bool("window-maximized", false)
            local is_fs = mp.get_property_bool("fullscreen", false)
            if not is_max and not is_fs then
                mp.set_property_bool("window-maximized", true)
            else
                mp.commandv("cycle", "fullscreen")
            end
            render()
            return
        end

        -- Check Settings Button
        local btn_menu_x = L.dock_x + L.dock_w - 28
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

-- Property Observers
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

mp.observe_property("user-data/mpp-enhancement-level", "number", function(_, val)
    state.enhancement_level = val or 0
    render()
end)

mp.observe_property("mouse-pos", "native", on_mouse_move)

-- Key & Mouse Bindings
mp.add_forced_key_binding("MBTN_LEFT", "glass_mouse_click", on_mouse_button, {complex = true})
mp.add_forced_key_binding("WHEEL_UP", "glass_wheel_up", on_wheel_up)
mp.add_forced_key_binding("WHEEL_DOWN", "glass_wheel_down", on_wheel_down)

-- Periodic Autohide Check (every 0.25s)
mp.add_periodic_timer(0.25, check_autohide)

-- Initial Render
wake_up()
render()
