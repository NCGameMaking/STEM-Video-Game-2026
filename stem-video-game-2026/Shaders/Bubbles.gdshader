shader_type spatial;
render_mode blend_mix, cull_back;
uniform sampler2D noise_texture;
uniform float smoothness = 0.2;
uniform float wobble_speed = 0.03;
uniform float wobble_amplitude = 0.2;
uniform float bubble_alpha = 0.5; // base transparency

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float height = texture(noise_texture, VERTEX.xz * smoothness + vec2(TIME * wobble_speed)).r;
    VERTEX += NORMAL * height * wobble_amplitude;
}

float fresnel_alpha(vec3 normal) {
    vec3 view_dir = vec3(0.0, 0.0, -1.0);
    float f = dot(normal, view_dir);
    f = clamp(abs(f), 0.0, 1.0);
    return pow(1.0 - f, 1.5); // center transparent, edges slightly less
}

void fragment() {
    vec3 normal_view = normalize((PROJECTION_MATRIX * vec4(NORMAL, 0.0)).xyz);
    float alpha = fresnel_alpha(normal_view);

    ALBEDO = vec3(1.0);      // pure white
    ALPHA = alpha * bubble_alpha; // transparency only
}