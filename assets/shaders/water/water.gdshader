shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx, world_vertex_coords;

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

//Fragment
uniform vec3 water_color: source_color = vec3(1.0);
uniform vec3 deep_water_color: source_color = vec3(1.0);
uniform float water_smooth: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float fresnel_force: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float water_color_ratio: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float depth_distance: hint_range(0.0, 50.0, 0.1) = 0.5;
uniform float beers_law: hint_range(0.0, 50.0, 0.1) = 3.0;

uniform sampler2D water_noise_1;
uniform sampler2D water_noise_2;

uniform float normal_scale: hint_range(0.0, 1.0, 0.1) = 0.5;

uniform float uv_scale = 1.0;

varying vec4 world_uv;

// Vertex
uniform float wave_time = 0.0;
uniform vec4[5] waves;
uniform float gravity = 9.8;

vec3 gerstner_wave(vec4 wave, vec3 p, inout vec3 tangent, inout vec3 binormal) {
	if (wave == vec4(0.0))
		return vec3(0.0);
	
	float wave_steepness = wave.z;
	float wave_length = wave.w;
	float k = TAU / wave_length;
	float c = sqrt(gravity / k);
	vec2 d = normalize(wave.xy);
	float f = k * (dot(d, p.xz) - c * wave_time);
	float a = wave_steepness / k;
	
	tangent += vec3(
		-d.x * d.x * (wave_steepness * sin(f)),
		d.x * (wave_steepness * cos(f)),
		-d.x * d.y * (wave_steepness * sin(f))
	);
	
	binormal += vec3(
		-d.x * d.y * (wave_steepness * sin(f)),
		d.y * (wave_steepness * cos(f)),
		-d.y * d.y * (wave_steepness * sin(f))
	);
	
	return vec3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
} 

void vertex() {
	world_uv = MODEL_MATRIX * vec4(VERTEX, 1.0);
	
	vec3 vertex = VERTEX;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 p = vertex;
	
	for (int i = 0; i < waves.length(); i++)
	{
		p += gerstner_wave(waves[i], vertex, tangent, binormal);
	}
	
	vec3 normal = normalize(cross(binormal, tangent));
	
	VERTEX = p;
	NORMAL = normal;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment() {
	vec2 base_uv = world_uv.xz * uv_scale;
	base_uv.x += sin(wave_time + (base_uv.x + base_uv.y) * 25.0) * 0.01;
	base_uv.y += cos(wave_time + (base_uv.x - base_uv.y) * 25.0) * 0.01;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	world.xyz /= world.w;
	float depth_blend = smoothstep(world.z + depth_distance, world.z, VERTEX.z);
	//depth_blend = exp(depth_blend * -beers_law);
	//depth_blend = clamp(pow(depth_blend, 3.0), 0.0, 1.0);
	
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	float fresnel_val = fresnel(fresnel_force, NORMAL, VIEW);
	float point_height = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y - NODE_POSITION_WORLD.y;
	float height = clamp(point_height * water_smooth, 0.0, 1.0);
	vec3 water_col = mix(deep_water_color, water_color, height);
	
	ALBEDO = mix(screen * depth_blend, water_col, water_color_ratio);
	NORMAL_MAP = mix(texture(water_noise_1, base_uv).rgb, texture(water_noise_2, base_uv).rgb, (sin(wave_time) + 1.0) / 2.0);
	NORMAL *= normal_scale;
	SPECULAR *= fresnel_val;
}