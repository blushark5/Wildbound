shader_type canvas_item;
render_mode unshaded;

uniform vec4 rim_color : source_color = vec4(0.56, 0.93, 0.77, 0.90);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.60;
uniform float glint : hint_range(0.0, 1.0) = 0.10;

// Enhance the existing original pixel sprite. Keep original silhouette and
// nearest-filter pixels; don't simulate a replacement painting.
void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    float edge = 0.0;
    vec2 step_uv = TEXTURE_PIXEL_SIZE;
    edge = max(edge, texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a);
    edge = max(edge, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a);
    edge = max(edge, texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a);
    edge = max(edge, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a);
    vec3 enhanced = pixel.rgb * (1.0 + glint);
    if (pixel.a < 0.04 && edge > 0.04) {
        COLOR = vec4(rim_color.rgb, min(0.72, edge * rim_strength));
    } else {
        COLOR = vec4(enhanced, pixel.a);
    }
}
