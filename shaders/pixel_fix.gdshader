shader_type canvas_item;

void fragment() {
    vec2 texture_resolution = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 uv = UV * texture_resolution;
    vec2 seam = floor(uv + 0.5);
    vec2 dudv = fwidth(uv);
    uv = seam + clamp((uv - seam) / dudv, -0.5, 0.5);
    
    // Беремо ідеальну картинку і множимо на колір ноди (який тепер має бути білим!)
    COLOR = texture(TEXTURE, uv / texture_resolution) * COLOR;
}