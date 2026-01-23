class_name WaterBody
extends MeshInstance3D

var noise: Image
var wave_speed: float
var noise_scale: float
var height_scale: float

var time: float = 0.0

func _ready() -> void:
	add_to_group("water_body")
	
	noise = material_override.get("shader_parameter/wave").noise.get_seamless_image(512, 512)
	wave_speed = material_override.get("shader_parameter/wave_speed")
	noise_scale = material_override.get("shader_parameter/noise_scale")
	height_scale = material_override.get("shader_parameter/height_scale")


func _process(delta: float) -> void:
	time += delta
	material_override.set("shader_parameter/wave_time", time)


func compute_wave_height(node_global_position: Vector3) -> float:
	var uv_x: float = wrapf(node_global_position.x / noise_scale + time * wave_speed, 0.0, 1.0)
	var uv_y: float = wrapf(node_global_position.z / noise_scale + time * wave_speed, 0.0, 1.0)
	
	var pixel_pos: Vector2 = Vector2(uv_x * noise.get_width(), uv_y * noise.get_height())
	return global_position.y + noise.get_pixelv(pixel_pos).r * height_scale
