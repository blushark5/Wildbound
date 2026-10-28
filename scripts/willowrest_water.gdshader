shader_type canvas_item;
// Subtle animated water shimmer. Confined to the river and blue water pixels.
void fragment() {
    vec4 src = texture(TEXTURE, UV);
    if (UV.x < 0.38 && UV.y > 0.36 && src.b > src.r * 1.28 && src.g > src.r * 1.15) {
        float ripple = sin(TIME * 2.3 + UV.x * 170.0 + UV.y * 85.0);
        float drift = sin(TIME * 1.3 - UV.x * 90.0 + UV.y * 112.0);
        float d = (ripple + drift) * 0.018;
        src.rgb += vec3(d * 0.20, d * 0.75, d * 0.95);
    }
    COLOR = src;
}
