shader_type canvas_item;
render_mode unshaded;

uniform bool grain_enabled = true;
uniform float grain_intensity : hint_range(0.0, 0.20) = 0.024;
uniform float grain_fps : hint_range(1.0, 60.0) = 18.0;

uniform bool chromatic_aberration_enabled = true;
uniform float chromatic_aberration_px : hint_range(0.0, 3.0) = 0.85;

uniform bool soft_focus_enabled = true;
uniform float soft_focus_amount : hint_range(0.0, 1.0) = 0.14;
uniform float soft_focus_radius_px : hint_range(0.0, 3.0) = 0.70;

uniform bool halation_enabled = true;
uniform float halation_intensity : hint_range(0.0, 1.0) = 0.10;
uniform float halation_radius_px : hint_range(0.0, 4.0) = 1.25;

uniform bool flicker_enabled = true;
uniform float flicker_intensity : hint_range(0.0, 0.10) = 0.012;
uniform float flicker_speed : hint_range(0.1, 30.0) = 7.5;

uniform bool color_bleed_enabled = true;
uniform float color_bleed_intensity : hint_range(0.0, 0.50) = 0.065;
uniform float color_bleed_radius_px : hint_range(0.0, 3.0) = 0.90;

uniform bool dust_enabled = true;
uniform float dust_intensity : hint_range(0.0, 0.20) = 0.006;

uniform bool scratches_enabled = true;
uniform float scratches_intensity : hint_range(0.0, 0.20) = 0.003;

uniform bool exposure_variation_enabled = true;
uniform float exposure_variation_intensity : hint_range(0.0, 0.10) = 0.010;
uniform float exposure_variation_speed : hint_range(0.1, 10.0) = 1.7;

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_random_time(float speed, float seed) {
    float t = TIME * speed;
    float a = hash11(floor(t) + seed);
    float b = hash11(floor(t) + 1.0 + seed);
    float blend = smoothstep(0.0, 1.0, fract(t));
    return mix(a, b, blend);
}

vec4 sample_font(vec2 uv) {
    return texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
}

void fragment() {
    vec4 tint = COLOR;
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec4 center = sample_font(UV);

    vec4 focused = center;
    if (soft_focus_enabled && soft_focus_amount > 0.0) {
        vec2 step_uv = px * soft_focus_radius_px;
        vec4 blur = (
            center * 2.0 +
            sample_font(UV + vec2(step_uv.x, 0.0)) +
            sample_font(UV - vec2(step_uv.x, 0.0)) +
            sample_font(UV + vec2(0.0, step_uv.y)) +
            sample_font(UV - vec2(0.0, step_uv.y))
        ) / 6.0;
        focused = mix(center, blur, soft_focus_amount);
    }

    float red_alpha = focused.a;
    float green_alpha = focused.a;
    float blue_alpha = focused.a;
    if (chromatic_aberration_enabled && chromatic_aberration_px > 0.0) {
        vec2 chroma = vec2(px.x * chromatic_aberration_px, px.y * chromatic_aberration_px * 0.18);
        red_alpha = sample_font(UV + chroma).a;
        blue_alpha = sample_font(UV - chroma).a;
    }

    vec3 rgb = vec3(
        tint.r * red_alpha,
        tint.g * green_alpha,
        tint.b * blue_alpha
    );
    float alpha = max(max(red_alpha, green_alpha), blue_alpha) * tint.a;

    if (color_bleed_enabled && color_bleed_intensity > 0.0) {
        vec2 bleed_step = px * color_bleed_radius_px;
        float bleed_alpha = (
            sample_font(UV + vec2(bleed_step.x, 0.0)).a +
            sample_font(UV - vec2(bleed_step.x, 0.0)).a +
            sample_font(UV + vec2(0.0, bleed_step.y)).a +
            sample_font(UV - vec2(0.0, bleed_step.y)).a
        ) * 0.25;
        float expanded = max(alpha, bleed_alpha * tint.a);
        alpha = mix(alpha, expanded, color_bleed_intensity);
        rgb = mix(rgb, tint.rgb * expanded, color_bleed_intensity * 0.35);
    }

    if (halation_enabled && halation_intensity > 0.0) {
        vec2 halo_step = px * halation_radius_px;
        float halo_alpha = (
            sample_font(UV + vec2(halo_step.x, 0.0)).a +
            sample_font(UV - vec2(halo_step.x, 0.0)).a +
            sample_font(UV + vec2(0.0, halo_step.y)).a +
            sample_font(UV - vec2(0.0, halo_step.y)).a +
            sample_font(UV + halo_step).a +
            sample_font(UV - halo_step).a
        ) / 6.0;
        float halo = max(halo_alpha - center.a * 0.35, 0.0) * halation_intensity;
        rgb += vec3(1.0, 0.62, 0.42) * halo * tint.a;
        alpha = max(alpha, halo * 0.42 * tint.a);
    }

    float exposure = 1.0;
    if (flicker_enabled && flicker_intensity > 0.0) {
        float flicker = (smooth_random_time(flicker_speed, 19.0) - 0.5) * 2.0;
        exposure *= 1.0 + flicker * flicker_intensity;
    }
    if (exposure_variation_enabled && exposure_variation_intensity > 0.0) {
        float slow_exposure = (smooth_random_time(exposure_variation_speed, 71.0) - 0.5) * 2.0;
        exposure *= 1.0 + slow_exposure * exposure_variation_intensity;
    }
    rgb *= exposure;

    vec2 pixel_coord = floor(UV / max(px, vec2(0.000001)));
    if (grain_enabled && grain_intensity > 0.0) {
        float grain_frame = floor(TIME * grain_fps);
        float grain = hash21(pixel_coord + vec2(grain_frame * 17.0, grain_frame * 29.0)) - 0.5;
        rgb += vec3(grain * grain_intensity) * alpha;
    }

    if (dust_enabled && dust_intensity > 0.0) {
        float dust_frame = floor(TIME * 2.2);
        float dust_seed = hash21(floor(pixel_coord / 6.0) + vec2(dust_frame * 3.0, dust_frame * 5.0));
        float dust = smoothstep(0.993, 1.0, dust_seed) * dust_intensity;
        rgb *= 1.0 - dust;
    }

    if (scratches_enabled && scratches_intensity > 0.0) {
        float scratch_frame = floor(TIME * 0.75);
        float scratch_seed = hash21(vec2(floor(pixel_coord.x * 0.37), scratch_frame * 11.0));
        float scratch = smoothstep(0.9975, 1.0, scratch_seed) * scratches_intensity;
        rgb += vec3(scratch * 0.55) * alpha;
    }

    COLOR = vec4(max(rgb, vec3(0.0)), clamp(alpha, 0.0, 1.0));
}
