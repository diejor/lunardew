shader_type spatial;
render_mode unshaded;

#include "res://src/planet/shaders/transvoxel.gdshaderinc"

// Base colors: moon surface, crater fill, and outline color.
uniform vec3 u_color_moon : source_color = vec3(0.8, 0.8, 0.8);
uniform vec3 u_color_crater : source_color = vec3(0.4, 0.4, 0.4);
uniform vec3 u_color_outline : source_color = vec3(1.0, 0.0, 0.0);
// Outline width (in noise value units).
uniform float u_outline_threshold = 0.02;

uniform sampler2D u_crater_noise; // Tileable noise texture for crater placement.
uniform float u_noise_scale = 1.0; // Controls texture tiling.
uniform float u_crater_threshold = 0.5; // Threshold to decide crater areas.

// Varying to pass the world-space vertex position.
varying vec3 v_world_pos;

//
// Triplanar functions (embedded)
//

// Computes blend weights for triplanar mapping from the world normal.
// The 'sharpness' parameter controls the blending falloff.
vec3 get_triplanar_blend(vec3 world_normal, float sharpness) {
    vec3 blending = pow(abs(world_normal), vec3(sharpness));
    return blending / (blending.x + blending.y + blending.z);
}

// Performs triplanar texture sampling with mipmap filtering using textureGrad.
// Projects the texture on the three primary axes and blends them using the provided weights.
vec4 texture_triplanar(sampler2D tex, vec3 world_pos, vec3 blend) {
    // Projection on X-axis: use the YZ plane.
    vec2 coord_x = world_pos.yz;
    vec2 dcoord_x_dx = dFdx(coord_x);
    vec2 dcoord_x_dy = dFdy(coord_x);
    vec4 sample_x = textureGrad(tex, coord_x, dcoord_x_dx, dcoord_x_dy);

    // Projection on Y-axis: use the XZ plane.
    vec2 coord_y = world_pos.xz;
    vec2 dcoord_y_dx = dFdx(coord_y);
    vec2 dcoord_y_dy = dFdy(coord_y);
    vec4 sample_y = textureGrad(tex, coord_y, dcoord_y_dx, dcoord_y_dy);

    // Projection on Z-axis: use the XY plane.
    vec2 coord_z = world_pos.xy;
    vec2 dcoord_z_dx = dFdx(coord_z);
    vec2 dcoord_z_dy = dFdy(coord_z);
    vec4 sample_z = textureGrad(tex, coord_z, dcoord_z_dx, dcoord_z_dy);

    // Blend the three samples based on their respective weights.
    return sample_x * blend.x + sample_y * blend.y + sample_z * blend.z;
}

void vertex() {
    // Optionally apply transvoxel modifications.
    VERTEX = get_transvoxel_position(VERTEX, CUSTOM0);
    // Compute the world-space position using the built-in MODEL_MATRIX.
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Use the normalized world position so that the mapping is independent of scale.
    vec3 n = normalize(v_world_pos);
    // Use the normalized vector to drive triplanar mapping.
    vec3 blend = get_triplanar_blend(n, 8.0);
    // Use the normalized direction scaled by u_noise_scale.
    vec3 scaled_pos = n * u_noise_scale;

    // Sample the noise texture using triplanar mapping with mipmap filtering.
    vec4 noise_sample = texture_triplanar(u_crater_noise, scaled_pos, blend);

    // Create a crater mask based on the threshold.
    float is_crater = step(noise_sample.r, u_crater_threshold);

    // Compute the difference from the threshold to determine crater edges.
    float diff = abs(noise_sample.r - u_crater_threshold);
    // Use a binary step for a sharp outline.
    float outline_mask = step(diff, u_outline_threshold);

    // Blend between the base moon color and crater fill based on the crater mask.
    vec3 base_color = mix(u_color_moon, u_color_crater, is_crater);
    // Replace the base color with the outline color where applicable.
    ALBEDO = mix(base_color, u_color_outline, outline_mask);
}
