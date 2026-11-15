//!HOOK MAIN
//!BIND HOOKED
//!DESC TrueTheater Video Enhancement A/B Test (Left: Original, Right: Enhanced)

// Converts RGB to Rec.709 Luminance
float rgb2luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Converts RGB to HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Converts HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 hook() {
    vec2 pos = HOOKED_pos;
    vec2 pt = HOOKED_pt;
    vec3 orig_c = clamp(HOOKED_tex(pos).rgb, 0.0, 1.0);

    // 2px Split-Screen Divider line at 50% width
    float divider = 0.50;
    float half_line = pt.x * 1.0;
    if (abs(pos.x - divider) <= half_line) {
        // High visibility cyan/red line
        return vec4(1.0, 0.2, 0.25, 1.0);
    }

    // Left half: untouched original
    if (pos.x < divider) {
        return vec4(orig_c, 1.0);
    }

    // Right half: TrueTheater Enhanced
    vec3 c = orig_c;
    vec3 n = clamp(HOOKED_tex(pos + vec2(0.0, -pt.y)).rgb, 0.0, 1.0);
    vec3 s = clamp(HOOKED_tex(pos + vec2(0.0,  pt.y)).rgb, 0.0, 1.0);
    vec3 w = clamp(HOOKED_tex(pos + vec2(-pt.x, 0.0)).rgb, 0.0, 1.0);
    vec3 e = clamp(HOOKED_tex(pos + vec2( pt.x, 0.0)).rgb, 0.0, 1.0);

    // --- PASS 1: Contrast Adaptive Sharpening (CAS) ---
    vec3 min_rgb = min(c, min(min(n, s), min(w, e)));
    vec3 max_rgb = max(c, max(max(n, s), max(w, e)));

    vec3 amp_rgb = clamp(min(min_rgb, 2.0 - max_rgb) / max(max_rgb, vec3(1e-4)), 0.0, 1.0);
    amp_rgb = inversesqrt(max(amp_rgb, vec3(1e-4)));

    float sharpness = 0.55;
    float peak = -3.0 * sharpness + 8.0;
    vec3 w_rgb = -1.0 / (amp_rgb * peak);
    vec3 rcp_weight = 1.0 / (4.0 * w_rgb + 1.0);

    vec3 sharpened = clamp(((n + s + w + e) * w_rgb + c) * rcp_weight, 0.0, 1.0);

    // --- PASS 2: Adaptive Local Tone Mapping (TrueTheater Lighting) ---
    float lum = clamp(rgb2luma(sharpened), 0.0, 1.0);
    float shadow_lift = 0.06 * pow(clamp(1.0 - lum, 0.0, 1.0), 2.0) * lum;
    float s_curve = 0.10 * (lum - 0.5) * (1.0 - abs(2.0 * lum - 1.0));
    float new_lum = clamp(lum + shadow_lift + s_curve, 0.0, 1.0);
    vec3 lit_rgb = clamp(sharpened * (new_lum / max(lum, 1e-4)), 0.0, 1.0);

    // --- PASS 3: Skin-Tone Protected Vibrance (TrueTheater Color) ---
    vec3 hsv = rgb2hsv(lit_rgb);
    float skin_center_hue = 0.070;
    float hue_dist = min(abs(hsv.x - skin_center_hue), 1.0 - abs(hsv.x - skin_center_hue));
    
    float skin_hue_weight = 1.0 - smoothstep(0.015, 0.080, hue_dist);
    float skin_sat_weight = smoothstep(0.12, 0.22, hsv.y) * (1.0 - smoothstep(0.68, 0.85, hsv.y));
    float skin_val_weight = smoothstep(0.15, 0.30, hsv.z);
    float is_skin = clamp(skin_hue_weight * skin_sat_weight * skin_val_weight, 0.0, 1.0);

    float non_skin_factor = mix(1.0, 0.05, is_skin);
    float vibrance_strength = 0.45;
    float sat_boost = (1.0 - hsv.y) * vibrance_strength * non_skin_factor;
    hsv.y = clamp(hsv.y + hsv.y * sat_boost, 0.0, 1.0);

    vec3 final_rgb = hsv2rgb(hsv);
    return vec4(clamp(final_rgb, 0.0, 1.0), 1.0);
}
