//!HOOK MAIN
//!BIND HOOKED
//!DESC Flip Horizontal (Mirror Video Viewport)

vec4 hook() {
    vec2 pos = vec2(clamp(1.0 - HOOKED_pos.x, 0.0, 1.0), HOOKED_pos.y);
    return HOOKED_tex(pos);
}
