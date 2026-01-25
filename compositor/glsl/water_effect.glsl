#[compute]
#version 450
#define MAX_VIEWS 2
#include "godot/scene_data_inc.glsl"

// Invocations in the (x, y, z) dimension.
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std140) uniform SceneDataBlock {
	SceneData data;
	SceneData prev_data;
}
scene_data_block;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;

// Our push constant.
// Must be aligned to 16 bytes, just like the push constant we passed from the script.
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	float view;
	float pad;
} params;

// The code we want to execute in each invocation.
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);
	int view = int(params.view);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec2 uv_norm = vec2(uv) / params.raster_size;

	vec4 color = imageLoad(color_image, uv);
	float depth = texture(depth_texture, uv_norm).r;

	imageStore(color_image, uv, color);
}