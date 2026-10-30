shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D moss_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D snow_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.045;
uniform float triplanar_sharpness = 4.0;

varying vec3 world_position;
varying vec3 world_normal;

vec3 triplanar_sample(sampler2D tex, vec3 position, vec3 normal) {
    vec3 blend_weights = pow(abs(normal), vec3(triplanar_sharpness));
    blend_weights /= max(blend_weights.x + blend_weights.y + blend_weights.z, 0.0001);
    vec3 x_sample = texture(tex, position.zy * texture_scale).rgb;
    vec3 y_sample = texture(tex, position.xz * texture_scale).rgb;
    vec3 z_sample = texture(tex, position.xy * texture_scale).rgb;
    return x_sample * blend_weights.x + y_sample * blend_weights.y + z_sample * blend_weights.z;
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec3 n = normalize(world_normal);
    float slope = 1.0 - abs(n.y);
    float rock_mask = smoothstep(0.30, 0.78, slope);
    float snow_mask = smoothstep(650.0, 880.0, world_position.y);
    float soil_mask = 1.0 - smoothstep(0.0, 0.32, slope);

    vec3 grass = triplanar_sample(grass_texture, world_position, n);
    vec3 moss = triplanar_sample(moss_texture, world_position, n);
    vec3 rock = triplanar_sample(rock_texture, world_position, n);
    vec3 dirt = triplanar_sample(dirt_texture, world_position, n);
    vec3 snow = triplanar_sample(snow_texture, world_position, n);

    vec3 ground = mix(grass, moss, clamp((COLOR.g - COLOR.r + 0.12) * 1.3, 0.0, 0.72));
    ground = mix(ground, dirt, soil_mask * 0.10);
    ground = mix(ground, rock, rock_mask);
    ground = mix(ground, snow, snow_mask);
    ALBEDO = ground * COLOR.rgb * 1.12;
    ROUGHNESS = 0.96;
}
