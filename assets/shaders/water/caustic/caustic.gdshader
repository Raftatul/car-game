shader_type spatial;
render_mode skip_vertex_transform, shadows_disabled, unshaded;

uniform sampler2D caustic_tex;

uniform sampler2D screen_texture : hint_screen_texture;

void vertex(){
	vec3 vertex_os = VERTEX;
	
	mat4 BILLBOARD_MATRIX = mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
	
	
	vec4 vertex_ws = BILLBOARD_MATRIX * vec4(vertex_os, 1.0);
	vec4 vertex_vs = VIEW_MATRIX * vertex_ws;
	vec4 vertex_proj = PROJECTION_MATRIX * vertex_vs;
	POSITION = vertex_proj;
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	color *= dot(vec3(0.0, 1.0, 0.0), NORMAL);
	
	ALBEDO = color.rgb;
}