shader_type spatial;
render_mode unshaded; // Use unshaded to see flat colors without lighting interference

#include "res://src/planet/shaders/transvoxel.gdshaderinc"

// Transform for your Voxel block (defines planet coordinates)
uniform mat4 u_block_local_transform;

// Base moon color and crater tint
uniform vec3 u_color_moon : source_color = vec3(0.8, 0.8, 0.8);
uniform vec3 u_color_crater : source_color = vec3(0.4, 0.4, 0.4);

// A noise texture to determine crater placement (should be a tileable grayscale texture)
uniform sampler2D u_crater_noise;

// Controls the scale of the noise pattern on the planet surface
uniform float u_noise_scale = 1.0;

// The threshold for the crater effect; lower values yield larger crater areas
uniform float u_crater_threshold = 0.5;

// Varying to pass planet-space vertex position from vertex() to fragment()
varying vec3 v_planet_pos;

void vertex() {
    // Apply transvoxel modifications if needed
    VERTEX = get_transvoxel_position(VERTEX, CUSTOM0);
    // Transform vertex to planet-space
    vec3 planet_pos = (u_block_local_transform * vec4(VERTEX, 1.0)).xyz;
    v_planet_pos = planet_pos;
}

void fragment() {
    // Compute spherical coordinates from the planet-space position.
    // r: radial distance (planet radius at this vertex)
    float r = length(v_planet_pos);
    // theta: angle around the Y axis (longitude); returns [-π, +π]
    float theta = atan(v_planet_pos.z, v_planet_pos.x);
    // phi: angle from the "north pole" (latitude); returns [0, π]
    float phi = acos(clamp(v_planet_pos.y / r, -1.0, 1.0));

    // Map theta and phi to a [0,1] range to form UV coordinates.
    float u = (theta / (2.0 * 3.1415926535)) + 0.5;
    float v = phi / 3.1415926535;

    // Scale the UV coordinates to adjust the noise tiling
    vec2 noise_uv = vec2(u, v) * u_noise_scale;

    // Sample the noise texture. Expecting a grayscale image where the red channel is used.
    float crater_val = texture(u_crater_noise, noise_uv).r;

    // Use a step function to create a binary mask based on the threshold:
    // Pixels where the noise value is lower than u_crater_threshold become crater areas.
    float is_crater = step(crater_val, u_crater_threshold);

    // Mix between the base moon color and crater color based on the crater mask
    ALBEDO = mix(u_color_moon, u_color_crater, is_crater);
}
