-- Media Player Pro - glass_enhancements.lua
-- Implements 3 levels of genuine video enhancements using Deband, CAS (Contrast Adaptive Sharpening),
-- and high-fidelity chroma/luma scaling filters.

local mp = require 'mp'

local current_level = 0

local level_names = {
    [0] = "Off (Original)",
    [1] = "Level 1: Balanced (Deband + CAS 0.35)",
    [2] = "Level 2: High Clarity (Deep Deband + CAS 0.60)",
    [3] = "Level 3: Ultra Fidelity (Ultra Deband + CAS 0.85)"
}

local function apply_enhancement(level)
    current_level = level

    if level == 1 then
        -- Level 1: Balanced Enhancement
        -- Clean banding artifacts, slight adaptive sharpening
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", "2")
        mp.set_property("deband-threshold", "35")
        mp.set_property("deband-range", "16")
        mp.set_property("deband-grain", "5")
        mp.commandv("vf", "set", "@mpp_cas:cas=strength=0.35")
        pcall(function()
            mp.set_property("cscale", "ewa_lanczos")
            mp.set_property("dscale", "mitchell")
        end)
    elseif level == 2 then
        -- Level 2: High Clarity
        -- Deeper deband + prominent contrast-adaptive sharpening + high quality scaler
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", "3")
        mp.set_property("deband-threshold", "48")
        mp.set_property("deband-range", "20")
        mp.set_property("deband-grain", "8")
        mp.commandv("vf", "set", "@mpp_cas:cas=strength=0.60")
        pcall(function()
            mp.set_property("scale", "ewa_lanczossharp")
            mp.set_property("cscale", "ewa_lanczos")
            mp.set_property("dscale", "mitchell")
            mp.set_property("dither-depth", "auto")
        end)
    elseif level == 3 then
        -- Level 3: Ultra Fidelity
        -- Maximum quality deband + high-fidelity CAS + anti-ringing + precision dithering
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", "4")
        mp.set_property("deband-threshold", "64")
        mp.set_property("deband-range", "24")
        mp.set_property("deband-grain", "12")
        mp.commandv("vf", "set", "@mpp_cas:cas=strength=0.85")
        pcall(function()
            mp.set_property("scale", "ewa_lanczossharp")
            mp.set_property("scale-antiring", "0.7")
            mp.set_property("cscale", "ewa_lanczos")
            mp.set_property("cscale-antiring", "0.7")
            mp.set_property("dscale", "mitchell")
            mp.set_property("dither-depth", "auto")
            mp.set_property("correct-downscaling", "yes")
        end)
    else
        -- Level 0: Off
        current_level = 0
        mp.set_property("deband", "no")
        mp.commandv("vf", "set", "")
    end

    mp.set_property_native("user-data/mpp-enhancement-level", current_level)
    mp.osd_message(string.format("✦ Video Enhancement: %s", level_names[current_level]), 2.0)
end

local function cycle_enhancement()
    local next_level = (current_level + 1) % 4
    apply_enhancement(next_level)
end

-- Key binding to toggle / cycle enhancement levels
mp.add_forced_key_binding("e", "glass_cycle_enhancement", cycle_enhancement)
mp.add_forced_key_binding("E", "glass_cycle_enhancement_shift", cycle_enhancement)

-- Export for OSC UI menu integration
_G.mpp_get_enhancement_level = function() return current_level end
_G.mpp_set_enhancement_level = apply_enhancement
_G.mpp_cycle_enhancement = cycle_enhancement
