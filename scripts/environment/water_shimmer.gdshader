shader_type canvas_item;
// Applies ONLY to the water tile layer, not to all map pixels.
void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    float shimmer = sin(TIME * 1.65 + UV.x * 85.0 + UV.y * 48.0) * 0.014;
    pixel.rgb += vec3(shimmer * 0.2, shimmer * 0.6, shimmer);
    COLOR = pixel;
}
