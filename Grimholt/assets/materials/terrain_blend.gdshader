shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// World-space triplanar textures: terrain meshes intentionally do not need UVs.
uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D moss_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D snow_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.11;
uniform float triplanar_sharpness = 4.0;

varying vec3 world_position;
varying vec3 world_normal;

vec3 get_triplanar_weights(vec3 normal) {
    vec3 weights = pow(abs(normal), vec3(triplanar_sharpness));
    return weights / max(weights.x + weights.y + weights.z, 0.0001);
}

vec3 sample_grass(vec3 p, vec3 w) {
    return texture(grass_texture, p.zy * texture_scale).rgb * w.x
        + texture(grass_texture, p.xz * texture_scale).rgb * w.y
        + texture(grass_texture, p.xy * texture_scale).rgb * w.z;
}

vec3 sample_moss(vec3 p, vec3 w) {
    return texture(moss_texture, p.zy * texture_scale).rgb * w.x
        + texture(moss_texture, p.xz * texture_scale).rgb * w.y
        + texture(moss_texture, p.xy * texture_scale).rgb * w.z;
}

vec3 sample_rock(vec3 p, vec3 w) {
    return texture(rock_texture, p.zy * texture_scale).rgb * w.x
        + texture(rock_texture, p.xz * texture_scale).rgb * w.y
        + texture(rock_texture, p.xy * texture_scale).rgb * w.z;
}

vec3 sample_dirt(vec3 p, vec3 w) {
    return texture(dirt_texture, p.zy * texture_scale).rgb * w.x
        + texture(dirt_texture, p.xz * texture_scale).rgb * w.y
        + texture(dirt_texture, p.xy * texture_scale).rgb * w.z;
}

vec3 sample_snow(vec3 p, vec3 w) {
    return texture(snow_texture, p.zy * texture_scale).rgb * w.x
        + texture(snow_texture, p.xz * texture_scale).rgb * w.y
        + texture(snow_texture, p.xy * texture_scale).rgb * w.z;
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec3 n = normalize(world_normal);
    vec3 weights = get_triplanar_weights(n);
    float slope = 1.0 - abs(n.y);
    float rock_mask = smoothstep(0.30, 0.78, slope);
    float snow_mask = smoothstep(650.0, 880.0, world_position.y);
    float soil_mask = 1.0 - smoothstep(0.0, 0.32, slope);

    vec3 ground = mix(sample_grass(world_position, weights),
                      sample_moss(world_position, weights),
                      clamp((COLOR.g - COLOR.r + 0.12) * 1.3, 0.0, 0.72));
    ground = mix(ground, sample_dirt(world_position, weights), soil_mask * 0.10);
    ground = mix(ground, sample_rock(world_position, weights), rock_mask);
    ground = mix(ground, sample_snow(world_position, weights), snow_mask);

    // Keep the procedural biome palette subtle; never darken the source textures to near-black.
    vec3 biome_tint = mix(vec3(1.0), COLOR.rgb * 1.8, 0.28);
    ALBEDO = ground * biome_tint;
    ROUGHNESS = 0.96;
}
